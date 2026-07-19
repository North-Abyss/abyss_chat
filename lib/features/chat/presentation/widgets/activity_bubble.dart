import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/features/chat/domain/models/message.dart';
import 'package:abyss_chat/features/chat/domain/chat_controller.dart';

final Set<String> _playedActivityAnimations = {};

class ActivityBubble extends ConsumerStatefulWidget {
  final Message msg;
  final bool isMe;
  final String threadId;

  const ActivityBubble({super.key, required this.msg, required this.isMe, required this.threadId});

  @override
  ConsumerState<ActivityBubble> createState() => _ActivityBubbleState();
}

class _ActivityBubbleState extends ConsumerState<ActivityBubble> {
  late Map<String, dynamic> data;

  @override
  void initState() {
    super.initState();
    _parseData();
  }

  @override
  void didUpdateWidget(ActivityBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.msg.fileData != widget.msg.fileData) {
      _parseData();
    }
  }

  void _parseData() {
    try {
      if (widget.msg.fileData != null && widget.msg.fileData!.isNotEmpty) {
        data = jsonDecode(widget.msg.fileData!);
      } else {
        data = {'activity': 'unknown'};
      }
    } catch (e) {
      data = {'activity': 'error'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final activityType = data['activity'] as String?;
    
    switch (activityType) {
      case 'coin':
        return _buildCoinToss(context);
      case 'dice':
        return _buildDiceRoll(context);
      case 'tictactoe':
        return _buildTicTacToe(context);
      case 'poll':
        return _buildPoll(context);
      case 'event':
        return _buildEvent(context);
      default:
        return const Text('Unknown activity');
    }
  }

  Widget _buildEvent(BuildContext context) {
    return EventBubble(data: data, isMe: widget.isMe, msgId: widget.msg.id, threadId: widget.threadId);
  }

  Widget _buildCoinToss(BuildContext context) {
    return CoinTossBubble(data: data, isMe: widget.isMe, msgId: widget.msg.id);
  }

  Widget _buildDiceRoll(BuildContext context) {
    return DiceRollBubble(data: data, isMe: widget.isMe, msgId: widget.msg.id);
  }

  Widget _buildTicTacToe(BuildContext context) {
    final board = List<String>.from(data['board'] ?? List.filled(9, ''));
    final turn = data['turn'] as String? ?? 'X';
    final state = data['state'] as String? ?? 'playing'; // playing, won_X, won_O, draw
    final initiator = data['initiator'] as String?;
    
    final myId = ref.read(chatThreadsProvider.notifier).myId;
    final isMyTurn = (myId == initiator && turn == 'X') || (myId != initiator && turn == 'O');
    final cs = Theme.of(context).colorScheme;

    final threads = ref.read(chatThreadsProvider).value ?? [];
    final thread = threads.where((t) => t.id == widget.threadId).firstOrNull;
    
    String getPlayerName(String playerTurn) {
      if (playerTurn == 'X') {
        if (myId == initiator) return 'You';
        return thread?.isGroup == false ? thread!.peer.name : 'Initiator';
      } else {
        if (myId != initiator) return 'You';
        return thread?.isGroup == false ? thread!.peer.name : 'Opponent';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isMe ? cs.onPrimaryContainer.withValues(alpha: 0.1) : cs.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('❌ Tic-Tac-Toe ⭕', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (state == 'playing')
            Text(isMyTurn ? 'Your turn ($turn)' : 'Waiting for ${getPlayerName(turn)}...')
          else if (state == 'won_X')
            Text('${getPlayerName('X')} Won! 🎉', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))
          else if (state == 'won_O')
            Text('${getPlayerName('O')} Won! 🎉', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))
          else if (state == 'draw')
            const Text('Draw!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          const SizedBox(height: 12),
          SizedBox(
            width: 150,
            height: 150,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                final cell = board[index];
                return GestureDetector(
                  onTap: () {
                    if (state == 'playing' && isMyTurn && cell.isEmpty) {
                      _makeTicTacToeMove(index, board, turn, initiator ?? '');
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        cell,
                        style: TextStyle(
                          fontSize: 24,
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
        ],
      ),
    );
  }

  void _makeTicTacToeMove(int index, List<String> currentBoard, String currentTurn, String initiator) {
    final newBoard = List<String>.from(currentBoard);
    newBoard[index] = currentTurn;
    
    // Check win condition
    String newState = 'playing';
    final lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Cols
      [0, 4, 8], [2, 4, 6] // Diagonals
    ];
    
    bool won = false;
    for (var line in lines) {
      if (newBoard[line[0]] != '' &&
          newBoard[line[0]] == newBoard[line[1]] &&
          newBoard[line[0]] == newBoard[line[2]]) {
        won = true;
        newState = 'won_${newBoard[line[0]]}';
        break;
      }
    }
    
    if (!won && !newBoard.contains('')) {
      newState = 'draw';
    }
    
    final newTurn = currentTurn == 'X' ? 'O' : 'X';
    
    final payload = jsonEncode({
      'activity': 'tictactoe',
      'board': newBoard,
      'turn': newTurn,
      'state': newState,
      'initiator': initiator,
    });
    
    ref.read(chatThreadsProvider.notifier).sendMessage(
      widget.threadId,
      'Played Tic-Tac-Toe',
      type: MessageType.activity,
      fileData: payload,
    );
  }

  Widget _buildPoll(BuildContext context) {
    final question = data['question'] as String? ?? 'Poll';
    final options = List<String>.from(data['options'] ?? []);
    final votes = Map<String, List<String>>.from((data['votes'] as Map?)?.map(
          (k, v) => MapEntry(k as String, List<String>.from(v ?? [])),
        ) ?? {});
        
    final cs = Theme.of(context).colorScheme;
    final myId = ref.read(chatThreadsProvider.notifier).myId;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isMe ? cs.onPrimaryContainer.withValues(alpha: 0.1) : cs.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.poll, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            ],
          ),
          const SizedBox(height: 12),
          ...options.map((opt) {
            final voters = List<String>.from(votes[opt] ?? []);
            final hasVoted = voters.contains(myId);
            final totalVotes = votes.values.fold<int>(0, (sum, list) => sum + list.length);
            final percent = totalVotes == 0 ? 0.0 : voters.length / totalVotes;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                   _voteOnPoll(opt, options, votes);
                },
                child: Stack(
                  children: [
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: hasVoted ? cs.primary : cs.outlineVariant),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percent,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(opt, maxLines: 1, overflow: TextOverflow.ellipsis)),
                            Text('${voters.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _voteOnPoll(String selectedOpt, List<String> options, Map<String, List<String>> currentVotes) {
    final myId = ref.read(chatThreadsProvider.notifier).myId;
    final newVotes = Map<String, List<dynamic>>.from(currentVotes);
    
    for (var key in newVotes.keys) {
      newVotes[key] = List.from(newVotes[key]!)..remove(myId);
    }
    
    if (newVotes[selectedOpt] == null) newVotes[selectedOpt] = [];
    newVotes[selectedOpt]!.add(myId);
    
    final payload = jsonEncode({
      'activity': 'poll',
      'question': data['question'],
      'options': options,
      'votes': newVotes,
    });
    
    ref.read(chatThreadsProvider.notifier).syncActivityUpdate(
      widget.threadId,
      widget.msg.id,
      payload,
    );
  }
}

class CoinTossBubble extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isMe;
  final String msgId;
  const CoinTossBubble({super.key, required this.data, required this.isMe, required this.msgId});
  @override
  State<CoinTossBubble> createState() => _CoinTossBubbleState();
}

class _CoinTossBubbleState extends State<CoinTossBubble> with SingleTickerProviderStateMixin {
  late bool _shouldAnimate;
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _initCoin();
  }

  @override
  void didUpdateWidget(CoinTossBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.msgId != widget.msgId || oldWidget.data != widget.data) {
      _initCoin();
    }
  }
  
  void _initCoin() {
    _shouldAnimate = !_playedActivityAnimations.contains(widget.msgId);
    if (_shouldAnimate) {
      _playedActivityAnimations.add(widget.msgId);
      _controller.forward(from: 0.0);
    } else {
      _controller.value = 1.0;
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final result = widget.data['result'] as String?;
    final cs = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isMe ? cs.onPrimaryContainer.withValues(alpha: 0.1) : cs.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙 Coin Toss', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final val = Curves.easeOutBack.transform(_controller.value);
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(val * 3.14159 * 6), // Spin 3 times
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: result == 'Heads' ? Colors.amber.shade300 : Colors.blueGrey.shade300,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      result == 'Heads' ? 'H' : 'T',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            result ?? 'Unknown',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class DiceRollBubble extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isMe;
  final String msgId;
  const DiceRollBubble({super.key, required this.data, required this.isMe, required this.msgId});
  @override
  State<DiceRollBubble> createState() => _DiceRollBubbleState();
}

class _DiceRollBubbleState extends State<DiceRollBubble> {
  late bool _shouldAnimate;
  late List<int> _currentRolls;
  Timer? _timer;
  final Random _random = Random();
  late List<int> _finalRolls;

  @override
  void initState() {
    super.initState();
    _initDice();
  }

  @override
  void didUpdateWidget(DiceRollBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.msgId != widget.msgId || oldWidget.data != widget.data) {
      _initDice();
    }
  }

  void _initDice() {
    _timer?.cancel();
    _finalRolls = List<int>.from(widget.data['rolls'] ?? []);
    _shouldAnimate = !_playedActivityAnimations.contains(widget.msgId);
    
    if (_shouldAnimate && _finalRolls.isNotEmpty) {
      _playedActivityAnimations.add(widget.msgId);
      _currentRolls = List.generate(_finalRolls.length, (_) => _random.nextInt(6) + 1);
      int ticks = 0;
      _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        ticks++;
        if (ticks >= 15) {
          timer.cancel();
          if (mounted) setState(() => _currentRolls = _finalRolls);
        } else {
          if (mounted) {
            setState(() {
              _currentRolls = List.generate(_finalRolls.length, (_) => _random.nextInt(6) + 1);
            });
          }
        }
      });
    } else {
      _currentRolls = _finalRolls;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isMe ? cs.onPrimaryContainer.withValues(alpha: 0.1) : cs.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎲 Dice Roll', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _currentRolls.map((roll) {
              return Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: FittedBox(
                      child: Text(
                        roll.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Total: ${_currentRolls.fold(0, (sum, item) => sum + item)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class EventBubble extends ConsumerWidget {
  final Map<String, dynamic> data;
  final bool isMe;
  final String msgId;
  final String threadId;

  const EventBubble({super.key, required this.data, required this.isMe, required this.msgId, required this.threadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = data['title'] as String? ?? 'Event';
    final date = data['date'] as String? ?? 'TBD';
    final time = data['time'] as String? ?? 'TBD';
    final location = data['location'] as String? ?? 'TBD';
    
    final rsvps = Map<String, String>.from(data['rsvps'] ?? {}); // user_id -> 'going' | 'declined'
    
    final myId = ref.read(chatThreadsProvider.notifier).myId;
    final myStatus = rsvps[myId];

    final cs = Theme.of(context).colorScheme;

    int goingCount = rsvps.values.where((v) => v == 'going').length;
    int declinedCount = rsvps.values.where((v) => v == 'declined').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMe ? cs.onPrimaryContainer.withValues(alpha: 0.1) : cs.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16),
              const SizedBox(width: 8),
              Text(date),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16),
              const SizedBox(width: 8),
              Text(time),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(location)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Going ($goingCount)'),
              Text('Declined ($declinedCount)'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: myStatus == 'going' ? Colors.green : null,
                    foregroundColor: myStatus == 'going' ? Colors.white : null,
                  ),
                  onPressed: () => _updateRsvp(ref, 'going'),
                  child: const Text('✓ Going'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: myStatus == 'declined' ? Colors.red : null,
                    foregroundColor: myStatus == 'declined' ? Colors.white : null,
                  ),
                  onPressed: () => _updateRsvp(ref, 'declined'),
                  child: const Text('✕ Decline'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateRsvp(WidgetRef ref, String status) {
    final myId = ref.read(chatThreadsProvider.notifier).myId;
    if (myId == null) return;

    final newRsvps = Map<String, String>.from(data['rsvps'] ?? {});
    newRsvps[myId] = status;

    final payload = jsonEncode({
      'activity': 'event',
      'title': data['title'],
      'date': data['date'],
      'time': data['time'],
      'location': data['location'],
      'rsvps': newRsvps,
    });

    ref.read(chatThreadsProvider.notifier).syncActivityUpdate(
      threadId,
      msgId,
      payload,
    );
  }
}
