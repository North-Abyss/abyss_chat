import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/models/call_log.dart';
import 'package:abyss_chat/providers/chat_provider.dart';
import 'package:abyss_chat/widgets/user_avatar.dart';
import 'package:abyss_chat/providers/call_provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';
import 'package:abyss_chat/models/user.dart';

class ReactionInstance {
  final String id;
  final String emoji;
  final double xOffset;
  ReactionInstance(this.id, this.emoji, this.xOffset);
}

class CallScreen extends ConsumerStatefulWidget {
  final bool isIncoming;

  const CallScreen({
    super.key,
    this.isIncoming = false,
  });

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeaker = true;
  bool _isEmojiDockOpen = false;
  final Map<String, TransformationController> _transformControllers = {};
  
  final List<ReactionInstance> _activeReactions = [];
  StreamSubscription? _reactionSub;
  
  @override
  void initState() {
    super.initState();
    // Default to the call state video setting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final callState = ref.read(callProvider);
      if (callState != null && mounted) {
        setState(() {
          _isVideoEnabled = callState.isVideo;
        });
      }
    });

    _reactionSub = ref.read(callProvider.notifier).reactionStream.listen((msg) {
      final emoji = msg['emoji'] as String;
      _spawnReaction(emoji);
    });
  }

  void _spawnReaction(String emoji) {
    if (!mounted) return;
    final id = const Uuid().v4();
    final xOffset = 0.2 + (DateTime.now().millisecondsSinceEpoch % 60) / 100.0; 
    
    setState(() {
      _activeReactions.add(ReactionInstance(id, emoji, xOffset));
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _activeReactions.removeWhere((r) => r.id == id);
        });
      }
    });
  }

  @override
  void dispose() {
    _reactionSub?.cancel();
    for (final controller in _transformControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _minimizeCall() {
    ref.read(callProvider.notifier).showMiniCall();
  }

  void _endCall() {
    final callState = ref.read(callProvider);
    if (callState == null) return;
    
    final startTime = callState.startTime;
    final duration = startTime != null ? DateTime.now().difference(startTime) : null;
    
    // Log the call for all peers
    for (final peer in callState.peers) {
      final log = CallLog(
        id: const Uuid().v4(),
        peer: peer,
        isVideo: callState.isVideo,
        timestamp: startTime ?? DateTime.now(),
        duration: duration,
        isOutgoing: !widget.isIncoming,
        isMissed: callState.state != CallState.connected,
      );
      ref.read(callLogsProvider.notifier).addCallLog(log);
    }
    
    ref.read(callProvider.notifier).endCall();
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callProvider);
    if (callState == null) return const Scaffold(backgroundColor: Colors.black);
    
    final isConnected = callState.state == CallState.connected;
    final remoteRenderers = ref.read(callProvider.notifier).remoteRenderers;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _minimizeCall();
        },
        child: SafeArea(
          child: Column(
            children: [
              // Main Content Area (Video)
              Expanded(
                child: Stack(
                  children: [
                    // Main Content Area (Video or Avatar)
              Positioned.fill(
                child: (isConnected && callState.isVideo && remoteRenderers.isNotEmpty)
                    ? _buildVideoGrid(remoteRenderers, callState.peers)
                    : _buildAudioPlaceholder(callState, isConnected),
              ),
              
              // Reactions Overlay
              if (_activeReactions.isNotEmpty)
                Positioned.fill(child: _buildReactionsOverlay()),

              // Local Mini Video (Picture in Picture)
              if (isConnected && callState.isVideo)
                Positioned(
                  right: 16,
                  top: 16,
                  width: 100,
                  height: 150,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _isVideoEnabled
                      ? RTCVideoView(
                          ref.read(callProvider.notifier).localRenderer,
                          mirror: true,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        )
                      : Container(
                          color: Colors.black87,
                          child: Center(
                            child: ref.watch(myProfileProvider).when(
                              data: (profile) => UserAvatar(
                                user: profile ?? User(id: '', name: 'Me', avatarIcon: 0xe491, avatarColor: 0xFF6750A4),
                                radius: 32,
                              ),
                              loading: () => const CircularProgressIndicator(color: Colors.white24),
                              error: (error, stack) => UserAvatar(
                                user: User(id: '', name: 'Me', avatarIcon: 0xe491, avatarColor: 0xFF6750A4),
                                radius: 32,
                              ),
                            ),
                          ),
                        ),
                  ),
                ),

              // Top Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black87, Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                        onPressed: _minimizeCall,
                      ),
                      const Spacer(),
                      const Icon(Icons.lock, size: 12, color: Colors.white54),
                      const SizedBox(width: 4),
                      const Text('End-to-end encrypted', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      const Spacer(),
                      const SizedBox(width: 48), // Balance
                    ],
                  ),
                ),
              ),
              // Floating Emoji Dock overlaid on video
              if (_isEmojiDockOpen && isConnected)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[800]?.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildEmojiDockButton('👍'),
                          _buildEmojiDockButton('❤️'),
                          _buildEmojiDockButton('😂'),
                          _buildEmojiDockButton('👏'),
                          _buildEmojiDockButton('🎉'),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),


              // Floating Controls Shortcut Box / Dock
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.grey[900]?.withValues(alpha: 0.85),
                  border: const Border(top: BorderSide(color: Colors.white12)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (widget.isIncoming && callState.state == CallState.ringing) ...[
                        _buildActionButton(Icons.call_end, Colors.red, _endCall),
                        _buildActionButton(Icons.call, Colors.green, () => ref.read(callProvider.notifier).answerCall()),
                      ] else ...[
                        _buildControlButton(
                          icon: _isSpeaker ? Icons.volume_up : Icons.volume_down,
                          isActive: _isSpeaker,
                          onPressed: () => setState(() => _isSpeaker = !_isSpeaker),
                        ),
                        if (callState.isVideo)
                          _buildControlButton(
                            icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                            isActive: !_isVideoEnabled,
                            onPressed: () {
                              setState(() => _isVideoEnabled = !_isVideoEnabled);
                              ref.read(callProvider.notifier).toggleVideo(_isVideoEnabled);
                            },
                          ),
                        _buildControlButton(
                          icon: _isMuted ? Icons.mic_off : Icons.mic,
                          isActive: _isMuted,
                          onPressed: () {
                            setState(() => _isMuted = !_isMuted);
                            ref.read(callProvider.notifier).toggleAudio(!_isMuted);
                          },
                        ),
                        // Emoji Toggle Button
                        _buildControlButton(
                          icon: Icons.emoji_emotions,
                          isActive: _isEmojiDockOpen,
                          onPressed: () => setState(() => _isEmojiDockOpen = !_isEmojiDockOpen),
                        ),
                        _buildActionButton(Icons.call_end, Colors.red, _endCall),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReactionsOverlay() {
    return IgnorePointer(
      child: Stack(
        children: _activeReactions.map((reaction) {
          return Positioned(
            left: MediaQuery.of(context).size.width * reaction.xOffset,
            bottom: 100, // Starts just above controls
            child: TweenAnimationBuilder<double>(
              key: ValueKey(reaction.id),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 3),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, -300 * value), // Float up 300px
                  child: Opacity(
                    opacity: 1.0 - value, // Fade out
                    child: Text(
                      reaction.emoji,
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAudioPlaceholder(CallSession callState, bool isConnected) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (callState.peers.length == 1)
            UserAvatar(user: callState.peers.first, radius: 80)
          else
            const CircleAvatar(
              radius: 80,
              backgroundColor: Colors.grey,
              child: Icon(Icons.group, size: 80, color: Colors.white),
            ),
          const SizedBox(height: 32),
          Text(
            callState.peers.length == 1 
                ? callState.peers.first.name 
                : '${callState.peers.length} Participants',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isConnected 
              ? '${(callState.currentDuration?.inMinutes ?? 0).toString().padLeft(2, '0')}:${((callState.currentDuration?.inSeconds ?? 0) % 60).toString().padLeft(2, '0')}' 
              : callState.state == CallState.ended 
                  ? '⚠️ Connection failed!'
                  : (widget.isIncoming ? 'Incoming...' : 'Calling...'),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onPressed) {
    return IconButton.filled(
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 32,
      padding: const EdgeInsets.all(16),
      style: IconButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildVideoGrid(Map<String, RTCVideoRenderer> renderers, List<dynamic> peers) {
    if (renderers.isEmpty) return const Center(child: CircularProgressIndicator());
    
    final count = renderers.length;

    Widget buildContainer(String peerId, RTCVideoRenderer renderer) {
        final matches = peers.where((p) => p.id == peerId).toList();
        final peerName = matches.isNotEmpty ? matches.first.name : 'Unknown';
        
        _transformControllers.putIfAbsent(peerId, () => TransformationController());
        final tController = _transformControllers[peerId]!;

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (ref.read(callProvider.notifier).remoteMediaStatus[peerId]?['videoEnabled'] ?? true)
                InteractiveViewer(
                  transformationController: tController,
                  minScale: 0.5,
                  maxScale: 4.0,
                  scaleEnabled: false,
                  child: RTCVideoView(
                    renderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                  ),
                )
              else
                Container(
                  color: Colors.black87,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (matches.isNotEmpty)
                          UserAvatar(user: matches.first, radius: 48)
                        else
                          const CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person, size: 48, color: Colors.white),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          peerName,
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              // Name Badge
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    peerName,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              // Zoom Controls Overlay
              if (ref.read(callProvider.notifier).remoteMediaStatus[peerId]?['videoEnabled'] ?? true)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildZoomButton(Icons.add, () {
                        setState(() {
                          tController.value = tController.value.clone()..multiply(Matrix4.diagonal3Values(1.2, 1.2, 1.2));
                        });
                      }),
                      const SizedBox(height: 4),
                      _buildZoomButton(Icons.remove, () {
                        setState(() {
                          tController.value = tController.value.clone()..multiply(Matrix4.diagonal3Values(0.8, 0.8, 0.8));
                        });
                      }),
                      const SizedBox(height: 4),
                      _buildZoomButton(Icons.fit_screen, () {
                        setState(() {
                          tController.value = Matrix4.identity();
                        });
                      }),
                    ],
                  ),
                ),
            ],
          ),
        );
    }

    if (count == 1) {
      final peerId = renderers.keys.first;
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: buildContainer(peerId, renderers[peerId]!),
      );
    }

    // For multiple peers, use a Wrap
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: renderers.entries.map((e) => SizedBox(
          width: count == 2 ? MediaQuery.of(context).size.width / 2 - 12 : MediaQuery.of(context).size.width / 2 - 12,
          height: 300,
          child: buildContainer(e.key, e.value),
        )).toList(),
      ),
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildEmojiDockButton(String emoji) {
    return InkWell(
      onTap: () {
        ref.read(callProvider.notifier).sendReaction(emoji);
        setState(() => _isEmojiDockOpen = false);
      },
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Text(emoji, style: const TextStyle(fontSize: 28)),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return IconButton.filled(
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 28,
      padding: const EdgeInsets.all(16),
      style: IconButton.styleFrom(
        backgroundColor: isActive ? Colors.white : Colors.grey[800],
        foregroundColor: isActive ? Colors.black : Colors.white,
      ),
    );
  }
}
