import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:abyss_chat/features/chat/presentation/widgets/gif_picker_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:abyss_chat/features/chat/domain/chat_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:abyss_chat/features/groups/presentation/screens/group_info_screen.dart';
import 'package:abyss_chat/features/chat/presentation/screens/chat_media_screen.dart';
import 'package:abyss_chat/features/contacts/presentation/screens/contact_profile_screen.dart';
import 'package:abyss_chat/core/widgets/user_avatar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:abyss_chat/features/calling/domain/call_controller.dart';
import 'package:abyss_chat/app/gif_provider.dart';
import 'package:flutter/services.dart';


// --- MAIN CHAT SCREEN WIDGET ---
import 'package:flutter/foundation.dart';
import 'package:abyss_chat/core/widgets/abyss_snackbar.dart';
import 'package:abyss_chat/features/chat/domain/models/message.dart';
import 'package:abyss_chat/features/chat/domain/models/chat_thread.dart';
import 'package:file_picker/file_picker.dart';
import 'package:abyss_chat/features/chat/presentation/widgets/message_text_content.dart';
import 'package:abyss_chat/core/utils/shared_prefs_helper.dart';
import 'package:abyss_chat/features/chat/presentation/widgets/activity_bubble.dart';
import 'dart:math';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:abyss_chat/features/chat/presentation/widgets/audio_message_bubble.dart';
import 'package:abyss_chat/features/chat/presentation/widgets/gif_player.dart';
class ChatScreen extends ConsumerStatefulWidget {
  final String threadId;
  final bool isDesktop;
  
  const ChatScreen({super.key, required this.threadId, this.isDesktop = false});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

enum VoiceRecordState {
  idle,
  recording,
  preview,
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  bool _showEmojiPicker = false;
  final Set<String> _selectedMessageIds = {};
  
  bool _hasText = false;
  VoiceRecordState _voiceState = VoiceRecordState.idle;
  Timer? _recordTimer;
  int _recordDuration = 0;
  String? _recordedFilePath;
  
  late final AudioRecorder _audioRecorder;
  final AudioPlayer _previewPlayer = AudioPlayer();
  bool _isPreviewPlaying = false;
  Duration _previewDuration = Duration.zero;
  Duration _previewPosition = Duration.zero;
  
  bool _isSearchMode = false;
  String _searchQuery = '';
  DateTime? _searchDate;
  bool _showScrollToBottom = false;

  bool get _isSelectionMode => _selectedMessageIds.isNotEmpty;
  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _previewPlayer.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPreviewPlaying = state.playing);
      if (state.processingState == ProcessingState.completed) {
        _previewPlayer.seek(Duration.zero);
        _previewPlayer.pause();
      }
    });
    _previewPlayer.durationStream.listen((d) {
      if (mounted) setState(() => _previewDuration = d ?? Duration.zero);
    });
    _previewPlayer.positionStream.listen((p) {
      if (mounted) setState(() => _previewPosition = p);
    });
    _textController.addListener(() {
      final textNotEmpty = _textController.text.trim().isNotEmpty;
      if (textNotEmpty != _hasText) {
        setState(() {
          _hasText = textNotEmpty;
        });
      }
      if (textNotEmpty) {
        ref.read(chatThreadsProvider.notifier).sendTypingIndicator(widget.threadId);
      }
    });
    
    _scrollController.addListener(() {
      if (_scrollController.offset > 200) {
        if (!_showScrollToBottom) setState(() => _showScrollToBottom = true);
      } else {
        if (_showScrollToBottom) setState(() => _showScrollToBottom = false);
      }
    });

    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });

    _focusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
        if (!HardwareKeyboard.instance.isShiftPressed) {
          _sendMessage();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _textController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      if (_showEmojiPicker) {
        _focusNode.unfocus();
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    ref.read(chatThreadsProvider.notifier).sendMessage(widget.threadId, text);
    _textController.clear();
    
    // Scroll to bottom after sending
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        String path = '';
        if (!kIsWeb) {
          final dir = await getTemporaryDirectory();
          path = '${dir.path}/voice_msg_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }
        await _audioRecorder.start(
          RecordConfig(encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc), 
          path: path
        );
        setState(() {
          _voiceState = VoiceRecordState.recording;
          _recordDuration = 0;
          _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            setState(() => _recordDuration++);
          });
        });
      } else {
        if (mounted) AbyssSnackBar.show(context, 'Microphone permission denied', type: SnackBarType.error);
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
    }
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    if (_voiceState != VoiceRecordState.recording) return;
    try {
      _recordTimer?.cancel();
      final path = await _audioRecorder.stop();
      
      setState(() {
        _voiceState = cancel ? VoiceRecordState.idle : VoiceRecordState.preview;
        _recordedFilePath = cancel ? null : path;
      });

      if (!cancel && path != null) {
        if (kIsWeb) {
          await _previewPlayer.setUrl(path);
        } else {
          await _previewPlayer.setFilePath(path);
        }
      }
    } catch (e) {
      debugPrint('Error stopping record: $e');
    }
  }

  Future<void> _sendVoiceMessage() async {
    if (_recordedFilePath == null) return;
    try {
      Uint8List bytes;
      if (kIsWeb) {
        final response = await http.get(Uri.parse(_recordedFilePath!));
        bytes = response.bodyBytes;
      } else {
        final file = File(_recordedFilePath!);
        bytes = await file.readAsBytes();
      }
      final base64Data = base64Encode(bytes);
      
      ref.read(chatThreadsProvider.notifier).sendMessage(
        widget.threadId, 
        '🎤 Voice Message', 
        type: MessageType.audio,
        localFilePath: _recordedFilePath,
        fileName: 'voice_message.m4a',
        fileData: base64Data,
      );
      
      setState(() {
        _voiceState = VoiceRecordState.idle;
        _recordedFilePath = null;
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      debugPrint('Error sending voice msg: $e');
    }
  }

  void _showEventPlanningDialog(BuildContext context) {
    final titleController = TextEditingController();
    final dateController = TextEditingController();
    final timeController = TextEditingController();
    final locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Plan an Event'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Event Title', icon: Icon(Icons.event)),
              ),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Date (e.g., Oct 25)', icon: Icon(Icons.calendar_today)),
              ),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: 'Time (e.g., 7:00 PM)', icon: Icon(Icons.access_time)),
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location', icon: Icon(Icons.location_on)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              
              final payload = jsonEncode({
                'activity': 'event',
                'title': titleController.text.trim(),
                'date': dateController.text.trim().isEmpty ? 'TBD' : dateController.text.trim(),
                'time': timeController.text.trim().isEmpty ? 'TBD' : timeController.text.trim(),
                'location': locationController.text.trim().isEmpty ? 'TBD' : locationController.text.trim(),
                'rsvps': {ref.read(chatThreadsProvider.notifier).myId: 'going'},
              });
              
              ref.read(chatThreadsProvider.notifier).sendMessage(
                widget.threadId, 
                '📅 Planned: ${titleController.text.trim()}', 
                type: MessageType.activity, 
                fileData: payload
              );
              Navigator.pop(context);
            },
            child: const Text('Create Event'),
          ),
        ],
      ),
    );
  }

  void _showAttachmentMenu(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => Align(
        alignment: Alignment.bottomRight,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 320, // Compact dock width
            margin: const EdgeInsets.only(right: 16, bottom: 90),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 8)),
              ],
            ),
            child: Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: [
                _buildAttachIcon(context, Icons.insert_drive_file, Colors.indigo, 'Document', () async {
                  Navigator.pop(context);
                  final result = await FilePicker.pickFiles(withData: true);
                  if (result != null && result.files.isNotEmpty) {
                    final file = result.files.single;
                    final name = file.name;
                    final path = file.path;
                    Uint8List? bytes = file.bytes;
                    if (bytes == null && path != null && !kIsWeb) {
                      bytes = await File(path).readAsBytes();
                    }
                    if (bytes == null) return;
                    if (bytes.length > 10 * 1024 * 1024) {
                      if (context.mounted) AbyssSnackBar.show(context, 'File is larger than 10MB', type: SnackBarType.error);
                      return;
                    }
                    final base64Data = base64Encode(bytes);
                    final isImage = name.toLowerCase().endsWith('.png') || name.toLowerCase().endsWith('.jpg') || name.toLowerCase().endsWith('.jpeg') || name.toLowerCase().endsWith('.gif');
                    ref.read(chatThreadsProvider.notifier).sendMessage(
                      widget.threadId, 
                      isImage ? 'Sent an image' : 'Sent a file', 
                      type: isImage ? MessageType.image : MessageType.file,
                      localFilePath: path,
                      fileName: name,
                      fileData: base64Data,
                    );
                  }
                }),
                _buildAttachIcon(context, Icons.camera_alt, Colors.pink, 'Camera', () async {
                  Navigator.pop(context);
                  if (kIsWeb) {
                    AbyssSnackBar.show(context, 'Camera not supported on Web', type: SnackBarType.info);
                    return;
                  }
                  try {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      final base64Data = base64Encode(bytes);
                      ref.read(chatThreadsProvider.notifier).sendMessage(
                        widget.threadId, 
                        'Sent an image', 
                        type: MessageType.image,
                        localFilePath: image.path,
                        fileName: 'camera_image.jpg',
                        fileData: base64Data,
                      );
                    }
                  } catch (e) {
                    debugPrint('Error picking image: $e');
                  }
                }),
                _buildAttachIcon(context, Icons.gif_box, Colors.teal, 'GIF', () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.all(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: GifPickerSheet(
                          onGifSelected: (url) {
                            ref.read(chatThreadsProvider.notifier).sendMessage(
                              widget.threadId,
                              'GIF',
                              type: MessageType.image,
                              fileData: url,
                            );
                          },
                        ),
                      ),
                    ),
                  );
                }),
                _buildAttachIcon(context, Icons.event, Colors.blue, 'Event', () {
                  Navigator.pop(context);
                  _showEventPlanningDialog(context);
                }),
                _buildAttachIcon(context, Icons.monetization_on, Colors.amber, 'Coin Toss', () {
                  Navigator.pop(context);
                  final result = Random().nextBool() ? 'Heads' : 'Tails';
                  final payload = jsonEncode({'activity': 'coin', 'result': result});
                  ref.read(chatThreadsProvider.notifier).sendMessage(widget.threadId, '🪙 Tossed a coin', type: MessageType.activity, fileData: payload);
                }),
                _buildAttachIcon(context, Icons.casino, Colors.purple, 'Roll Dice', () {
                  Navigator.pop(context);
                  showDialog(context: context, builder: (dialogContext) => AlertDialog(
                    title: const Text('Roll how many dice?'),
                    content: Wrap(
                      spacing: 8,
                      children: List.generate(4, (i) => ChoiceChip(
                        label: Text('${i+1}'),
                        selected: false,
                        onSelected: (_) {
                          Navigator.pop(dialogContext);
                          final rolls = List.generate(i+1, (_) => Random().nextInt(6) + 1);
                          final payload = jsonEncode({'activity': 'dice', 'rolls': rolls});
                          ref.read(chatThreadsProvider.notifier).sendMessage(widget.threadId, '🎲 Rolled ${i+1} dice', type: MessageType.activity, fileData: payload);
                        },
                      )),
                    ),
                  ));
                }),
                _buildAttachIcon(context, Icons.grid_3x3, Colors.red, 'Tic-Tac-Toe', () {
                  Navigator.pop(context);
                  final payload = jsonEncode({'activity': 'tictactoe', 'board': List.filled(9, ''), 'turn': 'X', 'state': 'playing', 'initiator': ref.read(chatThreadsProvider.notifier).myId});
                  ref.read(chatThreadsProvider.notifier).sendMessage(widget.threadId, '❌ Started Tic-Tac-Toe', type: MessageType.activity, fileData: payload);
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttachIcon(BuildContext context, IconData icon, Color color, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final thread = ref.watch(singleThreadProvider(widget.threadId));
    final cs = Theme.of(context).colorScheme;

    if (thread == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Thread not found')),
      );
    }
    
    // Auto-hide emoji picker if keyboard opens
    // Removed so that emoji picker can pop up above the keyboard
    
    // Mark as read when viewed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(chatThreadsProvider.notifier).markAllRead(widget.threadId);
      }
    });

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedMessageIds.clear()),
              ),
              title: Text('${_selectedMessageIds.length} selected'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    final selectedMsgs = thread.messages
                        .where((m) => _selectedMessageIds.contains(m.id))
                        .toList()
                      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
                    
                    final text = selectedMsgs.map((m) => '[${m.timestamp.hour}:${m.timestamp.minute.toString().padLeft(2, '0')}] ${m.senderName ?? 'Someone'}: ${m.text}').join('\n');
                    Clipboard.setData(ClipboardData(text: text));
                    AbyssSnackBar.show(context, 'Copied to clipboard', type: SnackBarType.success);
                    setState(() => _selectedMessageIds.clear());
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete messages?'),
                        content: const Text('These messages will be removed from your view.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          FilledButton.tonal(
                            onPressed: () {
                              ref.read(chatThreadsProvider.notifier).deleteMessages(widget.threadId, _selectedMessageIds.toList());
                              setState(() => _selectedMessageIds.clear());
                              Navigator.pop(context);
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.reply), // Forward icon
                  onPressed: () {
                    final selectedMsgs = thread.messages
                        .where((m) => _selectedMessageIds.contains(m.id))
                        .toList();
                    _showForwardBottomSheet(selectedMsgs);
                  },
                ),
              ],
            )
          : _isSearchMode
              ? AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _isSearchMode = false;
                        _searchController.clear();
                        _searchDate = null;
                      });
                    },
                  ),
                  title: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: 'Search messages...',
                      border: InputBorder.none,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(_searchDate == null ? Icons.calendar_today : Icons.event_available),
                      color: _searchDate == null ? null : cs.primary,
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _searchDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _searchDate = date);
                        }
                      },
                    ),
                  ],
                )
              : AppBar(
                  automaticallyImplyLeading: !widget.isDesktop,
              title: GestureDetector(
                onTap: () {
                  if (thread.isGroup) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => GroupInfoScreen(thread: thread)));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ContactProfileScreen(peer: thread.peer)));
                  }
                },
                child: Row(
                  children: [
                    UserAvatar(user: thread.peer, radius: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            thread.isGroup ? (thread.groupName ?? 'Group') : thread.peer.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          if (thread.isGroup)
                            Row(
                              children: [
                                const Icon(Icons.lock, size: 10, color: Colors.green),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'E2EE • ${thread.members.length} members',
                                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                const Icon(Icons.lock, size: 10, color: Colors.green),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    thread.peer.isOnline ? 'E2EE • Online' : 'E2EE • Offline',
                                    style: TextStyle(fontSize: 12, color: thread.peer.isOnline ? cs.primary : cs.onSurfaceVariant),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => setState(() => _isSearchMode = true),
                ),
                IconButton(
                  icon: const Icon(Icons.videocam),
                  onPressed: () => _handleCall(thread, true),
                ),
                IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: () => _handleCall(thread, false),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'info') {
                      if (thread.isGroup) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => GroupInfoScreen(thread: thread)));
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ContactProfileScreen(peer: thread.peer)));
                      }
                    } else if (value == 'media') {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatMediaScreen(thread: thread)));
                    } else if (value == 'clear') {
                      ref.read(chatThreadsProvider.notifier).clearMessages(widget.threadId);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'info',
                      child: Row(
                        children: [
                          Icon(thread.isGroup ? Icons.info : Icons.person, size: 20),
                          const SizedBox(width: 12),
                          Text(thread.isGroup ? 'Group Info' : 'View Contact Info'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'media',
                      child: Row(
                        children: [
                          Icon(Icons.perm_media, size: 20),
                          SizedBox(width: 12),
                          Text('Media, Links, and Docs'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear',
                      child: Row(
                        children: [
                          Icon(Icons.clear_all, size: 20),
                          SizedBox(width: 12),
                          Text('Clear Chat'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
      body: Stack(
        children: [
          Column(
            children: [
              // Messages
              Expanded(
                child: Builder(
                  builder: (context) {
                    var displayMsgs = thread.messages;
                if (_searchQuery.isNotEmpty) {
                  displayMsgs = displayMsgs.where((m) => m.text.toLowerCase().contains(_searchQuery)).toList();
                }
                if (_searchDate != null) {
                  displayMsgs = displayMsgs.where((m) => 
                    m.timestamp.year == _searchDate!.year &&
                    m.timestamp.month == _searchDate!.month &&
                    m.timestamp.day == _searchDate!.day
                  ).toList();
                }
                
                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: displayMsgs.length,
                  itemBuilder: (context, index) {
                    final msgIndex = displayMsgs.length - 1 - index;
                    final msg = displayMsgs[msgIndex];
                final isMe = msg.senderId == ref.read(chatThreadsProvider.notifier).myId;

                // System messages
                if (msg.type.name == 'system') {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(msg.text, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    ),
                  );
                }

                IconData statusIcon = Icons.schedule;
                Color statusColor = cs.onSurfaceVariant;
                if (isMe) {
                  switch (msg.status) {
                    case MessageStatus.pending: 
                      statusIcon = Icons.wifi_protected_setup; 
                      statusColor = Colors.orange;
                      break;
                    case MessageStatus.sending: statusIcon = Icons.schedule; break;
                    case MessageStatus.sent: statusIcon = Icons.check; break;
                    case MessageStatus.delivered: statusIcon = Icons.done_all; break;
                    case MessageStatus.read: 
                      statusIcon = Icons.done_all; 
                      statusColor = Colors.blue; 
                      break;
                    case MessageStatus.failed: 
                      statusIcon = Icons.error_outline; 
                      statusColor = Colors.red;
                      break;
                  }
                }

                final isSelected = _selectedMessageIds.contains(msg.id);

                return GestureDetector(
                  onTap: () {
                    if (_isSelectionMode) {
                      setState(() {
                        if (isSelected) {
                          _selectedMessageIds.remove(msg.id);
                        } else {
                          _selectedMessageIds.add(msg.id);
                        }
                      });
                    }
                  },
                  onSecondaryTap: () {
                    setState(() {
                      _selectedMessageIds.add(msg.id);
                    });
                  },
                  onLongPress: () {
                    setState(() {
                      _selectedMessageIds.add(msg.id);
                    });
                  },
                  child: Container(
                    color: isSelected ? cs.primary.withValues(alpha: 0.15) : Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      child: Stack(
                        children: [
                          Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? cs.primaryContainer : cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              margin: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sender name for groups
                          if (thread.isGroup && !isMe)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                msg.senderName ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                          // Message text + timestamp row
                          Wrap(
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.end,
                            spacing: 8,
                            children: [
                              if (msg.type == MessageType.image)
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
                                      backgroundColor: Colors.black,
                                      appBar: AppBar(
                                        backgroundColor: Colors.black,
                                        iconTheme: const IconThemeData(color: Colors.white),
                                      ),
                                      body: InteractiveViewer(
                                        minScale: 1.0,
                                        maxScale: 5.0,
                                        child: SizedBox.expand(
                                          child: msg.fileData != null && msg.fileData!.startsWith('http')
                                              ? (msg.fileData!.toLowerCase().endsWith('.gif') 
                                                  ? GifPlayer(url: msg.fileData!, fit: BoxFit.contain)
                                                  : CachedNetworkImage(imageUrl: msg.fileData!, fit: BoxFit.contain))
                                              : msg.fileData != null && msg.fileData!.isNotEmpty
                                                  ? Image.memory(base64Decode(msg.fileData!), fit: BoxFit.contain)
                                                  : (msg.localFilePath != null && !kIsWeb
                                                      ? Image.file(File(msg.localFilePath!), fit: BoxFit.contain)
                                                      : const Center(child: Icon(Icons.broken_image, color: Colors.white, size: 50))),
                                        ),
                                      ),
                                    )));
                                  },
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxHeight: 200,
                                      maxWidth: MediaQuery.of(context).size.width * 0.6,
                                    ),
                                    margin: const EdgeInsets.only(bottom: 4),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Stack(
                                        children: [
                                          msg.fileData != null && msg.fileData!.startsWith('http')
                                              ? (msg.fileData!.toLowerCase().endsWith('.gif')
                                                  ? GifPlayer(url: msg.fileData!, fit: BoxFit.cover)
                                                  : CachedNetworkImage(imageUrl: msg.fileData!, fit: BoxFit.cover))
                                              : msg.fileData != null && msg.fileData!.isNotEmpty
                                                  ? Image.memory(base64Decode(msg.fileData!), fit: BoxFit.cover)
                                                  : (msg.localFilePath != null && !kIsWeb
                                                      ? Image.file(File(msg.localFilePath!), fit: BoxFit.cover) 
                                                      : const Icon(Icons.broken_image)),
                                          if (msg.fileData != null && msg.fileData!.startsWith('http') && msg.fileData!.toLowerCase().endsWith('.gif'))
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: Consumer(
                                                builder: (context, ref, child) {
                                                  final isFav = ref.watch(gifProvider).favoriteGifs.contains(msg.fileData!);
                                                  return GestureDetector(
                                                    onTap: () {
                                                      ref.read(gifProvider.notifier).toggleFavorite(msg.fileData!);
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets.all(4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black.withValues(alpha: 0.5),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        isFav ? Icons.favorite : Icons.favorite_border,
                                                        color: isFav ? Colors.red : Colors.white,
                                                        size: 16,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              else if (msg.type == MessageType.file && msg.fileName != null)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isMe ? cs.onPrimaryContainer.withValues(alpha: 0.1) : cs.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.insert_drive_file, color: isMe ? cs.onPrimaryContainer : cs.onSurface),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          msg.fileName!,
                                          style: TextStyle(
                                            color: isMe ? cs.onPrimaryContainer : cs.onSurface,
                                            decoration: TextDecoration.underline,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                else if (msg.type == MessageType.activity)
                                  ActivityBubble(msg: msg, isMe: isMe, threadId: widget.threadId)
                                else if (msg.type == MessageType.audio)
                                  AudioMessageBubble(msg: msg, isMe: isMe)
                                else
                                    MessageTextContent(msg: msg, isMe: isMe),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isMe
                                          ? cs.onPrimaryContainer.withValues(alpha: 0.6)
                                          : cs.onSurfaceVariant,
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 3),
                                    Icon(
                                      statusIcon,
                                      size: 14,
                                      color: statusColor,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isSelected && isMe)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Icon(Icons.check_circle, color: cs.primary),
                      ),
                    ),
                  if (isSelected && !isMe)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Icon(Icons.check_circle, color: cs.primary),
                      ),
                    ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      // Input Bar
          if (!_isSelectionMode)
            Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2))),
                  ),
                  child: SafeArea(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (_voiceState == VoiceRecordState.idle)
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(_showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined),
                                    color: cs.onSurfaceVariant,
                                    onPressed: _toggleEmojiPicker,
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _textController,
                                      focusNode: _focusNode,
                                      keyboardType: TextInputType.multiline,
                                      textInputAction: TextInputAction.newline,
                                      contentInsertionConfiguration: ContentInsertionConfiguration(
                                        onContentInserted: (KeyboardInsertedContent content) {
                                          if (content.data != null) {
                                            final isImage = content.mimeType.startsWith('image/');
                                            if (isImage) {
                                              final base64Data = base64Encode(content.data!);
                                              ref.read(chatThreadsProvider.notifier).sendMessage(
                                                widget.threadId, 
                                                'Sent an image', 
                                                type: MessageType.image,
                                                fileName: content.uri.isEmpty ? 'pasted_image' : content.uri,
                                                fileData: base64Data,
                                              );
                                            }
                                          }
                                        },
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: 'Message',
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                                      ),
                                      minLines: 1,
                                      maxLines: 5,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle),
                                    color: cs.primary,
                                    iconSize: 28,
                                    onPressed: () => _showAttachmentMenu(context),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (_voiceState == VoiceRecordState.recording)
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: cs.errorContainer.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  const Icon(Icons.mic, color: Colors.red).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 500.ms),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${(_recordDuration ~/ 60).toString().padLeft(2, '0')}:${(_recordDuration % 60).toString().padLeft(2, '0')}',
                                    style: TextStyle(color: cs.onErrorContainer, fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () => _stopRecording(cancel: true),
                                    child: Text('Cancel', style: TextStyle(color: cs.error)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (_voiceState == VoiceRecordState.preview)
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _previewPlayer.stop();
                                      setState(() {
                                        _voiceState = VoiceRecordState.idle;
                                        _recordedFilePath = null;
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(_isPreviewPlaying ? Icons.pause : Icons.play_arrow, color: cs.primary),
                                    onPressed: () {
                                      if (_isPreviewPlaying) {
                                        _previewPlayer.pause();
                                      } else {
                                        _previewPlayer.play();
                                      }
                                    },
                                  ),
                                  Expanded(
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0, end: _previewPosition.inMilliseconds.toDouble()),
                                      duration: const Duration(milliseconds: 200),
                                      builder: (context, val, _) {
                                        final maxVal = _previewDuration.inMilliseconds.toDouble() > 0 ? _previewDuration.inMilliseconds.toDouble() : 1.0;
                                        return Slider(
                                          value: val.clamp(0.0, maxVal),
                                          max: maxVal,
                                          onChanged: (newVal) {
                                            _previewPlayer.seek(Duration(milliseconds: newVal.toInt()));
                                          },
                                          activeColor: cs.primary,
                                          inactiveColor: cs.primary.withValues(alpha: 0.3),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: _hasText || _voiceState == VoiceRecordState.preview ? cs.primary : (_voiceState == VoiceRecordState.recording ? Colors.red : cs.surfaceContainerHighest),
                          radius: 24,
                          child: GestureDetector(
                            onTap: () {
                              if (_voiceState == VoiceRecordState.idle) {
                                if (_hasText) {
                                  _sendMessage();
                                } else {
                                  _startRecording();
                                }
                              } else if (_voiceState == VoiceRecordState.recording) {
                                _stopRecording();
                              } else if (_voiceState == VoiceRecordState.preview) {
                                _previewPlayer.stop();
                                _sendVoiceMessage();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              color: Colors.transparent,
                              child: Icon(
                                _voiceState == VoiceRecordState.idle
                                    ? (_hasText ? Icons.send : Icons.mic_none)
                                    : (_voiceState == VoiceRecordState.recording ? Icons.stop : Icons.send),
                                color: _hasText || _voiceState != VoiceRecordState.idle ? cs.onPrimary : cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ).animate(target: _hasText || _voiceState != VoiceRecordState.idle ? 1 : 0)
                         .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), curve: Curves.easeOutBack, duration: 200.ms),
                      ],
                    ),
                  ),
            ),
      ],
    ),
          
          // Scroll to bottom button
          if (_showScrollToBottom)
            Positioned(
              right: 16,
              bottom: _isSelectionMode ? 16 : 80, // Above the input bar
              child: FloatingActionButton.small(
                onPressed: () {
                  _scrollController.animateTo(
                    0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
                child: const Icon(Icons.arrow_downward),
              ),
            ),
          
          // Floating Emoji Picker
          if (_showEmojiPicker)
            Positioned(
              bottom: 80 + MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  height: 300,
                  color: cs.surface,
                  child: EmojiPicker(
                    textEditingController: _textController,
                    config: Config(
                      height: 300,
                      emojiTextStyle: const TextStyle(
                        fontFamilyFallback: ['Apple Color Emoji', 'Segoe UI Emoji', 'Noto Color Emoji'],
                      ),
                      emojiViewConfig: EmojiViewConfig(
                        backgroundColor: cs.surface,
                      ),
                      bottomActionBarConfig: BottomActionBarConfig(
                        showBackspaceButton: true,
                        showSearchViewButton: true,
                        backgroundColor: cs.surfaceContainerHighest,
                        buttonColor: cs.surfaceContainerHighest,
                        buttonIconColor: cs.onSurfaceVariant,
                      ),
                      categoryViewConfig: CategoryViewConfig(
                        backgroundColor: cs.surface,
                        indicatorColor: cs.primary,
                        iconColorSelected: cs.primary,
                        iconColor: cs.onSurfaceVariant,
                      ),
                      searchViewConfig: SearchViewConfig(
                        backgroundColor: cs.surfaceContainerHighest,
                        buttonIconColor: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showForwardBottomSheet(List<Message> selectedMsgs) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final threads = ref.watch(chatThreadsProvider).value ?? [];
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Forward to...', style: Theme.of(context).textTheme.titleLarge),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: threads.length,
                      itemBuilder: (context, index) {
                        final t = threads[index];
                        if (t.id == widget.threadId) return const SizedBox.shrink(); // Don't show current thread
                        return ListTile(
                          leading: UserAvatar(user: t.peer, radius: 20),
                          title: Text(t.isGroup ? (t.groupName ?? 'Group') : t.peer.name),
                          onTap: () {
                            ref.read(chatThreadsProvider.notifier).forwardMessages(t.id, selectedMsgs);
                            AbyssSnackBar.show(context, 'Messages forwarded', type: SnackBarType.success);
                            setState(() => _selectedMessageIds.clear());
                            Navigator.pop(context);
                          },
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

  Future<void> _handleCall(ChatThread thread, bool isVideo) async {
    final myId = ref.read(chatThreadsProvider.notifier).myId;
    final callPeers = thread.isGroup 
        ? thread.members.where((m) => m.id != myId).toList()
        : [thread.peer];

    if (thread.isGroup) {
      if (callPeers.length > 10) {
        AbyssSnackBar.show(context, 'Group calls are limited to 10 participants for optimal performance.', type: SnackBarType.error);
        return;
      }
      
      final prefs = await SharedPrefsHelper.instance;
      final hideWarning = prefs.getBool('hide_group_call_warning') ?? false;
      
      if (!hideWarning && mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) {
            bool dontShowAgain = false;
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: const Text('Group Call Limits'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Abyss uses a decentralized network. For optimal call quality, we recommend keeping group calls under 10 people.'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: dontShowAgain,
                            onChanged: (val) => setState(() => dontShowAgain = val ?? false),
                          ),
                          const Expanded(child: Text('Don\'t show this warning again')),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (dontShowAgain) {
                          prefs.setBool('hide_group_call_warning', true);
                        }
                        Navigator.pop(context, true);
                      },
                      child: const Text('Call'),
                    ),
                  ],
                );
              },
            );
          },
        );
        
        if (proceed != true) return;
      }
    }

    ref.read(callProvider.notifier).startCall(callPeers, isVideo, isGroup: thread.isGroup);
  }
}
