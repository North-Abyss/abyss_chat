import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/models/user.dart';
import 'package:abyss_chat/models/call_log.dart';
import 'package:abyss_chat/providers/chat_provider.dart';
import 'package:abyss_chat/widgets/user_avatar.dart';
import 'package:abyss_chat/providers/call_provider.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';

class CallScreen extends ConsumerStatefulWidget {
  final User peer;
  final bool isVideo;
  final bool isIncoming;

  const CallScreen({
    super.key,
    required this.peer,
    this.isVideo = false,
    this.isIncoming = false,
  });

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  bool _isMuted = false;
  bool _isVideoEnabled = false;
  bool _isSpeaker = false;
  
  Timer? _timer;
  String _timerText = '00:00';

  @override
  void initState() {
    super.initState();
    _isVideoEnabled = widget.isVideo;
    
    // Simulate answering a call or connecting after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        final notifier = ref.read(callProvider.notifier);
        notifier.setConnected();
        
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) return;
          final callState = ref.read(callProvider);
          if (callState?.startTime != null) {
            final duration = DateTime.now().difference(callState!.startTime!);
            setState(() {
              _timerText = '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _minimizeCall() {
    ref.read(callProvider.notifier).showMiniCall();
    Navigator.pop(context);
  }

  void _endCall() {
    final callState = ref.read(callProvider);
    final startTime = callState?.startTime;
    
    // Log the call
    final duration = startTime != null ? DateTime.now().difference(startTime) : null;
    final log = CallLog(
      id: const Uuid().v4(),
      peer: widget.peer,
      isVideo: widget.isVideo,
      timestamp: startTime ?? DateTime.now(),
      duration: duration,
      isOutgoing: !widget.isIncoming,
      isMissed: callState?.state != CallState.connected,
    );
    ref.read(callLogsProvider.notifier).addCallLog(log);
    ref.read(callProvider.notifier).endCall();
    
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callProvider);
    final isConnected = callState?.state == CallState.connected;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            
            // Video / Avatar Area
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    UserAvatar(user: widget.peer, radius: 80),
                    const SizedBox(height: 32),
                    Text(
                      widget.peer.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isConnected ? _timerText : (widget.isIncoming ? 'Incoming...' : 'Ringing...'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Controls Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Speaker
                  _buildControlButton(
                    icon: _isSpeaker ? Icons.volume_up : Icons.volume_down,
                    isActive: _isSpeaker,
                    onPressed: () => setState(() => _isSpeaker = !_isSpeaker),
                  ),
                  
                  // Mute Audio
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    isActive: _isMuted,
                    onPressed: () => setState(() => _isMuted = !_isMuted),
                  ),
                  
                  // Toggle Video
                  _buildControlButton(
                    icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                    isActive: !_isVideoEnabled,
                    onPressed: () => setState(() => _isVideoEnabled = !_isVideoEnabled),
                  ),
                  
                  // End Call
                  GestureDetector(
                    onTap: _endCall,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.call_end, color: Colors.white, size: 32),
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
