import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/features/calling/domain/call_controller.dart';
import 'package:abyss_chat/features/games/domain/game_controller.dart';
import 'package:abyss_chat/features/games/domain/models/game_state.dart';
import 'package:abyss_chat/features/chat/domain/chat_controller.dart';

class ActiveStatusBanner extends ConsumerStatefulWidget {
  final String threadId;
  const ActiveStatusBanner({super.key, required this.threadId});

  @override
  ConsumerState<ActiveStatusBanner> createState() => _ActiveStatusBannerState();
}

class _ActiveStatusBannerState extends ConsumerState<ActiveStatusBanner> {
  bool _isMinimized = false;

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callProvider);
    final gameState = ref.watch(gameControllerProvider);

    if (callState != null &&
        callState.isGroup &&
        (callState.threadId == widget.threadId || callState.peers.any((p) => p.id == widget.threadId || widget.threadId == p.name))) {
      return _buildCallBanner(context, callState);
    }

    if (gameState != null && gameState.participants.contains(widget.threadId)) {
      return _buildGameBanner(context, gameState);
    }

    return const SizedBox.shrink();
  }

  Widget _buildCallBanner(
    BuildContext context,
    CallSession callState,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.group, color: cs.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Group Call',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                Text(
                  'Tap to join',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (callState.state == CallState.connected || callState.state == CallState.ringing) ...[
            ElevatedButton(
              onPressed: () {
                ref.read(callProvider.notifier).endCall();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
              ),
              child: const Text('End'),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: () {
                ref.read(callProvider.notifier).answerCall();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
              child: const Text('Join'),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildGameBanner(
    BuildContext context,
    GameState gameState,
  ) {
    final cs = Theme.of(context).colorScheme;
    final myId = ref.read(chatThreadsProvider.notifier).myId;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                gameState.type == GameType.ticTacToe
                    ? Icons.grid_3x3
                    : Icons.psychology,
                color: cs.onTertiaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  gameState.type == GameType.ticTacToe
                      ? 'Tic-Tac-Toe'
                      : 'Guessing Game',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.onTertiaryContainer,
                  ),
                ),
              ),
              if (gameState.isFinished)
                Text(
                  gameState.winnerId == null
                      ? 'Draw!'
                      : (gameState.winnerId == myId ? 'You Won!' : 'Winner!'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                )
              else if (gameState.type == GameType.ticTacToe)
                Text(
                  gameState.currentTurnId == myId
                      ? 'Your Turn'
                      : "Opponent's Turn",
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onTertiaryContainer.withValues(alpha: 0.8),
                  ),
                )
              else if (gameState.type == GameType.guessing)
                Text(
                  'Category: ${gameState.category}',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onTertiaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              IconButton(
                icon: Icon(_isMinimized ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up),
                color: cs.onTertiaryContainer,
                onPressed: () {
                  setState(() {
                    _isMinimized = !_isMinimized;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.power_settings_new),
                color: cs.error,
                onPressed: () =>
                    ref.read(gameControllerProvider.notifier).quitGame(),
              ),
            ],
          ),
          if (!_isMinimized && gameState.type == GameType.ticTacToe) ...[
            const SizedBox(height: 12),
            _buildTicTacToeBoard(context, ref, gameState, myId),
          ],
        ],
      ),
    );
  }

  Widget _buildTicTacToeBoard(
    BuildContext context,
    WidgetRef ref,
    GameState gameState,
    String? myId,
  ) {
    final cs = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: 9,
          itemBuilder: (context, index) {
            final cell = gameState.board[index];
            return GestureDetector(
              onTap: () {
                ref
                    .read(gameControllerProvider.notifier)
                    .makeTicTacToeMove(index);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    cell,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: cell == 'X' ? Colors.blue : Colors.red,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
