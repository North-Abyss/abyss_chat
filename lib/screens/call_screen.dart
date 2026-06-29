import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/models/call_log.dart';
import 'package:abyss_chat/providers/chat_provider.dart';
import 'package:abyss_chat/widgets/user_avatar.dart';
import 'package:abyss_chat/providers/call_provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';
import 'package:abyss_chat/models/user.dart';

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
  bool _isVideoEnabled = false;
  bool _isSpeaker = false;
  
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
          child: Stack(
            children: [
              // Main Content Area (Video or Avatar)
              Positioned.fill(
                child: (isConnected && callState.isVideo && remoteRenderers.isNotEmpty)
                    ? _buildVideoGrid(remoteRenderers, callState.peers)
                    : _buildAudioPlaceholder(callState, isConnected),
              ),

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
                            child: UserAvatar(
                              user: callState.peers.firstWhere((p) => p.id == ref.read(peerServiceProvider).myId, orElse: () => User(id: '', name: 'Me', avatarIcon: 0xe491, avatarColor: 0xFF6750A4)),
                              radius: 32,
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

              // Floating Controls Shortcut Box
              Positioned(
                bottom: 32,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[900]?.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
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
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildVideoGrid(Map<String, RTCVideoRenderer> renderers, List<dynamic> peers) {
    if (renderers.isEmpty) return const Center(child: CircularProgressIndicator());
    
    final count = renderers.length;
    int columns = 1;
    if (count > 1 && count <= 4) columns = 2;
    if (count > 4) columns = 3;

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: count == 1 ? 0.75 : 1.0, // Taller if only 1 person
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: renderers.length,
      itemBuilder: (context, index) {
        final peerId = renderers.keys.elementAt(index);
        final renderer = renderers[peerId]!;
        final matches = peers.where((p) => p.id == peerId).toList();
        final peerName = matches.isNotEmpty ? matches.first.name : 'Unknown';
        
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
                RTCVideoView(
                  renderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white24,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.black : Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
