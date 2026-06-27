import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/models/chat_thread.dart';
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
                    // Placeholder for adding members
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
