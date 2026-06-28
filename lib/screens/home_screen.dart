import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/providers/chat_provider.dart';
import 'package:abyss_chat/screens/chat_screen.dart';
import 'package:abyss_chat/services/mdns_service.dart';
import 'package:abyss_chat/widgets/abyss_snackbar.dart';
import 'package:abyss_chat/widgets/user_avatar.dart';
import 'package:abyss_chat/services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:abyss_chat/screens/contact_profile_screen.dart';
import 'package:abyss_chat/screens/create_group_screen.dart';

class HomeScreen extends ConsumerWidget {
  final bool isDesktop;
  const HomeScreen({super.key, this.isDesktop = false});

  void _showNewChatDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect to Peer'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Enter Friend's UUID",
            hintText: 'e.g. 1a2b3c4d',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final peerId = controller.text.trim();
              if (peerId.isNotEmpty) {
                ref.read(chatThreadsProvider.notifier).startNewChat(peerId);
                Navigator.pop(context);
                if (isDesktop) {
                  ref.read(selectedThreadIdProvider.notifier).select(peerId);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChatScreen(threadId: peerId)),
                  );
                }
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _showConnectByIdDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Connect to Peer'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter Peer ID',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton.tonal(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  ref.read(chatThreadsProvider.notifier).startNewChat(controller.text.trim());
                  Navigator.pop(context);
                }
              },
              child: const Text('Connect'),
            ),
          ],
        );
      },
    );
  }

  void _showNearbyPeersDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final peers = ref.watch(nearbyPeersProvider);
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nearby Users (mDNS)', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  if (peers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No users found on local network. Ensure both devices are on the same Wi-Fi.'),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: peers.length,
                        itemBuilder: (context, index) {
                          final peer = peers[index];
                          return ListTile(
                            leading: UserAvatar(user: peer, radius: 20),
                            title: Text(peer.name),
                            subtitle: Text('ID: ${peer.id}'),
                            trailing: FilledButton.tonal(
                              onPressed: () {
                                ref.read(chatThreadsProvider.notifier).startNewChat(peer.id, peerName: peer.name);
                                Navigator.pop(context);
                                if (isDesktop) {
                                  ref.read(selectedThreadIdProvider.notifier).select(peer.id);
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => ChatScreen(threadId: peer.id)),
                                  );
                                }
                              },
                              child: const Text('Connect'),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncThreads = ref.watch(chatThreadsProvider);
    final selectedId = ref.watch(selectedThreadIdProvider);
    final myId = ref.read(chatThreadsProvider.notifier).myId;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Abyss Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            if (myId != null) 
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: myId));
                  NotificationService.showMessageNotification('Abyss Chat', 'Copied ID to clipboard');
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy, size: 10, color: Theme.of(context).colorScheme.onPrimaryContainer),
                      const SizedBox(width: 4),
                      Text(
                        'ID: $myId', 
                        style: TextStyle(
                          fontSize: 11, 
                          fontWeight: FontWeight.bold, 
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'scan') {
                _showNearbyPeersDialog(context, ref);
              } else if (value == 'connect') {
                _showConnectByIdDialog(context, ref);
              }
            },
            itemBuilder: (context) => [
              if (!kIsWeb)
                const PopupMenuItem(
                  value: 'scan',
                  child: Text('Radar (Local Scan)'),
                ),
              const PopupMenuItem(
                value: 'connect',
                child: Text('Connect via ID'),
              ),
            ],
          ),
        ],
      ),
      body: asyncThreads.when(
        data: (threads) {
          if (threads.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline, 
                      size: 64, 
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                    ),
                    const SizedBox(height: 16),
                    Text('No active chats yet', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Connect with a friend to start chatting securely.', 
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _showConnectByIdDialog(context, ref),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Connect via ID'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: threads.length,
            itemBuilder: (context, index) {
              final thread = threads[index];
              final lastMessage = thread.messages.isNotEmpty 
                ? thread.messages.last 
                : null;
              final isSelected = isDesktop && selectedId == thread.id;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Card(
                  elevation: isSelected ? 4 : 1,
                  shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    selected: isSelected,
                    selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                    leading: Stack(
                      children: [
                        UserAvatar(user: thread.peer, radius: 24),
                        if (thread.isGroup)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.group, size: 14, color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      thread.isGroup ? (thread.groupName ?? 'Group') : thread.peer.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      lastMessage?.text ?? 'No messages yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (lastMessage != null)
                          Text(
                            _formatDate(lastMessage.timestamp),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: thread.unreadCount > 0 ? Theme.of(context).colorScheme.primary : null,
                                ),
                          ),
                        if (thread.unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${thread.unreadCount}',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    onLongPress: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.person),
                            title: const Text('View Profile'),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ContactProfileScreen(peer: thread.peer)));
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.clear_all),
                            title: const Text('Clear Messages'),
                            onTap: () {
                              ref.read(chatThreadsProvider.notifier).clearMessages(thread.id);
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.delete, color: Colors.red),
                            title: const Text('Delete Chat', style: TextStyle(color: Colors.red)),
                            onTap: () {
                              ref.read(chatThreadsProvider.notifier).deleteThread(thread.id);
                              if (isDesktop && selectedId == thread.id) {
                                ref.read(selectedThreadIdProvider.notifier).select(null);
                              }
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                onTap: () {
                  if (isDesktop) {
                    ref.read(selectedThreadIdProvider.notifier).select(thread.id);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(threadId: thread.id),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        },
      );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_add),
                    title: const Text('New Chat'),
                    onTap: () {
                      Navigator.pop(context);
                      _showNewChatDialog(context, ref);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.group_add),
                    title: const Text('New Group'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
                    },
                  ),
                  if (!kIsWeb)
                    ListTile(
                      leading: const Icon(Icons.radar),
                      title: const Text('Scan Nearby (mDNS)'),
                      onTap: () {
                        Navigator.pop(context);
                        _showNearbyPeersDialog(context, ref);
                      },
                    )
                  else
                    ListTile(
                      leading: Icon(Icons.radar, color: Theme.of(context).disabledColor),
                      title: Text('Scan Nearby (Native Only)', style: TextStyle(color: Theme.of(context).disabledColor)),
                      onTap: () {
                        Navigator.pop(context);
                        AbyssSnackBar.show(context, 'Local network scanning (mDNS) is not supported in web browsers due to security restrictions. Please use Connect via ID.', type: SnackBarType.info);
                      },
                    ),
                ],
              ),
            ),
          );
        },
        child: const Icon(Icons.message),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0 && now.day == date.day) {
      return DateFormat.jm().format(date); // e.g. 5:30 PM
    } else if (difference.inDays == 1 || (difference.inDays == 0 && now.day != date.day)) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat.E().format(date); // e.g. Mon
    } else {
      return DateFormat('dd/MM/yy').format(date);
    }
  }
}
