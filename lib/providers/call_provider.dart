import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/models/user.dart';
import 'package:abyss_chat/screens/call_screen.dart';

// Global navigator key to insert the overlay anywhere
final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

enum CallState { idle, ringing, connected, ended }

class CallSession {
  final User peer;
  final bool isVideo;
  final CallState state;
  final DateTime? startTime;
  final Duration? currentDuration;

  CallSession({
    required this.peer,
    required this.isVideo,
    this.state = CallState.idle,
    this.startTime,
    this.currentDuration,
  });

  CallSession copyWith({CallState? state, DateTime? startTime, Duration? currentDuration}) {
    return CallSession(
      peer: peer,
      isVideo: isVideo,
      state: state ?? this.state,
      startTime: startTime ?? this.startTime,
      currentDuration: currentDuration ?? this.currentDuration,
    );
  }
}

class CallNotifier extends Notifier<CallSession?> {
  OverlayEntry? _overlayEntry;
  Timer? _timer;

  @override
  CallSession? build() => null;

  void startCall(User peer, bool isVideo) {
    if (state != null) return; // Already in a call
    
    state = CallSession(peer: peer, isVideo: isVideo, state: CallState.ringing);
    _showFullCall();
    
    // Simulate answering a call or connecting after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      setConnected();
    });
  }

  void _showFullCall() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
    }
    
    final context = globalNavigatorKey.currentState?.overlay?.context;
    if (context == null || state == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => CallScreen(peer: state!.peer, isVideo: state!.isVideo),
    );
    globalNavigatorKey.currentState?.overlay?.insert(_overlayEntry!);
  }

  void setConnected() {
    if (state != null) {
      final startTime = DateTime.now();
      state = state!.copyWith(state: CallState.connected, startTime: startTime, currentDuration: Duration.zero);
      
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (state != null && state!.startTime != null) {
          state = state!.copyWith(currentDuration: DateTime.now().difference(state!.startTime!));
        }
      });
    }
  }

  void endCall() {
    _timer?.cancel();
    _timer = null;
    state = null;
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  void showMiniCall() {
    if (state == null) return;
    
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
    }
    
    final context = globalNavigatorKey.currentState?.overlay?.context;
    if (context == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => const MiniCallOverlay(),
    );
    globalNavigatorKey.currentState?.overlay?.insert(_overlayEntry!);
  }
  
  void maximizeCall() {
    _showFullCall();
  }
}

final callProvider = NotifierProvider<CallNotifier, CallSession?>(() => CallNotifier());

class MiniCallOverlay extends ConsumerStatefulWidget {
  const MiniCallOverlay({super.key});

  @override
  ConsumerState<MiniCallOverlay> createState() => _MiniCallOverlayState();
}

class _MiniCallOverlayState extends ConsumerState<MiniCallOverlay> {
  Offset position = const Offset(20, 40); // Initial top-left padding

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callProvider);
    if (callState == null) return const SizedBox.shrink();

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            position += details.delta;
          });
        },
        onTap: () {
          // Hide overlay and show full call
          ref.read(callProvider.notifier).maximizeCall();
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(callState.isVideo ? Icons.videocam : Icons.call, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  callState.state == CallState.connected ? 'Tap to return' : 'Ringing...',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
