import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/providers/chat_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:abyss_chat/screens/call_screen.dart';
import 'package:abyss_chat/screens/group_info_screen.dart';
import 'package:abyss_chat/screens/contact_profile_screen.dart';
import 'package:abyss_chat/widgets/user_avatar.dart';
import 'package:flutter/services.dart';
import 'package:abyss_chat/widgets/abyss_snackbar.dart';
import 'package:abyss_chat/models/message.dart';
import 'package:file_picker/file_picker.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String threadId;
  final bool isDesktop;
  
  const ChatScreen({super.key, required this.threadId, this.isDesktop = false});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showEmojiPicker() {
    final cs = Theme.of(context).colorScheme;
    
    // Calculate position slightly above the input bar
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    showDialog(
      context: context,
      barrierColor: Colors.transparent, // Don't dim the background
      builder: (context) => Stack(
        children: [
          Positioned(
            bottom: 70 + bottomInset, // Float above input bar
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: Container(
                height: 350,
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: EmojiPicker(
                  textEditingController: _textController,
                  config: Config(
                    height: 350,
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

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    ref.read(chatThreadsProvider.notifier).sendMessage(widget.threadId, text);
    _textController.clear();
    
    // Scroll to bottom after sending
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
    
    // Mark as read when viewed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(chatThreadsProvider.notifier).markAllRead(widget.threadId);
      }
    });

    return Scaffold(
      appBar: AppBar(
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
                      Text(
                        '${thread.members.length} members',
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                      )
                    else if (thread.peer.isOnline)
                      Text(
                        'Online',
                        style: TextStyle(fontSize: 12, color: cs.primary),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => CallScreen(peer: thread.peer, isVideo: true),
              ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => CallScreen(peer: thread.peer, isVideo: false),
              ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (thread.isGroup)
                        ListTile(
                          leading: const Icon(Icons.info),
                          title: const Text('Group Info'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => GroupInfoScreen(thread: thread)));
                          },
                        )
                      else
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('View Contact Info'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ContactProfileScreen(peer: thread.peer)));
                          },
                        ),
                      ListTile(
                        leading: const Icon(Icons.clear_all),
                        title: const Text('Clear Chat'),
                        onTap: () {
                          ref.read(chatThreadsProvider.notifier).clearMessages(widget.threadId);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: thread.messages.length,
              itemBuilder: (context, index) {
                final msg = thread.messages[index];
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

                return GestureDetector(
                  onLongPress: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.copy),
                              title: const Text('Copy Message'),
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: msg.text));
                                AbyssSnackBar.show(context, 'Copied to clipboard', type: SnackBarType.success);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Align(
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
                              if (msg.type == MessageType.file && msg.fileName != null)
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
                              else
                                Text(
                                  msg.text,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isMe ? cs.onPrimaryContainer : cs.onSurface,
                                  ),
                                ),
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
                );
              },
            ),
          ),
          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.emoji_emotions_outlined),
                            color: cs.onSurfaceVariant,
                            onPressed: _showEmojiPicker,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              focusNode: _focusNode,
                              decoration: const InputDecoration(
                                hintText: 'Message',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                              ),
                              minLines: 1,
                              maxLines: 5,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.attach_file),
                            color: cs.onSurfaceVariant,
                            onPressed: () async {
                              final result = await FilePicker.pickFiles();
                              if (result != null && result.files.single.path != null) {
                                final path = result.files.single.path!;
                                final name = result.files.single.name;
                                ref.read(chatThreadsProvider.notifier).sendMessage(
                                  widget.threadId, 
                                  'Sent a file', 
                                  type: MessageType.file,
                                  localFilePath: path,
                                  fileName: name,
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.camera_alt_outlined),
                            color: cs.onSurfaceVariant,
                            onPressed: () {
                              AbyssSnackBar.show(context, 'Camera coming soon', type: SnackBarType.info);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: _hasText ? cs.primary : cs.surfaceContainerHighest,
                    radius: 24,
                    child: IconButton(
                      icon: Icon(
                        _hasText ? Icons.send : Icons.mic,
                        color: _hasText ? cs.onPrimary : cs.onSurfaceVariant,
                      ),
                      onPressed: () {
                        if (_hasText) {
                          _sendMessage();
                        } else {
                          AbyssSnackBar.show(context, 'Voice messages coming soon', type: SnackBarType.info);
                        }
                      },
                    ),
                  ).animate(target: _hasText ? 1 : 0)
                   .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), curve: Curves.easeOutBack, duration: 200.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
