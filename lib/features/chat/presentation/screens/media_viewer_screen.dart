import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

import 'package:abyss_chat/features/chat/domain/models/message.dart';
import 'package:abyss_chat/features/chat/presentation/widgets/web_media_image.dart';
import 'package:abyss_chat/network/web_storage.dart';

class MediaViewerScreen extends StatefulWidget {
  final List<Message> mediaMessages;
  final int initialIndex;

  const MediaViewerScreen({
    super.key,
    required this.mediaMessages,
    required this.initialIndex,
  });

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  final FocusNode _focusNode = FocusNode();
  
  bool _showControls = true;
  final Set<String> _selectedMessageIds = {};
  bool _isSelectionMode = false;

  bool _isVideo(Message msg) {
    if (msg.fileName == null) return false;
    final ext = msg.fileName!.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);
  }

  bool _isDocument(Message msg) {
     if (msg.fileName == null) return false;
     final ext = msg.fileName!.split('.').last.toLowerCase();
     return !['jpg', 'jpeg', 'png', 'gif', 'webp', 'mp4', 'mov', 'avi', 'mkv', 'webm', 'mp3', 'wav', 'ogg', 'm4a'].contains(ext);
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedMessageIds.contains(id)) {
        _selectedMessageIds.remove(id);
        if (_selectedMessageIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedMessageIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.pop(context);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (_currentIndex > 0) {
          _pageController.previousPage(duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        if (_currentIndex < widget.mediaMessages.length - 1) {
          _pageController.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
        }
      }
    }
  }

  Future<void> _shareSelected() async {
    final toShare = _isSelectionMode 
      ? widget.mediaMessages.where((m) => _selectedMessageIds.contains(m.id)).toList()
      : [widget.mediaMessages[_currentIndex]];

    final List<XFile> xFiles = [];
    for (final msg in toShare) {
      if (msg.localFilePath != null && File(msg.localFilePath!).existsSync()) {
        xFiles.add(XFile(msg.localFilePath!));
      }
    }
    
    if (xFiles.isNotEmpty) {
      await SharePlus.instance.share(
        ShareParams(
          files: xFiles,
          text: 'Shared from Abyss Chat'
        )
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No local files available to share. Download them first.')));
    }
  }

  Future<void> _downloadSelected() async {
    final toDownload = _isSelectionMode 
      ? widget.mediaMessages.where((m) => _selectedMessageIds.contains(m.id)).toList()
      : [widget.mediaMessages[_currentIndex]];
      
    int downloadedCount = 0;
    
    if (kIsWeb) {
      for (final msg in toDownload) {
        if (msg.fileData != null && msg.fileData!.startsWith('web_idb:')) {
          final id = msg.fileData!.split(':')[1];
          final fileName = msg.fileName ?? 'abyss_media_$id';
          await WebStorage.triggerDownload(id, fileName);
          downloadedCount++;
        }
      }
    } else {
      String? homeDir;
      if (Platform.isWindows) {
        homeDir = Platform.environment['USERPROFILE'];
      } else if (Platform.isLinux || Platform.isMacOS) {
        homeDir = Platform.environment['HOME'];
      } else if (Platform.isAndroid || Platform.isIOS) {
        final dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        homeDir = dir.path;
      }

      if (homeDir != null) {
        final abyssDir = Directory('$homeDir/Abyss Chat');
        if (!abyssDir.existsSync()) {
          abyssDir.createSync(recursive: true);
        }
        
        for (final msg in toDownload) {
          if (msg.localFilePath != null && File(msg.localFilePath!).existsSync()) {
            final sourceFile = File(msg.localFilePath!);
            
            // Organize into subfolders based on file type
            final extension = (msg.fileName ?? sourceFile.path.split('/').last).split('.').last.toLowerCase();
            String subFolderName = 'Documents';
            if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
              subFolderName = 'Images';
            } else if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
              subFolderName = 'Videos';
            } else if (['mp3', 'wav', 'ogg', 'm4a'].contains(extension)) {
              subFolderName = 'Audio';
            }
            
            final targetDir = Directory('${abyssDir.path}/$subFolderName');
            if (!targetDir.existsSync()) {
              targetDir.createSync(recursive: true);
            }
            
            final fileName = msg.fileName ?? 'abyss_media_${DateTime.now().millisecondsSinceEpoch}.$extension';
            final targetPath = '${targetDir.path}/$fileName';
            await sourceFile.copy(targetPath);
            downloadedCount++;
          }
        }
      }
    }
    
    if (mounted && downloadedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloaded $downloadedCount items')));
    }
    setState(() {
      _isSelectionMode = false;
      _selectedMessageIds.clear();
    });
  }

  Widget _buildTopAppBar() {
    final msg = widget.mediaMessages[_currentIndex];
    final dateStr = DateFormat('MMM d, yyyy, h:mm a').format(msg.timestamp);

    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(Icons.person, color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(msg.senderName ?? 'Unknown', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(dateStr, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
                if (_isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('${_selectedMessageIds.length} Selected', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                  ),
                IconButton(
                  icon: Icon(Icons.download, color: Theme.of(context).colorScheme.onSurface),
                  onPressed: _downloadSelected,
                  tooltip: 'Download',
                ),
                IconButton(
                  icon: Icon(Icons.share, color: Theme.of(context).colorScheme.onSurface),
                  onPressed: _shareSelected,
                  tooltip: 'Share',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCarousel() {
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: SizedBox(
              height: 64,
              child: Center(
                child: ListView.builder(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
            itemCount: widget.mediaMessages.length,
          itemBuilder: (context, index) {
            final msg = widget.mediaMessages[index];
            final isSelected = _currentIndex == index;
            final isMultiSelected = _selectedMessageIds.contains(msg.id);

            return GestureDetector(
              onTap: () {
                if (_isSelectionMode) {
                  _toggleSelection(msg.id);
                } else {
                  _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                }
              },
              onLongPress: () {
                _toggleSelection(msg.id);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                width: 50,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: WebMediaImage(msg: msg, fit: BoxFit.cover),
                    ),
                    if (isMultiSelected)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.primary),
                          child: Icon(Icons.check, size: 16, color: Theme.of(context).colorScheme.onPrimary),
                        ),
                      )
                  ],
                ),
              ),
            );
          },
        ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: widget.mediaMessages.length,
                itemBuilder: (context, index) {
                  final msg = widget.mediaMessages[index];
                  
                  if (_isVideo(msg)) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.videocam, size: 100, color: Colors.white54),
                          const SizedBox(height: 16),
                          Text(msg.fileName ?? 'Video', style: const TextStyle(color: Colors.white, fontSize: 18)),
                          const SizedBox(height: 16),
                          const Text('Video playback not supported yet.\nPlease download to view.', style: TextStyle(color: Colors.white54), textAlign: TextAlign.center),
                        ],
                      ),
                    );
                  }
                  
                  if (_isDocument(msg)) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.insert_drive_file, size: 100, color: Colors.white54),
                          const SizedBox(height: 16),
                          Text(msg.fileName ?? 'Document', style: const TextStyle(color: Colors.white, fontSize: 18)),
                          const SizedBox(height: 16),
                          const Text('Please download to view this file.', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    );
                  }

                  return _ZoomableMediaItem(
                    msg: msg,
                    onTap: () {
                      setState(() {
                        _showControls = !_showControls;
                      });
                    },
                  );
                },
              ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopAppBar(),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomCarousel(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomableMediaItem extends StatefulWidget {
  final Message msg;
  final VoidCallback onTap;

  const _ZoomableMediaItem({required this.msg, required this.onTap});

  @override
  State<_ZoomableMediaItem> createState() => _ZoomableMediaItemState();
}

class _ZoomableMediaItemState extends State<_ZoomableMediaItem> {
  final TransformationController _controller = TransformationController();
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScaleChanged);
  }

  void _onScaleChanged() {
    final scale = _controller.value.getMaxScaleOnAxis();
    if (scale > 1.0 && !_isZoomed) {
      setState(() => _isZoomed = true);
    } else if (scale <= 1.0 && _isZoomed) {
      setState(() => _isZoomed = false);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScaleChanged);
    _controller.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _controller.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onTap,
          child: InteractiveViewer(
            transformationController: _controller,
            minScale: 1.0,
            maxScale: 5.0,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: WebMediaImage(msg: widget.msg, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
        if (_isZoomed)
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _resetZoom,
              child: const Icon(Icons.zoom_out_map, color: Colors.black),
            ),
          ),
      ],
    );
  }
}
