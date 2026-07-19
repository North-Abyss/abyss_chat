import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/constants/app_constants.dart';

class GifPlayer extends StatefulWidget {
  final String url;
  final BoxFit fit;

  const GifPlayer({super.key, required this.url, required this.fit});

  @override
  State<GifPlayer> createState() => _GifPlayerState();
}

class _GifPlayerState extends State<GifPlayer> {
  bool _isPlaying = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(AppConstants.gifPauseDelay, () {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isPlaying = !_isPlaying;
          if (_isPlaying) {
            _startTimer();
          } else {
            _timer?.cancel();
          }
        });
      },
      child: Stack(
        fit: StackFit.passthrough,
        alignment: Alignment.center,
        children: [
          _isPlaying
              ? Image.network(widget.url, fit: widget.fit)
              : CachedNetworkImage(imageUrl: widget.url, fit: widget.fit),
          if (!_isPlaying)
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black54,
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.gif_box, color: Colors.white, size: 32),
            ),
        ],
      ),
    );
  }
}
