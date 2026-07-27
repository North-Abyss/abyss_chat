import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/features/chat/domain/models/message.dart';
import 'package:abyss_chat/features/chat/domain/chat_controller.dart';
import 'models/game_state.dart';

final gameControllerProvider = NotifierProvider<GameController, GameState?>(() {
  return GameController();
});

class GameController extends Notifier<GameState?> {
  @override
  GameState? build() => null;

  void handleGameMessage(Message message) {
    if (message.fileData != null) {
      final stateUpdate = GameState.fromJson(message.fileData!);
      state = stateUpdate;
    }
  }

  void startGame(
    GameType type, {
    String? category,
    String? answer,
    required List<String> participants,
    String? threadId,
  }) {
    final myId = ref.read(chatThreadsProvider.notifier).myId;
    if (myId == null) return;

    final newState = GameState(
      gameId: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      hostId: myId,
      participants: participants,
      currentTurnId: participants.first,
      category: category,
      answer: answer, // Kept locally
      threadId: threadId,
    );

    state = newState;
    _broadcastGameState();
  }

  void _broadcastGameState() {
    if (state == null) return;
    final myId = ref.read(chatThreadsProvider.notifier).myId;
    if (myId == null) return;

    // Remove the answer before broadcasting to prevent cheating
    final broadcastState = state!.copyWith(answer: '');

    final payload = broadcastState.toJson();

    final peerService = ref.read(peerServiceProvider);
    final lanMessenger = ref.read(lanMessengerProvider);

    // Broadcast to all participants except me
    for (final peerId in state!.participants) {
      if (peerId == myId) continue;

      final msgMap = {'type': 'game_sync', 'data': payload};

      peerService.sendCustomData(peerId, msgMap);
      lanMessenger.sendCustomData(peerId, msgMap);
    }
  }

  void handleIncomingGameSync(String payload) {
    try {
      final data = jsonDecode(payload);
      if (data['type'] == 'quit') {
        if (state != null && state!.gameId == data['gameId']) {
          state = null;
        }
        return;
      }
    } catch (_) {}
    state = GameState.fromJson(payload);
  }

  // Tic-Tac-Toe
  void makeTicTacToeMove(int index) {
    if (state == null || state!.type != GameType.ticTacToe || state!.isFinished) {
      return;
    }
    final myId = ref.read(chatThreadsProvider.notifier).myId;
    if (state!.currentTurnId != myId) return;
    if (state!.board[index].isNotEmpty) return;

    final newBoard = List<String>.from(state!.board);
    // Determine my symbol (Host is X, guest is O)
    final mySymbol = state!.hostId == myId ? 'X' : 'O';
    newBoard[index] = mySymbol;

    // Check win
    final winLines = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    bool hasWon = false;
    for (final line in winLines) {
      if (newBoard[line[0]] == mySymbol &&
          newBoard[line[1]] == mySymbol &&
          newBoard[line[2]] == mySymbol) {
        hasWon = true;
        break;
      }
    }

    final isDraw = !hasWon && !newBoard.contains('');
    final nextTurnId = state!.participants.firstWhere(
      (id) => id != myId,
      orElse: () => state!.participants.first,
    );

    state = state!.copyWith(
      board: newBoard,
      isFinished: hasWon || isDraw,
      winnerId: hasWon ? myId : null,
      currentTurnId: nextTurnId,
    );

    _broadcastGameState();
    
    if (state!.isFinished && state!.threadId != null) {
      String msgText = hasWon ? '🎉 I won the game!' : '🤝 Game ended in a draw.';
      final payload = jsonEncode({
        'activity': 'tictactoe',
        'board': newBoard,
        'turn': 'X',
        'state': hasWon ? 'won_X' : 'draw',
        'initiator': state!.hostId,
      });
      ref.read(chatThreadsProvider.notifier).sendMessage(
        state!.threadId!,
        msgText,
        type: MessageType.activity,
        fileData: payload,
      );

      // Auto-quit after 2 seconds so the banner dismisses
      Future.delayed(const Duration(seconds: 2), () {
        quitGame();
      });
    }
  }

  // Guessing Game
  void checkGuess(String guess, String playerId) {
    if (state == null || state!.type != GameType.guessing || state!.isFinished) {
      return;
    }

    final myId = ref.read(chatThreadsProvider.notifier).myId;
    if (state!.hostId != myId) return; // Only host checks guesses

    if (state!.answer != null &&
        state!.answer!.toLowerCase() == guess.toLowerCase().trim()) {
      state = state!.copyWith(isFinished: true, winnerId: playerId);
      _broadcastGameState();
      
      if (state!.threadId != null) {
        final payload = jsonEncode({
          'activity': 'guessing',
          'winnerId': playerId,
          'answer': state!.answer,
        });
        ref.read(chatThreadsProvider.notifier).sendMessage(
          state!.threadId!,
          '🎉 The word was guessed correctly!',
          type: MessageType.activity,
          fileData: payload,
        );

        // Auto-quit after 2 seconds so the banner dismisses
        Future.delayed(const Duration(seconds: 2), () {
          quitGame();
        });
      }
    }
  }

  void quitGame() {
    if (state != null) {
      final myId = ref.read(chatThreadsProvider.notifier).myId;
      final quitPayload = jsonEncode({'type': 'quit', 'gameId': state!.gameId});
      final msgMap = {'type': 'game_sync', 'data': quitPayload};
      
      final peerService = ref.read(peerServiceProvider);
      final lanMessenger = ref.read(lanMessengerProvider);

      for (final peerId in state!.participants) {
        if (peerId == myId) continue;
        peerService.sendCustomData(peerId, msgMap);
        lanMessenger.sendCustomData(peerId, msgMap);
      }
    }
    state = null;
  }
}
