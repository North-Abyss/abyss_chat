import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'package:abyss_chat/features/chat/domain/models/message.dart';

class AudioMessageBubble extends StatefulWidget {
  final Message msg;
  final bool isMe;

  const AudioMessageBubble({super.key, required this.msg, required this.isMe});

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble> {
  final _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      if (widget.msg.localFilePath != null && !kIsWeb) {
        await _audioPlayer.setFilePath(widget.msg.localFilePath!);
      } else if (widget.msg.fileData != null) {
        if (kIsWeb) {
          final dataUri = 'data:audio/mp4;base64,${widget.msg.fileData}';
          await _audioPlayer.setUrl(dataUri);
        } else {
          final bytes = base64Decode(widget.msg.fileData!);
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/${widget.msg.id}.m4a');
          await file.writeAsBytes(bytes);
          await _audioPlayer.setFilePath(file.path);
        }
      }
      
      _audioPlayer.durationStream.listen((d) {
        if (mounted) setState(() => _duration = d ?? Duration.zero);
      });
      _audioPlayer.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) setState(() => _isPlaying = state.playing);
        if (state.processingState == ProcessingState.completed) {
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.pause();
        }
      });
    } catch (e) {
      debugPrint('Error loading audio: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: widget.isMe ? cs.onPrimaryContainer : cs.onSurface),
          onPressed: () {
            if (_isPlaying) {
              _audioPlayer.pause();
            } else {
              _audioPlayer.play();
            }
          },
        ),
        SizedBox(
          width: 150,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _position.inMilliseconds.toDouble()),
            duration: const Duration(milliseconds: 200),
            builder: (context, val, _) {
              final maxVal = _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0;
              return Slider(
                value: val.clamp(0.0, maxVal),
                max: maxVal,
                onChanged: (newVal) {
                  _audioPlayer.seek(Duration(milliseconds: newVal.toInt()));
                },
                activeColor: widget.isMe ? cs.onPrimaryContainer : cs.primary,
                inactiveColor: widget.isMe ? cs.onPrimaryContainer.withValues(alpha: 0.3) : cs.primary.withValues(alpha: 0.3),
              );
            },
          ),
        ),
        Text(
          '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: 10,
            color: widget.isMe ? cs.onPrimaryContainer : cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
