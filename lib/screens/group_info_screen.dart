import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/models/chat_thread.dart';
import 'package:abyss_chat/models/user.dart';
import 'package:abyss_chat/providers/chat_provider.dart';
import 'package:abyss_chat/services/mdns_service.dart';
import 'package:abyss_chat/widgets/user_avatar.dart';

class GroupInfoScreen extends ConsumerWidget {
  final ChatThread thread;

  const GroupInfoScreen({super.key, required this.thread});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(thread.groupName ?? 'Group Info'),
              background: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Center(
                  child: Icon(
                    Icons.group, 
                    size: 100, 
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${thread.members.length} Participants',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(Icons.person_add, color: Colors.white),
                  ),
                  title: const Text('Add Participants'),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => _AddParticipantsSheet(thread: thread),
                    );
                  },
                ),
                const Divider(),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: thread.members.length,
                  itemBuilder: (context, index) {
                    final member = thread.members[index];
                    return ListTile(
                      leading: UserAvatar(user: member, radius: 20),
                      title: Text(member.name),
                      subtitle: Text(member.id),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title: const Text('Exit Group', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    // Leave group logic
                    Navigator.pop(context);
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
}

class _AddParticipantsSheet extends ConsumerStatefulWidget {
  final ChatThread thread;
  const _AddParticipantsSheet({required this.thread});

  @override
  ConsumerState<_AddParticipantsSheet> createState() => _AddParticipantsSheetState();
}

class _AddParticipantsSheetState extends ConsumerState<_AddParticipantsSheet> {
  final List<User> _selected = [];

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(contactsProvider).value ?? [];
    final nearbyPeers = ref.watch(nearbyPeersProvider);
    
    // Combine contacts and nearby peers, removing duplicates by ID
    final allAvailable = <String, User>{};
    for (var c in contacts) {
      allAvailable[c.id] = c;
    }
    for (var p in nearbyPeers) {
      allAvailable[p.id] = p;
    }
    
    // Filter out users already in the group
    final existingIds = widget.thread.members.map((m) => m.id).toSet();
    final usersList = allAvailable.values.where((u) => !existingIds.contains(u.id)).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Add Participants', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: _selected.isEmpty ? null : () {
                  final threads = List<ChatThread>.from(ref.read(chatThreadsProvider).value ?? []);
                  final threadIndex = threads.indexWhere((t) => t.id == widget.thread.id);
                  if (threadIndex != -1) {
                    final updatedMembers = List<User>.from(threads[threadIndex].members)..addAll(_selected);
                    threads[threadIndex] = threads[threadIndex].copyWith(members: updatedMembers);
                    ref.read(chatThreadsProvider.notifier).updateGroupMembers(widget.thread.id, updatedMembers);
                  }
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: usersList.isEmpty
                ? const Center(child: Text('No new contacts found.'))
                : ListView.builder(
                    itemCount: usersList.length,
                    itemBuilder: (context, index) {
                      final user = usersList[index];
                      final isSelected = _selected.any((m) => m.id == user.id);
                      
                      return ListTile(
                        leading: UserAvatar(user: user, radius: 20),
                        title: Text(user.name),
                        subtitle: Text(user.id),
                        trailing: isSelected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selected.removeWhere((m) => m.id == user.id);
                            } else {
                              _selected.add(user);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
