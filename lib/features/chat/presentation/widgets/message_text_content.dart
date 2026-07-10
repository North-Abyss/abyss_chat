import 'package:flutter/material.dart';
import 'package:abyss_chat/features/chat/domain/models/message.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';
class MessageTextContent extends StatelessWidget {
  final Message msg;
  final bool isMe;

  const MessageTextContent({super.key, required this.msg, required this.isMe});

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.gif') || lower.endsWith('.webp');
  }

  bool _isVideoUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') || lower.endsWith('.webm') || lower.endsWith('.ogg');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textColor = isMe ? cs.onPrimaryContainer : cs.onSurface;

    // Very simple URL extraction (first URL found)
    final RegExp urlRegExp = RegExp(
      r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+',
      caseSensitive: false,
    );
    
    final match = urlRegExp.firstMatch(msg.text);
    if (match != null) {
      String url = match.group(0)!;
      if (!url.startsWith('http')) {
        url = 'https://$url';
      }

      // We have a URL, let's render text + preview
      return Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Text before/after or just the text with the URL
          InkWell(
            onTap: () => launchUrl(Uri.parse(url)),
            child: Text(
              msg.text,
              style: TextStyle(
                fontSize: 15,
                color: textColor,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildPreview(url, context),
        ],
      );
    }

    // Default plain text
    return Text(
      msg.text,
      style: TextStyle(
        fontSize: 15,
        color: textColor,
      ),
    );
  }

  Widget _buildPreview(String url, BuildContext context) {
    if (_isImageUrl(url)) {
      return GestureDetector(
        onTap: () => launchUrl(Uri.parse(url)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            width: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
          ),
        ),
      );
    } else if (_isVideoUrl(url)) {
      return _InlineVideoPlayer(url: url);
    } else {
      return SizedBox(
        width: 250,
        child: AnyLinkPreview(
          link: url,
          proxyUrl: kIsWeb ? 'https://corsproxy.io/?' : null,
          displayDirection: UIDirection.uiDirectionHorizontal,
          cache: const Duration(days: 7),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          errorWidget: Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.all(8),
            child: InkWell(
              onTap: () => launchUrl(Uri.parse(url)),
              child: const Text('View link \u2197', style: TextStyle(fontSize: 12, decoration: TextDecoration.underline, color: Colors.blue)),
            ),
          ),
        ),
      );
    }
  }
}

class _InlineVideoPlayer extends StatefulWidget {
  final String url;
  const _InlineVideoPlayer({required this.url});

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
      }).catchError((e) {
        if (mounted) setState(() => _error = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) return const Icon(Icons.error, color: Colors.red);
    if (!_initialized) return const SizedBox(width: 200, height: 150, child: Center(child: CircularProgressIndicator()));

    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying ? _controller.pause() : _controller.play();
        });
      },
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.black,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
            if (!_controller.value.isPlaying)
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black54,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
              ),
          ],
        ),
      ),
    );
  }
}
