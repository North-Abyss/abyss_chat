import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PickedMedia {
  final String name;
  final Uint8List bytes;
  final String? path;

  PickedMedia({
    required this.name,
    required this.bytes,
    this.path,
  });

  bool get isImage {
    final ext = name.split('.').last.toLowerCase();
    return ['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(ext);
  }
}

class MediaPreviewDialog extends StatefulWidget {
  final List<PickedMedia> mediaList;
  final Function(List<PickedMedia> selectedMedia, String caption, bool compressToZip) onSend;

  const MediaPreviewDialog({
    super.key,
    required this.mediaList,
    required this.onSend,
  });

  @override
  State<MediaPreviewDialog> createState() => _MediaPreviewDialogState();
}

class _MediaPreviewDialogState extends State<MediaPreviewDialog> {
  late PageController _pageController;
  int _currentIndex = 0;
  final TextEditingController _captionController = TextEditingController();
  bool _compressToZip = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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
      // Document/File preview
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.insert_drive_file, size: 100, color: Colors.indigo),
            const SizedBox(height: 16),
            Text(
              media.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${(media.bytes.length / 1024 / 1024).toStringAsFixed(2)} MB',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Preview Media (${_currentIndex + 1}/${widget.mediaList.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Carousel
            Expanded(
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: widget.mediaList.length,
                    onPageChanged: (idx) => setState(() => _currentIndex = idx),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildPreviewItem(widget.mediaList[index]),
                      );
                    },
                  ),
                  
                  // Left Arrow
                  if (_currentIndex > 0)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                        onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                      ),
                    ),
                  
                  // Right Arrow
                  if (_currentIndex < widget.mediaList.length - 1)
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                        onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                      ),
                    ),
                ],
              ),
            ),
            
            // Controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Caption input
                  TextField(
                    controller: _captionController,
                    decoration: InputDecoration(
                      hintText: 'Add a caption...',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    maxLines: null,
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      // Zip Compression Toggle
                      if (widget.mediaList.length > 1)
                        Expanded(
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Zip files into one archive'),
                            value: _compressToZip,
                            onChanged: (val) {
                              setState(() {
                                _compressToZip = val ?? false;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        )
                      else
                        const Spacer(),
                        
                      // Send Button
                      FloatingActionButton(
                        onPressed: () {
                          widget.onSend(widget.mediaList, _captionController.text.trim(), _compressToZip);
                          Navigator.of(context).pop();
                        },
                        elevation: 0,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        child: const Icon(Icons.send),
                      ),
                    ],
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
