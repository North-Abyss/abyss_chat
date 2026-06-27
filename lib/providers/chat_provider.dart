import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/models/chat_thread.dart';
import 'package:abyss_chat/models/message.dart';
import 'package:abyss_chat/models/user.dart';
import 'package:abyss_chat/services/peerdart_service.dart';
import 'package:abyss_chat/services/storage_service.dart';
import 'package:abyss_chat/services/mdns_service.dart';
import 'package:abyss_chat/models/call_log.dart';
import 'package:abyss_chat/services/lan_messenger.dart';
import 'package:abyss_chat/services/notification_service.dart';
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
  }

  void blockContact(String id) {
    deleteContact(id); // For now, blocking just deletes
  }
}

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
  );
});

class ChatThreadsNotifier extends AsyncNotifier<List<ChatThread>> {
  String? get myId => ref.read(peerServiceProvider).myId;
  String? _myName;
  String? get myName => _myName;

  @override
  Future<List<ChatThread>> build() async {
    final storage = ref.watch(storageServiceProvider);
    final peer = ref.watch(peerServiceProvider);
    final lan = ref.watch(lanMessengerProvider);
    
    // Listen for real incoming WebRTC messages
    final sub1 = peer.onMessageReceived.listen((message) {
      _handleIncomingMessage(message);
    });
    
    // Listen for incoming LAN TCP messages
    final sub2 = lan.onMessageReceived.listen((message) {
      _handleIncomingMessage(message);
    });
    
    ref.onDispose(() {
      sub1.cancel();
      sub2.cancel();
    });

    // Load persisted threads from disk
    return await storage.loadThreads();
  }

  void _handleIncomingMessage(Message message) {
    if (!state.hasValue) return;
    
    final threads = List<ChatThread>.from(state.value!);
    final senderId = message.senderId;
    
    // Find if we already have a thread with this peer
    int threadIndex = threads.indexWhere((t) => t.peer.id == senderId);
    
    if (threadIndex != -1) {
      // Append message
      threads[threadIndex].messages.add(message);
    } else {
      // Create new thread automatically when we receive a message from unknown peer
      final newThread = ChatThread(
        id: senderId, // Use their UUID as the thread ID
        peer: User(id: senderId, name: 'Peer $senderId', avatarIcon: 0xe491, avatarColor: 0xFF6750A4),
        messages: [message],
      );
      threads.insert(0, newThread);
    }
    
    state = AsyncData(threads);
    ref.read(storageServiceProvider).saveThreads(threads);
    
    // Show notification if this thread is not actively open
    final currentSelectedId = ref.read(selectedThreadIdProvider);
    if (currentSelectedId != senderId) {
      final thread = threads.firstWhere((t) => t.id == senderId);
      NotificationService.showMessageNotification(
        thread.isGroup ? (thread.groupName ?? 'Group') : thread.peer.name, 
        message.text,
      );
    }
  }

  /// Initialize the local peer and connect to signaling
  Future<void> initializePeer(String? customId, String myName) async {
    _myName = myName;
    await ref.read(peerServiceProvider).initialize(customId);
    
    // Start LAN Server
    final lanPort = await ref.read(lanMessengerProvider).startServer(customId ?? 'unknown');
    
    // Start mDNS
    final mdnsNotifier = ref.read(nearbyPeersProvider.notifier);
    await mdnsNotifier.startBroadcasting(myId ?? 'unknown', myName, port: lanPort);
    await mdnsNotifier.startScanning(myId ?? 'unknown');
  }

  /// Connect to a remote peer (starts WebRTC handshake + LAN TCP if available)
  Future<void> connectToPeer(String peerId) async {
    // Check if peer is on LAN
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

  Future<void> updateMyProfile(String name, int iconCodePoint, int colorValue) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveUserProfile(myId ?? '', name, avatarIcon: iconCodePoint, avatarColor: colorValue);
    
    _myName = name;
    
    // Refresh mDNS with new name
    final mdnsNotifier = ref.read(nearbyPeersProvider.notifier);
    await mdnsNotifier.startBroadcasting(myId ?? 'unknown', name);
    
    // Invalidate profile provider so UI updates
    ref.invalidate(myProfileProvider);
  }
  
  /// Start a new chat manually
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
      peer: User(id: groupId, name: groupName, avatarIcon: 0xe886, avatarColor: 0xFF2E7D32), // default group icon/color
      messages: [],
      isGroup: true,
      groupName: groupName,
      members: members,
    );
    
    threads.insert(0, groupThread);
    state = AsyncData(threads);
    ref.read(storageServiceProvider).saveThreads(threads);
    
    // Auto-select the new group
    ref.read(selectedThreadIdProvider.notifier).select(groupId);
    
    // System message to group
    final sysMsg = Message(
      id: const Uuid().v4(),
      senderId: myId ?? 'me',
      senderName: myName ?? 'You',
      text: 'Group "$groupName" created',
      timestamp: DateTime.now(),
      type: MessageType.system,
    );
    sendMessage(groupId, sysMsg.text);
  }

  Future<void> sendMessage(String threadId, String text) async {
    if (!state.hasValue) return;
    
    final msg = Message(
      id: const Uuid().v4(),
      senderId: ref.read(peerServiceProvider).myId ?? 'me',
      text: text,
      timestamp: DateTime.now(),
      isRead: false,
    );

    final threads = List<ChatThread>.from(state.value!);
    final threadIndex = threads.indexWhere((t) => t.id == threadId);
    
    if (threadIndex != -1) {
      threads[threadIndex].messages.add(msg);
      state = AsyncData(threads);
      
      // Save to disk
      ref.read(storageServiceProvider).saveThreads(threads);
      
      // Try LAN first
      final sentViaLan = ref.read(lanMessengerProvider).sendMessage(threadId, msg);
      
      // Send over WebRTC if LAN fails
      if (!sentViaLan) {
        if (threads[threadIndex].isGroup) {
          // Send to all members
          for (final member in threads[threadIndex].members) {
            if (member.id != myId) {
               ref.read(peerServiceProvider).sendMessage(member.id, msg);
            }
          }
        } else {
           ref.read(peerServiceProvider).sendMessage(threadId, msg);
        }
      }
    }
  }

  void deleteThread(String threadId) {
    if (!state.hasValue) return;
    final threads = List<ChatThread>.from(state.value!);
    threads.removeWhere((t) => t.id == threadId);
    state = AsyncData(threads);
    ref.read(storageServiceProvider).saveThreads(threads);
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

final chatThreadsProvider =
    AsyncNotifierProvider<ChatThreadsNotifier, List<ChatThread>>(() {
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
