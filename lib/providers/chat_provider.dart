import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/models/chat_thread.dart';
import 'package:abyss_chat/models/message.dart';
import 'package:abyss_chat/models/user.dart';
import 'package:abyss_chat/screens/chat_screen.dart';
import 'package:abyss_chat/services/peerdart_service.dart';
import 'package:abyss_chat/services/storage_service.dart';
import 'package:abyss_chat/services/mdns_service.dart';
import 'package:abyss_chat/models/call_log.dart';
import 'package:abyss_chat/services/lan_messenger.dart';
import 'package:abyss_chat/services/notification_service.dart';
import 'package:abyss_chat/providers/call_provider.dart';
import 'package:uuid/uuid.dart';

final storageServiceProvider = Provider((ref) => StorageService());

class ContactsNotifier extends AsyncNotifier<List<User>> {
  @override
  Future<List<User>> build() async {
    return await ref.watch(storageServiceProvider).loadContacts();
  }

  void addContact(User user) {
    if (!state.hasValue) return;
    final contacts = List<User>.from(state.value!);
    if (!contacts.any((c) => c.id == user.id)) {
      contacts.add(user);
      state = AsyncData(contacts);
      ref.read(storageServiceProvider).saveContacts(contacts);
    }
  }

  void deleteContact(String id) {
    if (!state.hasValue) return;
    final contacts = List<User>.from(state.value!);
    contacts.removeWhere((c) => c.id == id);
    state = AsyncData(contacts);
    ref.read(storageServiceProvider).saveContacts(contacts);
    
    // Also delete chat thread history
    ref.read(chatThreadsProvider.notifier).deleteThread(id);
  }

  void blockContact(String id) {
    ref.read(blockedContactsProvider.notifier).blockPeer(id);
    deleteContact(id); // Blocking also removes from contacts and deletes thread
  }
}

class BlockedContactsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    return await ref.watch(storageServiceProvider).loadBlockedPeers();
  }

  void blockPeer(String id) {
    if (!state.hasValue) return;
    final blocked = List<String>.from(state.value!);
    if (!blocked.contains(id)) {
      blocked.add(id);
      state = AsyncData(blocked);
      ref.read(storageServiceProvider).saveBlockedPeers(blocked);
    }
  }
}

final blockedContactsProvider = AsyncNotifierProvider<BlockedContactsNotifier, List<String>>(() => BlockedContactsNotifier());

final contactsProvider = AsyncNotifierProvider<ContactsNotifier, List<User>>(() => ContactsNotifier());

class CallLogsNotifier extends AsyncNotifier<List<CallLog>> {
  @override
  Future<List<CallLog>> build() async {
    return await ref.watch(storageServiceProvider).loadCallLogs();
  }

  void addCallLog(CallLog log) {
    if (!state.hasValue) return;
    final logs = List<CallLog>.from(state.value!);
    logs.insert(0, log);
    state = AsyncData(logs);
    ref.read(storageServiceProvider).saveCallLogs(logs);
  }
}

final callLogsProvider = AsyncNotifierProvider<CallLogsNotifier, List<CallLog>>(() => CallLogsNotifier());

final lanMessengerProvider = Provider<LanMessenger>((ref) {
  final service = LanMessenger();
  ref.onDispose(() => service.dispose());
  return service;
});

final peerServiceProvider = Provider<PeerDartService>((ref) {
  final service = PeerDartService();
  ref.onDispose(() => service.dispose());
  return service;
});

class SelectedThreadIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) {
    state = id;
  }
}

final selectedThreadIdProvider = NotifierProvider<SelectedThreadIdNotifier, String?>(() => SelectedThreadIdNotifier());

final myProfileProvider = FutureProvider<User?>((ref) async {
  final data = await ref.read(storageServiceProvider).loadUserProfile();
  if (data == null) return null;
  return User(
    id: data['id'],
    name: data['name'],
    avatarIcon: data['avatarIcon'],
    avatarColor: data['avatarColor'],
    profileImagePath: data['profileImagePath'],
  );
});

class ChatThreadsNotifier extends AsyncNotifier<List<ChatThread>> {
  String? get myId => ref.read(peerServiceProvider).myId;
  String? _myName;
  String? get myName => _myName;
  Timer? _retryTimer;
  final Map<String, DateTime> _lastConnectAttempt = {};

  @override
  Future<List<ChatThread>> build() async {
    final storage = ref.watch(storageServiceProvider);
    final peer = ref.watch(peerServiceProvider);
    final lan = ref.watch(lanMessengerProvider);
    
    // Message streams
    final sub1 = peer.onMessageReceived.listen(_handleIncomingMessage);
    final sub2 = lan.onMessageReceived.listen(_handleIncomingMessage);
    
    // Receipt streams
    final sub3 = peer.onDeliveryReceipt.listen(_handleDeliveryReceipt);
    final sub4 = lan.onDeliveryReceipt.listen(_handleDeliveryReceipt);
    final sub5 = peer.onReadReceipt.listen(_handleReadReceipt);
    final sub6 = lan.onReadReceipt.listen(_handleReadReceipt);
    
    // Typing indicator streams
    final sub7 = peer.onTypingReceived.listen(_handleTypingIndicator);
    final sub8 = lan.onTypingReceived.listen(_handleTypingIndicator);
    
    // PeerDart specialized streams
    final sub9 = peer.onConnectionOpened.listen(_handleConnectionOpened);
    final sub10 = peer.onProfileSyncReceived.listen(_handleProfileSync);
    
    // Start background retry loop for pending messages
    _retryTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _flushAllPendingQueues();
    });
    
    ref.onDispose(() {
      sub1.cancel(); sub2.cancel(); sub3.cancel(); sub4.cancel();
      sub5.cancel(); sub6.cancel(); sub7.cancel(); sub8.cancel();
      sub9.cancel(); sub10.cancel();
      _retryTimer?.cancel();
    });

    return await storage.loadThreads();
  }
  
  void _flushAllPendingQueues() {
    if (!state.hasValue) return;
    final threads = state.value!;
    final now = DateTime.now();
    for (final thread in threads) {
      if (thread.messages.any((m) => m.status == MessageStatus.pending)) {
        final lastAttempt = _lastConnectAttempt[thread.id];
        // Only try to reconnect if we haven't tried in the last 30 seconds
        if (lastAttempt == null || now.difference(lastAttempt).inSeconds > 30) {
          _lastConnectAttempt[thread.id] = now;
          connectToPeer(thread.id);
        }
        _flushQueueForPeer(thread.id);
      }
    }
  }

  void _handleIncomingMessage(Message message) {
    if (!state.hasValue) return;
    
    final blockedList = ref.read(blockedContactsProvider).value ?? [];
    if (blockedList.contains(message.senderId)) {
      return; // Ignore messages from blocked peers
    }
    
    final threads = List<ChatThread>.from(state.value!);
    final senderId = message.senderId;
    final currentSelectedId = ref.read(selectedThreadIdProvider);
    
    int threadIndex = threads.indexWhere((t) => t.id == senderId);
    
    if (threadIndex != -1) {
      final updatedMessages = List<Message>.from(threads[threadIndex].messages)..add(message);
      threads[threadIndex] = threads[threadIndex].copyWith(messages: updatedMessages);
    } else {
      final newThread = ChatThread(
        id: senderId,
        peer: User(
          id: senderId, 
          name: message.senderName ?? 'Peer $senderId', 
          avatarIcon: 0xe491, 
          avatarColor: 0xFF6750A4
        ),
        messages: [message],
      );
      threads.insert(0, newThread);
    }
    
    state = AsyncData(threads);
    ref.read(storageServiceProvider).saveThreads(threads);
    
    // Send Read Receipt if currently viewing this thread
    if (currentSelectedId == senderId) {
      sendReadReceipt(senderId, [message.id]);
    } else {
      final activeCall = ref.read(callProvider);
      final inActiveCallWithSender = activeCall != null && activeCall.peer.id == senderId;
      
      if (!inActiveCallWithSender) {
        final thread = threads.firstWhere((t) => t.id == senderId);
        NotificationService.showMessageNotification(
          thread.isGroup ? (thread.groupName ?? 'Group') : thread.peer.name, 
          message.text,
          onTap: () {
            ref.read(selectedThreadIdProvider.notifier).select(thread.id);
            final ctx = globalNavigatorKey.currentContext;
            if (ctx != null) {
              final isDesktop = MediaQuery.of(ctx).size.width >= 800;
              if (!isDesktop) {
                Navigator.push(ctx, MaterialPageRoute(builder: (_) => ChatScreen(threadId: thread.id)));
              }
            }
          }
        );
      }
    }
  }

  void _handleDeliveryReceipt(Map<String, dynamic> receipt) {
    if (!state.hasValue) return;
    final messageId = receipt['messageId'];
    _updateMessageStatus(messageId, MessageStatus.delivered);
  }

  void _handleReadReceipt(Map<String, dynamic> receipt) {
    if (!state.hasValue) return;
    final messageIds = List<String>.from(receipt['messageIds']);
    for (final msgId in messageIds) {
      _updateMessageStatus(msgId, MessageStatus.read);
    }
  }

  void _handleTypingIndicator(String peerId) {
    // We could add typing state to ChatThread here, e.g., thread.isTyping = true
    // For now, this is a placeholder where UI can watch a typing provider
  }

  void _handleConnectionOpened(String peerId) async {
    // Send our profile
    final myProfile = await ref.read(myProfileProvider.future);
    if (myProfile != null) {
      ref.read(peerServiceProvider).sendProfileSync(peerId, {
        'name': myProfile.name,
        'avatarIcon': myProfile.avatarIcon,
        'avatarColor': myProfile.avatarColor,
      });
    } else if (_myName != null) {
      ref.read(peerServiceProvider).sendProfileSync(peerId, {
        'name': _myName,
        'avatarIcon': 0xe491,
        'avatarColor': 0xFF6750A4,
      });
    }
    
    // Flush pending queue
    _flushQueueForPeer(peerId);
  }

  void _handleProfileSync(Map<String, dynamic> data) {
    final peerId = data['peerId'] as String;
    final profile = data['profile'] as Map<String, dynamic>;
    
    final newUser = User(
      id: peerId,
      name: profile['name'],
      avatarIcon: profile['avatarIcon'],
      avatarColor: profile['avatarColor'],
    );
    
    ref.read(contactsProvider.notifier).addContact(newUser);
    
    // Update thread if exists
    if (state.hasValue) {
      final threads = List<ChatThread>.from(state.value!);
      final threadIndex = threads.indexWhere((t) => t.id == peerId);
      if (threadIndex != -1) {
        threads[threadIndex] = threads[threadIndex].copyWith(peer: newUser);
        state = AsyncData(threads);
        ref.read(storageServiceProvider).saveThreads(threads);
      }
    }
  }

  void _updateMessageStatus(String messageId, MessageStatus newStatus) {
    if (!state.hasValue) return;
    final threads = List<ChatThread>.from(state.value!);
    bool updated = false;
    
    for (int i = 0; i < threads.length; i++) {
      final msgs = List<Message>.from(threads[i].messages);
      for (int j = msgs.length - 1; j >= 0; j--) {
        if (msgs[j].id == messageId) {
          // Prevent downgrading status (e.g. read -> delivered)
          if (msgs[j].status != MessageStatus.read) {
            msgs[j] = msgs[j].copyWith(status: newStatus);
            threads[i] = threads[i].copyWith(messages: msgs);
            updated = true;
          }
          break;
        }
      }
      if (updated) break;
    }
    
    if (updated) {
      state = AsyncData(threads);
      ref.read(storageServiceProvider).saveThreads(threads);
    }
  }

  Future<void> initializePeer(String? customId, String myName) async {
    _myName = myName;
    await ref.read(peerServiceProvider).initialize(customId);
    
    final lanPort = await ref.read(lanMessengerProvider).startServer(customId ?? 'unknown');
    
    final mdnsNotifier = ref.read(nearbyPeersProvider.notifier);
    await mdnsNotifier.startBroadcasting(myId ?? 'unknown', myName, port: lanPort);
    await mdnsNotifier.startScanning(myId ?? 'unknown');
  }

  Future<void> connectToPeer(String peerId) async {
    final mdnsPeers = ref.read(nearbyPeersProvider);
    final lanPeer = mdnsPeers.where((p) => p.id == peerId).firstOrNull;
    
    bool lanConnected = false;
    if (lanPeer != null && lanPeer.ipAddress != null && lanPeer.port != null) {
      lanConnected = await ref.read(lanMessengerProvider).connectToPeer(peerId, lanPeer.ipAddress!, lanPeer.port!);
    }
    
    if (!lanConnected) {
      ref.read(peerServiceProvider).connectToPeer(peerId);
    }
  }

  Future<void> updateMyProfile(String name, int iconCodePoint, int colorValue, {String? newImagePath, bool removeImage = false}) async {
    final storage = ref.read(storageServiceProvider);
    
    String? finalImagePath;
    if (newImagePath != null) {
      finalImagePath = newImagePath;
    } else if (removeImage) {
      finalImagePath = null;
    } else {
      final oldProfile = await storage.loadUserProfile();
      finalImagePath = oldProfile?['profileImagePath'];
    }

    await storage.saveUserProfile(myId ?? '', name, avatarIcon: iconCodePoint, avatarColor: colorValue, profileImagePath: finalImagePath);
    
    _myName = name;
    
    final mdnsNotifier = ref.read(nearbyPeersProvider.notifier);
    await mdnsNotifier.startBroadcasting(myId ?? 'unknown', name);
    
    ref.invalidate(myProfileProvider);
  }
  
  void startNewChat(String peerId, {String? peerName}) {
    if (!state.hasValue) return;
    final threads = List<ChatThread>.from(state.value!);
    
    if (!threads.any((t) => t.id == peerId)) {
      threads.insert(0, ChatThread(
        id: peerId,
        peer: User(id: peerId, name: peerName ?? 'Peer $peerId', avatarIcon: 0xe491, avatarColor: 0xFF6750A4),
        messages: [],
      ));
      state = AsyncData(threads);
      ref.read(storageServiceProvider).saveThreads(threads);
    }
    connectToPeer(peerId);
  }

  void createGroup(String groupName, List<User> members) {
    if (!state.hasValue) return;
    final threads = List<ChatThread>.from(state.value!);
    
    final groupId = const Uuid().v4();
    final groupThread = ChatThread(
      id: groupId,
      peer: User(id: groupId, name: groupName, avatarIcon: 0xe886, avatarColor: 0xFF2E7D32),
      messages: [],
      isGroup: true,
      groupName: groupName,
      members: members,
    );
    
    threads.insert(0, groupThread);
    state = AsyncData(threads);
    ref.read(storageServiceProvider).saveThreads(threads);
    
    ref.read(selectedThreadIdProvider.notifier).select(groupId);
    
    final sysMsg = Message(
      id: const Uuid().v4(),
      senderId: myId ?? 'me',
      senderName: myName ?? 'You',
      text: 'Group "$groupName" created',
      timestamp: DateTime.now(),
      type: MessageType.system,
      status: MessageStatus.sent,
    );
    sendMessage(groupId, sysMsg.text, type: MessageType.system);
  }

  Future<void> sendMessage(String threadId, String text, {MessageType type = MessageType.text, String? localFilePath, String? fileName, String? fileData}) async {
    if (!state.hasValue) return;
    
    final msg = Message(
      id: const Uuid().v4(),
      senderId: ref.read(peerServiceProvider).myId ?? 'me',
      senderName: _myName ?? 'Me',
      text: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sending, // Initial status
      type: type,
      localFilePath: localFilePath,
      fileName: fileName,
      fileData: fileData,
    );

    final threads = List<ChatThread>.from(state.value!);
    final threadIndex = threads.indexWhere((t) => t.id == threadId);
    
    if (threadIndex != -1) {
      final updatedMessages = List<Message>.from(threads[threadIndex].messages)..add(msg);
      threads[threadIndex] = threads[threadIndex].copyWith(messages: updatedMessages);
      state = AsyncData(threads);
      ref.read(storageServiceProvider).saveThreads(threads);
      
      bool sent = false;
      
      // Try LAN first
      sent = ref.read(lanMessengerProvider).sendMessage(threadId, msg);
      
      // Try WebRTC if LAN failed
      if (!sent) {
        if (threads[threadIndex].isGroup) {
          for (final member in threads[threadIndex].members) {
            if (member.id != myId) {
               final memberSent = ref.read(peerServiceProvider).sendMessage(member.id, msg);
               if (memberSent) sent = true;
            }
          }
        } else {
           sent = ref.read(peerServiceProvider).sendMessage(threadId, msg);
        }
      }

      // Update to sent or pending
      _updateMessageStatus(msg.id, sent ? MessageStatus.sent : MessageStatus.pending);
    }
  }

  Future<void> _flushQueueForPeer(String peerId) async {
    if (!state.hasValue) return;
    
    final threads = List<ChatThread>.from(state.value!);
    final threadIndex = threads.indexWhere((t) => t.id == peerId);
    
    if (threadIndex != -1) {
      final thread = threads[threadIndex];
      bool updated = false;
      final msgs = List<Message>.from(thread.messages);
      
      for (int i = 0; i < msgs.length; i++) {
        if (msgs[i].status == MessageStatus.pending || msgs[i].status == MessageStatus.sending) {
          final sent = ref.read(peerServiceProvider).sendMessage(peerId, msgs[i]);
          if (sent) {
            msgs[i] = msgs[i].copyWith(status: MessageStatus.sent);
            updated = true;
          }
        }
      }
      
      if (updated) {
        threads[threadIndex] = thread.copyWith(messages: msgs);
        state = AsyncData(threads);
        ref.read(storageServiceProvider).saveThreads(threads);
      }
    }
  }

  void sendTypingIndicator(String threadId) {
    // Send to LAN and WebRTC
    ref.read(lanMessengerProvider).sendTypingIndicator(threadId);
    ref.read(peerServiceProvider).sendTypingIndicator(threadId);
  }

  void sendReadReceipt(String threadId, List<String> messageIds) {
    if (messageIds.isEmpty) return;
    if (!state.hasValue) return;
    // Update local DB first
    final threads = List<ChatThread>.from(state.value!);
    final threadIndex = threads.indexWhere((t) => t.id == threadId);
    if (threadIndex != -1) {
      bool updated = false;
      final msgs = List<Message>.from(threads[threadIndex].messages);
      for (int i = 0; i < msgs.length; i++) {
        if (messageIds.contains(msgs[i].id) && msgs[i].status != MessageStatus.read) {
          msgs[i] = msgs[i].copyWith(status: MessageStatus.read);
          updated = true;
        }
      }
      if (updated) {
        threads[threadIndex] = threads[threadIndex].copyWith(messages: msgs);
        state = AsyncData(threads);
        ref.read(storageServiceProvider).saveThreads(threads);
      }
    }
    
    // Send over network
    ref.read(lanMessengerProvider).sendReadReceipt(threadId, messageIds);
    ref.read(peerServiceProvider).sendReadReceipt(threadId, messageIds);
  }

  void markAllRead(String threadId) {
    if (!state.hasValue) return;
    final threads = List<ChatThread>.from(state.value!);
    final thread = threads.firstWhere((t) => t.id == threadId, orElse: () => threads.first); // fallback
    if (thread.id != threadId) return;

    final unreadIds = thread.messages
        .where((m) => m.senderId != myId && m.status != MessageStatus.read)
        .map((m) => m.id)
        .toList();
    
    if (unreadIds.isNotEmpty) {
      // Let sendReadReceipt handle the status updates since it already modifies state.
      sendReadReceipt(threadId, unreadIds);
    }
  }

  void deleteThread(String threadId) {
    if (!state.hasValue) return;
    final threads = List<ChatThread>.from(state.value!);
    threads.removeWhere((t) => t.id == threadId);
    state = AsyncData(threads);
    ref.read(storageServiceProvider).saveThreads(threads);
  }

  void deleteMessages(String threadId, List<String> messageIds) {
    if (!state.hasValue) return;
    final threads = List<ChatThread>.from(state.value!);
    final threadIndex = threads.indexWhere((t) => t.id == threadId);
    if (threadIndex != -1) {
      final oldThread = threads[threadIndex];
      final newMessages = oldThread.messages.where((m) => !messageIds.contains(m.id)).toList();
      threads[threadIndex] = ChatThread(
        id: oldThread.id,
        peer: oldThread.peer,
        messages: newMessages,
        isGroup: oldThread.isGroup,
        groupName: oldThread.groupName,
        members: oldThread.members,
      );
      state = AsyncData(threads);
      ref.read(storageServiceProvider).saveThreads(threads);
    }
  }

  void forwardMessages(String targetThreadId, List<Message> messages) {
    for (final msg in messages) {
      sendMessage(
        targetThreadId,
        msg.text,
        type: msg.type,
        localFilePath: msg.localFilePath,
        fileName: msg.fileName,
      );
    }
  }

  void clearMessages(String threadId) {
    if (!state.hasValue) return;
    final threads = List<ChatThread>.from(state.value!);
    final threadIndex = threads.indexWhere((t) => t.id == threadId);
    if (threadIndex != -1) {
      final oldThread = threads[threadIndex];
      threads[threadIndex] = ChatThread(
        id: oldThread.id,
        peer: oldThread.peer,
        messages: [],
      );
      state = AsyncData(threads);
      ref.read(storageServiceProvider).saveThreads(threads);
    }
  }
}

final chatThreadsProvider = AsyncNotifierProvider<ChatThreadsNotifier, List<ChatThread>>(() {
  return ChatThreadsNotifier();
});

final singleThreadProvider = Provider.family<ChatThread?, String>((ref, id) {
  final asyncThreads = ref.watch(chatThreadsProvider);
  return asyncThreads.maybeWhen(
    data: (threads) => threads.firstWhere(
      (t) => t.id == id,
      orElse: () => throw Exception('Thread not found'),
    ),
    orElse: () => null,
  );
});
