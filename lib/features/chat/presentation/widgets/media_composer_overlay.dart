
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/features/chat/domain/chat_controller.dart';
import 'package:abyss_chat/features/chat/presentation/widgets/media_preview_dialog.dart';
import 'package:abyss_chat/core/widgets/user_avatar.dart';

class MediaComposerOverlay extends ConsumerStatefulWidget {
  final List<PickedMedia> initialMedia;
  final String currentThreadId;
  final VoidCallback onClose;
  final VoidCallback onAddMore;
  final Function(int) onRemove;
  final Function(List<PickedMedia> selectedMedia, String caption, bool compressToZip, List<String> targetThreadIds) onSend;

  const MediaComposerOverlay({
    super.key,
    required this.initialMedia,
    required this.currentThreadId,
    required this.onClose,
    required this.onAddMore,
    required this.onRemove,
    required this.onSend,
  });

  @override
  ConsumerState<MediaComposerOverlay> createState() => _MediaComposerOverlayState();
}

class _MediaComposerOverlayState extends ConsumerState<MediaComposerOverlay> {
  late PageController _pageController;
  int _currentIndex = 0;
  final TextEditingController _captionController = TextEditingController();
  bool _compressToZip = false;
  late List<String> _selectedThreadIds;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _selectedThreadIds = [widget.currentThreadId];
  }

  @override
  void didUpdateWidget(covariant MediaComposerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMedia.length != oldWidget.initialMedia.length) {
      if (_currentIndex >= widget.initialMedia.length) {
        _currentIndex = widget.initialMedia.isEmpty ? 0 : widget.initialMedia.length - 1;
      }
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Widget _buildPreviewItem(PickedMedia media) {
    if (media.isImage) {
      return InteractiveViewer(
        child: Image.memory(
          media.bytes,
          fit: BoxFit.contain,
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.insert_drive_file, size: 120, color: Colors.indigo),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                media.name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${(media.bytes.length / 1024 / 1024).toStringAsFixed(2)} MB',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaList = widget.initialMedia;
    final allThreads = ref.watch(chatThreadsProvider).value ?? [];
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface.withValues(alpha: 0.95),
      child: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: cs.onSurface),
                    onPressed: widget.onClose,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ..._selectedThreadIds.map((tid) {
                            final thread = allThreads.firstWhere((t) => t.id == tid, orElse: () => allThreads.first);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Chip(
                                avatar: UserAvatar(user: thread.peer, radius: 12),
                                label: Text(thread.isGroup ? (thread.groupName ?? 'Group') : thread.peer.name),
                                backgroundColor: cs.primaryContainer,
                                labelStyle: TextStyle(color: cs.onPrimaryContainer),
                                deleteIconColor: cs.onPrimaryContainer,
                                onDeleted: _selectedThreadIds.length > 1 ? () {
                                  setState(() => _selectedThreadIds.remove(tid));
                                } : null,
                              ),
                            );
                          }),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.add_circle, color: cs.primary, size: 28),
                            tooltip: 'Send to more contacts',
                            color: cs.surfaceContainerHigh,
                            onSelected: (tid) {
                              if (!_selectedThreadIds.contains(tid)) {
                                setState(() => _selectedThreadIds.add(tid));
                              }
                            },
                            itemBuilder: (context) {
                              return allThreads
                                  .where((t) => !_selectedThreadIds.contains(t.id))
                                  .map((t) => PopupMenuItem<String>(
                                        value: t.id,
                                        child: Row(
                                          children: [
                                            UserAvatar(user: t.peer, radius: 12),
                                            const SizedBox(width: 8),
                                            Text(t.isGroup ? (t.groupName ?? 'Group') : t.peer.name, style: TextStyle(color: cs.onSurface)),
                                          ],
                                        ),
                                      ))
                                  .toList();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Preview
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: mediaList.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  return _buildPreviewItem(mediaList[index]);
                },
              ),
            ),

            // Caption Input
            Container(
              padding: const EdgeInsets.all(16),
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _captionController,
                      style: TextStyle(color: cs.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Add a caption...',
                        hintStyle: TextStyle(color: cs.onSurfaceVariant),
                        filled: true,
                        fillColor: cs.surfaceContainer,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton(
                    onPressed: () {
                      widget.onSend(mediaList, _captionController.text, _compressToZip, _selectedThreadIds);
                    },
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    elevation: 0,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),

            // Bottom Carousel
            Container(
              height: 100,
              color: cs.surfaceContainerLow,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                children: [
                  if (mediaList.length > 1)
                    Row(
                      children: [
                        Checkbox(
                          value: _compressToZip,
                          onChanged: (val) => setState(() => _compressToZip = val ?? false),
                          fillColor: WidgetStateProperty.resolveWith((states) => cs.primary),
                          checkColor: cs.onPrimary,
                        ),
                        Text('Send as Zip', style: TextStyle(color: cs.onSurface)),
                        VerticalDivider(color: cs.outlineVariant, indent: 8, endIndent: 8),
                      ],
                    ),
                  Expanded(
                    child: Center(
                      child: ListView.builder(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: mediaList.length + 1,
                        itemBuilder: (context, index) {
                          if (index == mediaList.length) {
                            return GestureDetector(
                              onTap: widget.onAddMore,
                              child: Container(
                                width: 64,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: cs.outlineVariant),
                                ),
                                child: Center(
                                  child: Icon(Icons.add, color: cs.onSurfaceVariant, size: 32),
                                ),
                              ),
                            );
                          }
                          
                          final media = mediaList[index];
                          final isSelected = index == _currentIndex;
                          
                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? cs.primary : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: media.isImage
                                        ? Image.memory(media.bytes, fit: BoxFit.cover)
                                        : Container(
                                            color: cs.secondaryContainer,
                                            child: Center(
                                              child: Icon(Icons.insert_drive_file, color: cs.onSecondaryContainer),
                                            ),
                                          ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => widget.onRemove(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
