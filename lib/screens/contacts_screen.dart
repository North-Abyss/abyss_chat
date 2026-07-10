import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/providers/chat_provider.dart';
import 'package:abyss_chat/widgets/user_avatar.dart';
import 'package:abyss_chat/screens/chat_screen.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
      ),
      body: contactsAsync.when(
        data: (contacts) {
          if (contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.contacts, size: 64, color: cs.primary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('No contacts yet', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Connect with people to add them here.',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return ListTile(
                leading: UserAvatar(user: contact, radius: 24),
                title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('ID: ${contact.id}', style: TextStyle(color: cs.onSurfaceVariant)),
                trailing: const Icon(Icons.chat_bubble_outline),
                onTap: () {
                  ref.read(chatThreadsProvider.notifier).startNewChat(contact.id, peerName: contact.name);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => ChatScreen(threadId: contact.id)),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
