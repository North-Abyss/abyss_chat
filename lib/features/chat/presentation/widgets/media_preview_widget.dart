import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:abyss_chat/network/web_storage.dart';

class MediaPreviewWidget extends StatefulWidget {
  final String? filePath;
  final String? fileData;
  final String fileName;
  final double? width;
  final double? height;
  final bool isFullScreen;

  const MediaPreviewWidget({
    super.key,
    this.filePath,
    this.fileData,
    required this.fileName,
    this.width,
    this.height,
    this.isFullScreen = false,
  });

  @override
  State<MediaPreviewWidget> createState() => _MediaPreviewWidgetState();
}

class _MediaPreviewWidgetState extends State<MediaPreviewWidget> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _volume = 1.0;
  bool _hasError = false;
  String _errorMessage = '';

  late String _extension;

  void _toggleMute() {
    setState(() {
      _volume = _volume > 0 ? 0.0 : 1.0;
      _videoController?.setVolume(_volume);
    });
  }

  @override
  void initState() {
    super.initState();
    _extension = widget.fileName.split('.').last.toLowerCase();
    _initMedia();
  }

  Future<void> _initMedia() async {
    String? webUrl;
    if (kIsWeb && widget.fileData != null) {
      webUrl = widget.fileData!;
      if (webUrl.startsWith('web_idb:')) {
        final id = webUrl.split(':')[1];
        webUrl = await WebStorage.getMediaUrl(id);
      } else if (!webUrl.startsWith('http') && !webUrl.startsWith('data:')) {
        webUrl = 'data:application/octet-stream;base64,$webUrl';
      }
    }

    if (_isVideo) {
      if (kIsWeb && webUrl != null) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(webUrl));
      } else if (widget.filePath != null) {
        _videoController = VideoPlayerController.file(File(widget.filePath!));
      }
      
      if (_videoController != null) {
        try {
          await _videoController!.initialize();
          _videoController!.setVolume(_volume);
          _videoController!.addListener(() {
            if (mounted) {
              setState(() {
                _isPlaying = _videoController!.value.isPlaying;
                _position = _videoController!.value.position;
                _duration = _videoController!.value.duration;
              });
            }
          });
        } catch (e) {
          debugPrint('Video init error: $e');
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorMessage = 'Video format not supported on this platform';
            });
          }
        }
      }
      if (mounted) setState(() {});
    } else if (_isAudio) {
      _audioPlayer = AudioPlayer();
      try {
        if (kIsWeb && webUrl != null) {
          await _audioPlayer!.setUrl(webUrl);
        } else if (widget.filePath != null) {
          await _audioPlayer!.setFilePath(widget.filePath!);
        }
        
        _audioPlayer!.playerStateStream.listen((state) {
          if (mounted) {
            setState(() {
              _isPlaying = state.playing;
            });
          }
        });
        _audioPlayer!.positionStream.listen((pos) {
          if (mounted) {
            setState(() {
              _position = pos;
            });
          }
        });
        _audioPlayer!.durationStream.listen((dur) {
          if (mounted) {
            setState(() {
              _duration = dur ?? Duration.zero;
            });
          }
        });
      } catch (e) {
        debugPrint('Audio init error: $e');
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Audio format not supported on this platform';
          });
        }
      }
    }
  }

  bool get _isVideo => ['mp4', 'mkv', 'avi', 'mov'].contains(_extension);
  bool get _isAudio => ['mp3', 'wav', 'm4a', 'aac', 'ogg'].contains(_extension);
  bool get _isImage => ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(_extension);

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_isVideo && _videoController != null) {
      _isPlaying ? _videoController!.pause() : _videoController!.play();
    } else if (_isAudio && _audioPlayer != null) {
      _isPlaying ? _audioPlayer!.pause() : _audioPlayer!.play();
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    if (_isImage) {
      if (kIsWeb && widget.fileData != null) {
        return const SizedBox.shrink(); // Handled by WebMediaImage elsewhere
      }
      if (widget.filePath != null) {
        return Image.file(
          File(widget.filePath!),
          width: widget.width,
          height: widget.height,
          fit: BoxFit.cover,
        );
      }
    }

    if (_isVideo) {
      if (_hasError) {
        return Container(
          width: widget.width ?? 250,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        );
      }

      if (_videoController == null || !_videoController!.value.isInitialized) {
        return Container(
          width: widget.width ?? 250,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        );
      }
      return Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          if (!widget.isFullScreen || !_isPlaying)
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                size: widget.isFullScreen ? 64 : 48,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              onPressed: _togglePlayPause,
            ),
          if (widget.isFullScreen)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: _togglePlayPause,
                    ),
                    const SizedBox(width: 8),
                    Text('${_formatDuration(_position)} / ${_formatDuration(_duration)}', style: const TextStyle(color: Colors.white)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: VideoProgressIndicator(
                        _videoController!,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          playedColor: Theme.of(context).colorScheme.primary,
                          bufferedColor: Colors.white38,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(
                        _volume > 0 ? Icons.volume_up : Icons.volume_off,
                        color: Colors.white,
                      ),
                      onPressed: _toggleMute,
                    ),
                    SizedBox(
                      width: 100,
                      child: Slider(
                        value: _volume,
                        max: 1.0,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white38,
                        onChanged: (val) {
                          setState(() {
                            _volume = val;
                            _videoController?.setVolume(val);
                          });
                        }
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _videoController!,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: Theme.of(context).colorScheme.primary,
                  bufferedColor: Colors.grey.withValues(alpha: 0.5),
                  backgroundColor: Colors.black26,
                ),
              ),
            )
        ],
      );
    }

    if (_isAudio) {
      final cs = Theme.of(context).colorScheme;
      if (widget.isFullScreen) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AspectRatio(
              aspectRatio: 5 / 4,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.music_note_rounded, color: cs.primary, size: 80),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.fileName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    SliderTheme(
                      data: const SliderThemeData(
                        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                        trackHeight: 4.0,
                      ),
                      child: Slider(
                        value: _position.inMilliseconds.toDouble(),
                        max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                        onChanged: (val) {
                          if (_audioPlayer != null) {
                            _audioPlayer!.seek(Duration(milliseconds: val.toInt()));
                          }
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(_position), style: const TextStyle(fontSize: 12)),
                        Text(_formatDuration(_duration), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                        color: cs.primary,
                        size: 64,
                      ),
                      onPressed: _togglePlayPause,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.music_note_rounded, color: cs.primary, size: 32),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                color: cs.primary,
                size: 36,
              ),
              onPressed: _togglePlayPause,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.fileName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  SliderTheme(
                    data: const SliderThemeData(
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                      trackHeight: 2.0,
                    ),
                    child: Slider(
                      value: _position.inMilliseconds.toDouble(),
                      max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                      onChanged: (val) {
                        if (_audioPlayer != null) {
                          _audioPlayer!.seek(Duration(milliseconds: val.toInt()));
                        }
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(_position), style: const TextStyle(fontSize: 10)),
                      Text(_formatDuration(_duration), style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      );
    }

    // Fallback for other file types or uninitialized state
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.withValues(alpha: 0.1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isVideo ? Icons.video_file : (_isAudio ? Icons.audio_file : Icons.insert_drive_file),
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            widget.fileName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
