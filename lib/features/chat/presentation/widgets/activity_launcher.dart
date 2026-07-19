import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/features/chat/domain/models/message.dart';
import 'package:abyss_chat/features/chat/domain/chat_controller.dart';
import 'package:abyss_chat/core/widgets/user_avatar.dart';
import 'package:abyss_chat/features/chat/presentation/screens/chat_screen.dart';
import 'package:abyss_chat/app/responsive_layout.dart';

class ActivityLauncher {
  static void show(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _ActivitySheet(),
    );
  }
}

class _ActivitySheet extends ConsumerStatefulWidget {
  const _ActivitySheet();

  @override
  ConsumerState<_ActivitySheet> createState() => _ActivitySheetState();
}

class _ActivitySheetState extends ConsumerState<_ActivitySheet> {
  String? _selectedActivity;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (_selectedActivity == null)
              ...[
                Text(
                  'Launch Activity',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildActivityOption(
                  context,
                  title: 'Coin Toss',
                  subtitle: 'Heads or Tails',
                  icon: Icons.monetization_on,
                  color: Colors.amber,
                  onTap: () => setState(() => _selectedActivity = 'coin'),
                ),
                _buildActivityOption(
                  context,
                  title: 'Roll Dice',
                  subtitle: 'Roll 1 to 4 dice',
                  icon: Icons.casino,
                  color: Colors.blue,
                  onTap: () => setState(() => _selectedActivity = 'dice'),
                ),
                _buildActivityOption(
                  context,
                  title: 'Tic-Tac-Toe',
                  subtitle: 'Start a 3x3 game',
                  icon: Icons.grid_3x3,
                  color: Colors.red,
                  onTap: () => setState(() => _selectedActivity = 'tictactoe'),
                ),
                _buildActivityOption(
                  context,
                  title: 'Poll',
                  subtitle: 'Create a poll for a group',
                  icon: Icons.poll,
                  color: Colors.purple,
                  onTap: () => setState(() => _selectedActivity = 'poll'),
                ),
              ]
            else
              ...[
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => _selectedActivity = null),
                    ),
                    Text(
                      'Select Chat',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildChatSelector(context, ref),
              ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildActivityOption(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildChatSelector(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(chatThreadsProvider);
    
    return threadsAsync.when(
      data: (threads) {
        if (threads.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Text('No active chats found. Start a chat first!'),
          );
        }
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: threads.length,
            itemBuilder: (context, index) {
              final thread = threads[index];
              return ListTile(
                leading: UserAvatar(user: thread.peer, radius: 20),
                title: Text(thread.isGroup ? (thread.groupName ?? 'Group') : thread.peer.name),
                onTap: () => _launchActivity(thread.id),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _launchActivity(String threadId) {
    if (_selectedActivity == 'coin') {
      final result = Random().nextBool() ? 'Heads' : 'Tails';
      final payload = jsonEncode({'activity': 'coin', 'result': result});
      ref.read(chatThreadsProvider.notifier).sendMessage(threadId, '🪙 Tossed a coin', type: MessageType.activity, fileData: payload);
      Navigator.pop(context);
      _openChat(threadId);
    } else if (_selectedActivity == 'dice') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Roll how many dice?'),
          content: Wrap(
            spacing: 8,
            children: List.generate(4, (i) => ChoiceChip(
              label: Text('${i+1}'),
              selected: false,
              onSelected: (_) {
                Navigator.of(context, rootNavigator: true).pop(); // close dialog
                Navigator.of(context).pop(); // close sheet
                final rolls = List.generate(i+1, (_) => Random().nextInt(6) + 1);
                final payload = jsonEncode({'activity': 'dice', 'rolls': rolls});
                ref.read(chatThreadsProvider.notifier).sendMessage(threadId, '🎲 Rolled ${i+1} dice', type: MessageType.activity, fileData: payload);
                _openChat(threadId);
              },
            )),
          ),
        ),
      );
    } else if (_selectedActivity == 'tictactoe') {
      final payload = jsonEncode({'activity': 'tictactoe', 'board': List.filled(9, ''), 'turn': 'X', 'state': 'playing', 'initiator': ref.read(chatThreadsProvider.notifier).myId});
      ref.read(chatThreadsProvider.notifier).sendMessage(threadId, '❌ Started Tic-Tac-Toe', type: MessageType.activity, fileData: payload);
      Navigator.pop(context);
      _openChat(threadId);
    } else if (_selectedActivity == 'poll') {
      _showPollDialog(threadId);
    }
  }

  void _showPollDialog(String threadId) {
    final qController = TextEditingController();
    final optController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Poll'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qController,
              decoration: const InputDecoration(labelText: 'Question'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: optController,
              decoration: const InputDecoration(labelText: 'Options (comma separated)', hintText: 'Yes, No, Maybe'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final q = qController.text.trim();
              final opts = optController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
              if (q.isNotEmpty && opts.length > 1) {
                final payload = jsonEncode({
                  'activity': 'poll',
                  'question': q,
                  'options': opts,
                  'votes': {},
                });
                ref.read(chatThreadsProvider.notifier).sendMessage(threadId, '📊 Created a poll', type: MessageType.activity, fileData: payload);
                Navigator.pop(ctx);
                Navigator.pop(context);
                _openChat(threadId);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _openChat(String threadId) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    if (isDesktop) {
      ref.read(navigationIndexProvider.notifier).setIndex(0);
      ref.read(selectedThreadIdProvider.notifier).select(threadId);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(threadId: threadId)));
    }
  }
}
