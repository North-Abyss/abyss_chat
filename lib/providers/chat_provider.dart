import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/models/chat_thread.dart';
import 'package:abyss_chat/models/message.dart';
import 'package:abyss_chat/models/user.dart';
import "package:abyss_chat/services/mdns_service.dart";
import 'package:abyss_chat/screens/chat_screen.dart';
import 'package:abyss_chat/services/peerdart_service.dart';
import 'package:abyss_chat/services/storage_service.dart';
import 'package:abyss_chat/models/call_log.dart';
import 'package:abyss_chat/services/lan_messenger.dart';
import 'package:abyss_chat/services/notification_service.dart';
import 'package:abyss_chat/providers/call_provider.dart';
// removed
import 'package:uuid/uuid.dart';

final storageServiceProvider = Provider((ref) => StorageService());

class ContactsNotifier extends AsyncNotifier<List<User>> {
  @override
  Future<List<User>> build() async {
    final storage = ref.watch(storageServiceProvider);
    final contacts = await storage.loadContacts();
    
    // Automatically clean up any accidental "self" contacts (duplicate bug)
    final profile = await storage.loadUserProfile();
    if (profile != null && profile['id'] != null) {
      final myId = profile['id'] as String;
      final filtered = contacts.where((c) => c.id != myId).toList();
      if (filtered.length != contacts.length) {
        storage.saveContacts(filtered);
        return filtered;
      }
    }
    return contacts;
  }

  void addContact(User user) {
    if (!state.hasValue) return;
    final contacts = List<User>.from(state.value!);
    if (!contacts.any((c) => c.id == user.id)) {
      contacts.add(user);
      state = AsyncData(contacts);
      ref.read(storageServiceProvider).saveContacts(contacts);
    } else {
      final idx = contacts.indexWhere((c) => c.id == user.id);
      if (contacts[idx].name != user.name || contacts[idx].avatarIcon != user.avatarIcon || contacts[idx].avatarColor != user.avatarColor) {
        contacts[idx] = user;
        state = AsyncData(contacts);
        ref.read(storageServiceProvider).saveContacts(contacts);
      }
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
  final Set<String> _initiatedConnections = {};

  @override
  Future<List<ChatThread>> build() async {
    final storage = ref.read(storageServiceProvider);
    
    // Subscribe to incoming messages
    final lan = ref.read(lanMessengerProvider);
    final peer = ref.read(peerServiceProvider);
    
    final sub1 = lan.onMessageReceived.listen(_handleIncomingMessage);
    final sub2 = peer.onMessageReceived.listen(_handleIncomingMessage);
    
    final sub3 = lan.onDeliveryReceipt.listen(_handleDeliveryReceipt);
    final sub4 = peer.onDeliveryReceipt.listen(_handleDeliveryReceipt);
    
    final sub5 = lan.onReadReceipt.listen(_handleReadReceipt);
    final sub6 = peer.onReadReceipt.listen(_handleReadReceipt);
    
    final sub7 = peer.onConnectionOpened.listen(_handleConnectionOpened);
    final sub8 = peer.onProfileSyncReceived.listen(_handleProfileSync);

    // Activity sync and reverse connect handler
    void handleTunneledSignal(Map<String, dynamic> data) {
      if (data['type'] == 'activity_sync') {
        _handleActivitySync(data);
      } else if (data['type'] == 'reverse_connect_request') {
        final peerId = data['peerId'] as String;
        debugPrint('📞 Received reverse connect request from $peerId. I will act as the host!');
        connectToPeer(peerId, isReverseConnect: true);
      }
    }
    
    final sub9 = lan.onDataMessage.listen(handleTunneledSignal);
    final sub10 = peer.onDataMessage.listen(handleTunneledSignal);

    // Periodically process queue for offline peers
    _retryTimer = Timer.periodic(const Duration(seconds: 10), (_) {
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
    for (final thread in threads) {
      if (thread.messages.any((m) => m.status == MessageStatus.pending)) {
        if (thread.isGroup) {
          for (final member in thread.members) {
            if (member.id != myId) _trySend(member.id, thread.messages.lastWhere((m) => m.status == MessageStatus.pending));
          }
        } else {
          _trySend(thread.id, thread.messages.lastWhere((m) => m.status == MessageStatus.pending));
        }
      }
    }
  }

  void _handleIncomingMessage(Message message) {
    if (!state.hasValue) return;
    
    final blockedList = ref.read(blockedContactsProvider).value ?? [];
    if (blockedList.contains(message.senderId)) {
      return; 
    }
    
    final contactsList = ref.read(contactsProvider).value ?? [];
    final isMe = message.senderId == myId;
    final isKnownContact = isMe || contactsList.any((c) => c.id == message.senderId);

    if (!isKnownContact) {
      final newUser = User(
        id: message.senderId,
        name: message.senderName ?? 'Peer ${message.senderId}',
        avatarIcon: 0xe491,
        avatarColor: 0xFF6750A4,
      );
      _requestAirDropInvite(newUser, message: message);
      return;
    }
    
    final threads = List<ChatThread>.from(state.value!);
    final isGroup = message.groupId != null;
    final targetThreadId = isGroup ? message.groupId! : (message.networkSenderId ?? message.senderId);
    final currentSelectedId = ref.read(selectedThreadIdProvider);
    
    int threadIndex = threads.indexWhere((t) => t.id == targetThreadId);
    
    if (threadIndex != -1) {
      final existingIndex = threads[threadIndex].messages.indexWhere((m) => m.id == message.id);
      if (existingIndex != -1) {
        if (message.type == MessageType.activity) {
          final updatedMessages = List<Message>.from(threads[threadIndex].messages);
          updatedMessages[existingIndex] = message;
          threads[threadIndex] = threads[threadIndex].copyWith(messages: updatedMessages);
        } else {
          return;
        }
      } else {
        final updatedMessages = List<Message>.from(threads[threadIndex].messages)..add(message);
        threads[threadIndex] = threads[threadIndex].copyWith(messages: updatedMessages);
      }
    } else {
      if (isGroup) {
        final newGroup = ChatThread(
          id: targetThreadId,
          peer: User(id: targetThreadId, name: message.groupName ?? 'New Group', avatarIcon: 0xe886, avatarColor: 0xFF2E7D32),
          messages: [message],
          isGroup: true,
          groupName: message.groupName ?? 'New Group',
          members: [
            User(id: message.senderId, name: message.senderName ?? 'Peer ${message.senderId}', avatarIcon: 0xe491, avatarColor: 0xFF6750A4)
          ],
        );
        threads.insert(0, newGroup);
      } else {
        final newThread = ChatThread(
          id: targetThreadId,
          peer: User(
            id: targetThreadId, 
            name: message.senderName ?? 'Peer $targetThreadId', 
            avatarIcon: 0xe491, 
            avatarColor: 0xFF6750A4
          ),
          messages: [message],
        );
        threads.insert(0, newThread);
      }
    }
    
    state = AsyncData(threads);
    ref.read(storageServiceProvider).saveThreads(threads);
    
    if (currentSelectedId == targetThreadId) {
      if (!isGroup) sendReadReceipt(message.senderId, [message.id]);
    } else {
      final activeCall = ref.read(callProvider);
      final inActiveCallWithSender = activeCall != null && activeCall.peers.any((p) => p.id == targetThreadId);
      
      if (!inActiveCallWithSender) {
        final thread = threads.firstWhere((t) => t.id == targetThreadId);
        String notifyBody = message.text;
        if (message.type == MessageType.audio) notifyBody = '🎤 Voice message';
        if (message.type == MessageType.image) notifyBody = '📷 Image';
        
        NotificationService.showMessageNotification(
          thread.isGroup ? (thread.groupName ?? 'Group') : thread.peer.name, 
          notifyBody,
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

  void _handleConnectionOpened(String peerId) async {
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
    _flushAllPendingQueues();
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
    
    final blockedList = ref.read(blockedContactsProvider).value ?? [];
    if (blockedList.contains(peerId)) return;

    final contactsList = ref.read(contactsProvider).value ?? [];
    final isKnownContact = contactsList.any((c) => c.id == peerId);
    
    if (!isKnownContact) {
      if (_initiatedConnections.contains(peerId)) {
        _acceptPeer(newUser);
      } else {
        _requestAirDropInvite(newUser);
      }
      return;
    }
    
    _acceptPeer(newUser);
  }

  final Set<String> _pendingInvites = {};
  final Map<String, List<Message>> _pendingInviteMessages = {};

  void _requestAirDropInvite(User user, {Message? message}) {
    if (message != null) {
      _pendingInviteMessages.putIfAbsent(user.id, () => []).add(message);
    }
    
    if (_pendingInvites.contains(user.id)) return;
    _pendingInvites.add(user.id);

    final ctx = globalNavigatorKey.currentContext;
    if (ctx == null) return;
    
    NotificationService.showMessageNotification('New Connection Request', '${user.name} wants to connect with you.', inAppOnly: true);

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('New Connection Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Color(user.avatarColor),
              child: const Icon(IconData(0xe491, fontFamily: 'MaterialIcons'), size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text('${user.name} would like to share data and chat with you.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () { Navigator.pop(c); _rejectPeer(user.id); }, child: const Text('Decline', style: TextStyle(color: Colors.red))),
          FilledButton(onPressed: () { Navigator.pop(c); _acceptPeer(user); }, child: const Text('Accept')),
        ],
      ),
    );
  }

  void _rejectPeer(String id) {
    _pendingInvites.remove(id);
    _pendingInviteMessages.remove(id);
    ref.read(blockedContactsProvider.notifier).blockPeer(id);
  }

  void _acceptPeer(User user) {
    _pendingInvites.remove(user.id);
    ref.read(contactsProvider.notifier).addContact(user);
    
    if (state.hasValue) {
      final threads = List<ChatThread>.from(state.value!);
      final threadIndex = threads.indexWhere((t) => t.id == user.id);
      if (threadIndex != -1) {
        threads[threadIndex] = threads[threadIndex].copyWith(peer: user);
      } else {
        threads.insert(0, ChatThread(id: user.id, peer: user, messages: []));
      }
      state = AsyncData(threads);
      ref.read(storageServiceProvider).saveThreads(threads);
      
      if (_pendingInviteMessages.containsKey(user.id)) {
        final messages = _pendingInviteMessages.remove(user.id)!;
        for (final m in messages) {
          _handleIncomingMessage(m);
        }
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

  Future<void> initializePeer(String? customId, String myName, {String? username}) async {
    _myName = myName;
    await ref.read(peerServiceProvider).initialize(customId);
    try {
      final lanPort = await ref.read(lanMessengerProvider).startServer(customId ?? 'unknown');
      final mdnsNotifier = ref.read(nearbyPeersProvider.notifier);
      await mdnsNotifier.startBroadcasting(myId ?? 'unknown', myName, username: username, port: lanPort);
      await mdnsNotifier.startScanning(myId ?? 'unknown');
    } catch (e) {
      debugPrint('⚠️ Local Networking Initialization failed: $e');
    }
  }

  Future<void> connectToPeer(String peerId, {bool isReverseConnect = false}) async {
    final now = DateTime.now();
    if (_lastConnectAttempt.containsKey(peerId)) {
      final diff = now.difference(_lastConnectAttempt[peerId]!);
      if (diff.inSeconds < 3) return;
    }
    _lastConnectAttempt[peerId] = now;
    if (!isReverseConnect) _initiatedConnections.add(peerId);
    
    // Reverse-Host: Ask the peer to connect to us to punch through mDNS/Firewalls
    final metadata = isReverseConnect ? null : jsonEncode({
      'urgent_signal': {
        'type': 'reverse_connect_request',
        'peerId': myId ?? 'unknown',
      }
    });
    
    ref.read(peerServiceProvider).connectToPeer(peerId, metadata: metadata);
    
    final mdnsPeers = ref.read(nearbyPeersProvider);
    final lanPeer = mdnsPeers.where((p) => p.id == peerId).firstOrNull;
    if (lanPeer != null && lanPeer.ipAddress != null && lanPeer.port != null) {
      await ref.read(lanMessengerProvider).connectToPeer(peerId, lanPeer.ipAddress!, lanPeer.port!);
    }
  }

  bool _trySend(String targetId, Message message) {
    bool sent = ref.read(lanMessengerProvider).sendMessage(targetId, message);
    if (!sent) {
      sent = ref.read(peerServiceProvider).sendMessage(targetId, message);
    }
    if (!sent) {
      // Trigger our full connect flow which includes reverse_connect_request
      connectToPeer(targetId);
    }
    return sent;
  }

  Future<void> updateMyProfile(String name, int iconCodePoint, int colorValue, {String? newImagePath, bool removeImage = false}) async {
    final storage = ref.read(storageServiceProvider);
    String? finalImagePath;
    String? username;
    if (newImagePath != null) {
      finalImagePath = newImagePath;
    } else if (removeImage) {
      finalImagePath = null;
    } else {
      final oldProfile = await storage.loadUserProfile();
      finalImagePath = oldProfile?['profileImagePath'];
      username = oldProfile?['username'];
    }
    await storage.saveUserProfile(myId ?? '', name, username: username, avatarIcon: iconCodePoint, avatarColor: colorValue, profileImagePath: finalImagePath);
    _myName = name;
    final mdnsNotifier = ref.read(nearbyPeersProvider.notifier);
    await mdnsNotifier.startBroadcasting(myId ?? 'unknown', name, username: username);
    ref.invalidate(myProfileProvider);
    if (state.hasValue) {
      final profileData = {'name': name, 'avatarIcon': iconCodePoint, 'avatarColor': colorValue};
      for (final thread in state.value!) {
        if (!thread.isGroup) ref.read(peerServiceProvider).sendProfileSync(thread.id, profileData);
      }
    }
  }
  
  void startNewChat(String peerId, {String? peerName}) {
    if (!state.hasValue) return;
    final threads = List<ChatThread>.from(state.value!);
    if (!threads.any((t) => t.id == peerId)) {
      threads.insert(0, ChatThread(id: peerId, peer: User(id: peerId, name: peerName ?? 'Peer $peerId', avatarIcon: 0xe491, avatarColor: 0xFF6750A4), messages: []));
      state = AsyncData(threads);
      ref.read(storageServiceProvider).saveThreads(threads);
    }
    connectToPeer(peerId);
  }

  void createGroup(String groupName, List<User> members) {
    if (!state.hasValue) return;
    final threads = List<ChatThread>.from(state.value!);
    final groupId = const Uuid().v4();
    final groupThread = ChatThread(id: groupId, peer: User(id: groupId, name: groupName, avatarIcon: 0xe886, avatarColor: 0xFF2E7D32), messages: [], isGroup: true, groupName: groupName, members: members);
    threads.insert(0, groupThread);
    state = AsyncData(threads);
    ref.read(storageServiceProvider).saveThreads(threads);
    ref.read(selectedThreadIdProvider.notifier).select(groupId);
    sendMessage(groupId, 'Group "$groupName" created', type: MessageType.system);
  }

  void updateGroupMembers(String groupId, List<User> members) {
    if (!state.hasValue) return;
    final threads = List<ChatThread>.from(state.value!);
    final threadIndex = threads.indexWhere((t) => t.id == groupId);
    if (threadIndex != -1) {
      threads[threadIndex] = threads[threadIndex].copyWith(members: members);
      state = AsyncData(threads);
      ref.read(storageServiceProvider).saveThreads(threads);
    }
  }

  Future<void> sendMessage(String threadId, String text, {MessageType type = MessageType.text, String? localFilePath, String? fileName, String? fileData}) async {
    if (!state.hasValue) return;
    final threads = List<ChatThread>.from(state.value!);
    final threadIndex = threads.indexWhere((t) => t.id == threadId);
    if (threadIndex != -1) {
      final thread = threads[threadIndex];
      final msg = Message(
        id: const Uuid().v4(),
        senderId: myId ?? 'me',
        senderName: _myName ?? 'Me',
        text: text,
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
        type: type,
        localFilePath: localFilePath,
        fileName: fileName,
        fileData: fileData,
        groupId: thread.isGroup ? thread.id : null,
        groupName: thread.isGroup ? thread.groupName : null,
      );
      final updatedMessages = List<Message>.from(thread.messages)..add(msg);
      threads[threadIndex] = thread.copyWith(messages: updatedMessages);
      state = AsyncData(threads);
      ref.read(storageServiceProvider).saveThreads(threads);
      
      bool sent = false;
      if (thread.isGroup) {
        for (final member in thread.members) {
          if (member.id != myId && _trySend(member.id, msg)) sent = true;
        }
      } else {
        sent = _trySend(threadId, msg);
      }
      _updateMessageStatus(msg.id, sent ? MessageStatus.sent : MessageStatus.pending);
    }
  }

  void syncActivityUpdate(String threadId, String messageId, String fileData) {
    if (!state.hasValue) return;
    final threads = List<ChatThread>.from(state.value!);
    final threadIndex = threads.indexWhere((t) => t.id == threadId);
    if (threadIndex != -1) {
      final thread = threads[threadIndex];
      final msgIndex = thread.messages.indexWhere((m) => m.id == messageId);
      if (msgIndex == -1) return;
      final updatedMessages = List<Message>.from(thread.messages);
      final oldMsg = updatedMessages[msgIndex];
      updatedMessages[msgIndex] = oldMsg.copyWith(fileData: fileData);
      threads[threadIndex] = thread.copyWith(messages: updatedMessages);
      state = AsyncData(threads);
      ref.read(storageServiceProvider).saveThreads(threads);
      
      final payload = {'type': 'activity_sync', 'threadId': threadId, 'messageId': messageId, 'fileData': fileData};
      if (thread.isGroup) {
        for (final member in thread.members) {
          if (member.id != myId) _trySendSyncPayload(member.id, payload);
        }
      } else {
        _trySendSyncPayload(threadId, payload);
      }
    }
  }

  void _trySendSyncPayload(String targetId, Map<String, dynamic> payload) {
    if (!ref.read(lanMessengerProvider).sendCustomData(targetId, payload)) {
      ref.read(peerServiceProvider).sendCustomData(targetId, payload);
    }
  }
  
  void _handleActivitySync(Map<String, dynamic> data) {
    if (!state.hasValue) return;
    final messageId = data['messageId'] as String;
    final fileData = data['fileData'] as String;
    final threads = List<ChatThread>.from(state.value!);
    for (int tIdx = 0; tIdx < threads.length; tIdx++) {
      final thread = threads[tIdx];
      final mIdx = thread.messages.indexWhere((m) => m.id == messageId);
      if (mIdx != -1) {
        final updatedMessages = List<Message>.from(thread.messages);
        updatedMessages[mIdx] = updatedMessages[mIdx].copyWith(fileData: fileData);
        threads[tIdx] = thread.copyWith(messages: updatedMessages);
        state = AsyncData(threads);
        ref.read(storageServiceProvider).saveThreads(threads);
        break;
      }
    }
  }



  void sendTypingIndicator(String threadId) {
    if (!state.hasValue) return;
    final threads = state.value!;
    final thread = threads.firstWhere((t) => t.id == threadId, orElse: () => threads.first);
    final myId = ref.read(peerServiceProvider).myId ?? 'me';
    
    if (thread.isGroup) {
      for (final member in thread.members) {
        if (member.id != myId) {
          ref.read(lanMessengerProvider).sendTypingIndicator(member.id);
          ref.read(peerServiceProvider).sendTypingIndicator(member.id);
        }
      }
    } else {
      ref.read(lanMessengerProvider).sendTypingIndicator(threadId);
      ref.read(peerServiceProvider).sendTypingIndicator(threadId);
    }
  }

  void sendReadReceipt(String threadId, List<String> messageIds) {
    if (messageIds.isEmpty) return;
    if (!state.hasValue) return;
    // Update local DB first
    final threads = List<ChatThread>.from(state.value!);
    final threadIndex = threads.indexWhere((t) => t.id == threadId);
    ChatThread? thread;
    if (threadIndex != -1) {
      thread = threads[threadIndex];
      bool updated = false;
      final msgs = List<Message>.from(thread.messages);
      for (int i = 0; i < msgs.length; i++) {
        if (messageIds.contains(msgs[i].id) && msgs[i].status != MessageStatus.read) {
          msgs[i] = msgs[i].copyWith(status: MessageStatus.read);
          updated = true;
        }
      }
      if (updated) {
        threads[threadIndex] = thread.copyWith(messages: msgs);
        state = AsyncData(threads);
        ref.read(storageServiceProvider).saveThreads(threads);
      }
    }
    
    final myId = ref.read(peerServiceProvider).myId ?? 'me';
    // Send over network
    if (thread != null && thread.isGroup) {
      for (final member in thread.members) {
        if (member.id != myId) {
          ref.read(lanMessengerProvider).sendReadReceipt(member.id, messageIds);
          ref.read(peerServiceProvider).sendReadReceipt(member.id, messageIds);
        }
      }
    } else {
      ref.read(lanMessengerProvider).sendReadReceipt(threadId, messageIds);
      ref.read(peerServiceProvider).sendReadReceipt(threadId, messageIds);
    }
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

  void updateGroupProfile(String groupId, String? name, String? imagePath) {
    if (!state.hasValue) return;
    final threads = List<ChatThread>.from(state.value!);
    final threadIndex = threads.indexWhere((t) => t.id == groupId);
    if (threadIndex != -1) {
      final oldThread = threads[threadIndex];
      threads[threadIndex] = oldThread.copyWith(
        groupName: name ?? oldThread.groupName,
        groupImagePath: imagePath ?? oldThread.groupImagePath,
        peer: oldThread.peer.copyWith(
          name: name ?? oldThread.groupName,
          profileImagePath: imagePath ?? oldThread.groupImagePath,
        ),
      );
      state = AsyncData(threads);
      ref.read(storageServiceProvider).saveThreads(threads);
    }
  }

  void joinGroup(String groupId, String groupName, String? imagePath) {
    if (!state.hasValue) return;
    final threads = List<ChatThread>.from(state.value!);
    final threadIndex = threads.indexWhere((t) => t.id == groupId);
    
    if (threadIndex == -1) {
      final myId = ref.read(peerServiceProvider).myId ?? 'me';
      final myName = this.myName ?? 'Peer $myId';
      
      final newGroup = ChatThread(
        id: groupId,
        peer: User(id: groupId, name: groupName, avatarIcon: 0xe886, avatarColor: 0xFF2E7D32),
        messages: [],
        isGroup: true,
        groupName: groupName,
        groupImagePath: imagePath,
        members: [
          User(id: myId, name: myName, avatarIcon: 0xe491, avatarColor: 0xFF6750A4)
        ],
      );
      threads.insert(0, newGroup);
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
    data: (threads) => threads.where((t) => t.id == id).firstOrNull,
    orElse: () => null,
  );
});
