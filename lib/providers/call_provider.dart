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

  CallSession({
    required this.peer,
    required this.isVideo,
    this.state = CallState.idle,
    this.startTime,
  });

  CallSession copyWith({CallState? state, DateTime? startTime}) {
    return CallSession(
      peer: peer,
      isVideo: isVideo,
      state: state ?? this.state,
      startTime: startTime ?? this.startTime,
    );
  }
}

class CallNotifier extends Notifier<CallSession?> {
  OverlayEntry? _overlayEntry;

  @override
  CallSession? build() => null;

  void startCall(User peer, bool isVideo) {
    state = CallSession(peer: peer, isVideo: isVideo, state: CallState.ringing);
  }

  void setConnected() {
    if (state != null) {
      state = state!.copyWith(state: CallState.connected, startTime: DateTime.now());
    }
  }

  void endCall() {
    state = null;
    hideMiniCall();
  }

  void showMiniCall() {
    if (state == null || _overlayEntry != null) return;
    
    final context = globalNavigatorKey.currentState?.overlay?.context;
    if (context == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => const MiniCallOverlay(),
    );
    globalNavigatorKey.currentState?.overlay?.insert(_overlayEntry!);
  }

  void hideMiniCall() {
    _overlayEntry?.remove();
    _overlayEntry = null;
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
          // Hide overlay and push call screen back
          ref.read(callProvider.notifier).hideMiniCall();
          globalNavigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => CallScreen(
                peer: callState.peer,
                isVideo: callState.isVideo,
              ),
            ),
          );
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
