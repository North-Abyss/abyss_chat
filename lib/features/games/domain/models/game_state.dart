import 'dart:convert';

enum GameType { ticTacToe, guessing }

class GameState {
  final String gameId;
  final GameType type;
  final String hostId;
  final List<String> participants;
  final bool isFinished;
  final String? winnerId;
  final String? threadId;

  // Tic-Tac-Toe Specific
  final List<String> board; // 9 elements, empty string for null
  final String currentTurnId;

  // Guessing Game Specific
  final String? category;
  // Answer is only stored on the host's device in memory for security,
  // but if we are just making a simple game, we can broadcast a hashed answer.
  // Actually, for a simple game, the host just listens to messages and resolves the winner.
  final String? answer;

  GameState({
    required this.gameId,
    required this.type,
    required this.hostId,
    required this.participants,
    this.isFinished = false,
    this.winnerId,
    this.threadId,
    this.board = const ['', '', '', '', '', '', '', '', ''],
    this.currentTurnId = '',
    this.category,
    this.answer,
  });

  Map<String, dynamic> toMap() {
    return {
      'gameId': gameId,
      'type': type.name,
      'hostId': hostId,
      'participants': participants,
      'isFinished': isFinished,
      'winnerId': winnerId,
      'threadId': threadId,
      'board': board,
      'currentTurnId': currentTurnId,
      'category': category,
      'answer': answer,
    };
  }

  factory GameState.fromMap(Map<String, dynamic> map) {
    return GameState(
      gameId: map['gameId'] ?? '',
      type: GameType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => GameType.ticTacToe,
      ),
      hostId: map['hostId'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      isFinished: map['isFinished'] ?? false,
      winnerId: map['winnerId'],
      threadId: map['threadId'],
      board: List<String>.from(
        map['board'] ?? ['', '', '', '', '', '', '', '', ''],
      ),
      currentTurnId: map['currentTurnId'] ?? '',
      category: map['category'],
      answer: map['answer'],
    );
  }

  String toJson() => json.encode(toMap());

  factory GameState.fromJson(String source) =>
      GameState.fromMap(json.decode(source));

  GameState copyWith({
    String? gameId,
    GameType? type,
    String? hostId,
    List<String>? participants,
    bool? isFinished,
    String? winnerId,
    String? threadId,
    List<String>? board,
    String? currentTurnId,
    String? category,
    String? answer,
  }) {
    return GameState(
      gameId: gameId ?? this.gameId,
      type: type ?? this.type,
      hostId: hostId ?? this.hostId,
      participants: participants ?? this.participants,
      isFinished: isFinished ?? this.isFinished,
      winnerId: winnerId ?? this.winnerId,
      threadId: threadId ?? this.threadId,
      board: board ?? this.board,
      currentTurnId: currentTurnId ?? this.currentTurnId,
      category: category ?? this.category,
      answer: answer ?? this.answer,
    );
  }
}
