import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/features/contacts/domain/models/user.dart';
import 'package:abyss_chat/core/widgets/user_avatar.dart';
import 'package:abyss_chat/features/contacts/domain/contacts_controller.dart';
import 'package:share_plus/share_plus.dart';

class ContactProfileScreen extends ConsumerWidget {
  final User peer;

  const ContactProfileScreen({super.key, required this.peer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final livePeer = ref.watch(contactsProvider).value?.firstWhere(
              (u) => u.id == peer.id,
              orElse: () => peer,
            ) ??
        peer;

    void renameContact(String currentName) {
      final controller = TextEditingController(text: currentName);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Rename Contact'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Contact Name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      ).then((newName) {
        if (newName != null && newName.isNotEmpty && newName != currentName) {
          ref.read(contactsProvider.notifier).updateContactMetadata(
                livePeer.id,
                newName: newName,
              );
        }
      });
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => renameContact(livePeer.name),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(livePeer.name),
              background: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    UserAvatar(user: livePeer, radius: 60),
                    const SizedBox(height: 8),
                    Text(
                      'ID: ${livePeer.id}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(context, Icons.message, 'Message', () {
                      Navigator.pop(context);
                      // Already in chat if navigated from chat, else find thread
                    }),
                    _buildActionButton(context, Icons.call, 'Audio', () {}),
                    _buildActionButton(context, Icons.videocam, 'Video', () {}),
                  ],
                ),
                const Divider(height: 32),
                ListTile(
                  leading: Icon(
                    livePeer.isFavorite ? Icons.star : Icons.star_border,
                    color: livePeer.isFavorite ? Colors.amber : null,
                  ),
                  title: const Text('Favorite contact'),
                  trailing: Switch(
                    value: livePeer.isFavorite,
                    onChanged: (val) {
                      ref.read(contactsProvider.notifier).updateContactMetadata(
                            livePeer.id,
                            isFavorite: val,
                          );
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.photo),
                  title: const Text('Media, links, and docs'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.star),
                  title: const Text('Starred messages'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.search),
                  title: const Text('Search'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Share contact'),
                  onTap: () {
                    final usernameStr = peer.username != null
                        ? ' (@${peer.username})'
                        : '';
                    final shareText =
                        'Add ${peer.name}$usernameStr on Abyss Chat! ID: ${peer.id}';
                    // ignore: deprecated_member_use
                    Share.share(shareText);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text(
                    'Block contact',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Block contact?'),
                        content: Text(
                          'Are you sure you want to block ${peer.name}? You will no longer receive messages from them.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () {
                              ref
                                  .read(contactsProvider.notifier)
                                  .blockContact(peer.id);
                              Navigator.pop(context); // Close dialog
                              Navigator.pop(context); // Close profile
                            },
                            child: const Text('Block'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete contact',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete contact?'),
                        content: Text(
                          'Are you sure you want to delete ${peer.name}? This will also delete your entire chat history with them.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () {
                              ref
                                  .read(contactsProvider.notifier)
                                  .deleteContact(peer.id);
                              Navigator.pop(context); // Close dialog
                              Navigator.pop(context); // Close profile
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
