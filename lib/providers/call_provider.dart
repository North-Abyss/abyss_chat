import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:abyss_chat/models/user.dart';
import 'package:abyss_chat/screens/call_screen.dart';
import 'package:abyss_chat/providers/chat_provider.dart';
//import 'package:abyss_chat/services/peerdart_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peerdart/peerdart.dart';

// Global navigator key to insert the overlay anywhere
final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

enum CallState { idle, ringing, connected, ended }

class CallSession {
  final User peer;
  final bool isVideo;
  final CallState state;
  final DateTime? startTime;
  final Duration? currentDuration;
  final MediaConnection? mediaConnection;

  CallSession({
    required this.peer,
    required this.isVideo,
    this.state = CallState.idle,
    this.startTime,
    this.currentDuration,
    this.mediaConnection,
  });

  CallSession copyWith({
    CallState? state, 
    DateTime? startTime, 
    Duration? currentDuration,
    MediaConnection? mediaConnection,
  }) {
    return CallSession(
      peer: peer,
      isVideo: isVideo,
      state: state ?? this.state,
      startTime: startTime ?? this.startTime,
      currentDuration: currentDuration ?? this.currentDuration,
      mediaConnection: mediaConnection ?? this.mediaConnection,
    );
  }
}

class CallNotifier extends Notifier<CallSession?> {
  OverlayEntry? _overlayEntry;
  Timer? _timer;
  MediaStream? _localStream;
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timeoutTimer;

  @override
  CallSession? build() {
    _initRenderers();
    // Listen for incoming calls
    ref.onDispose(() {
      localRenderer.dispose();
      remoteRenderer.dispose();
      _audioPlayer.dispose();
    });
    
    // Subscribe to incoming calls from PeerDartService
    Future.microtask(() {
      ref.read(peerServiceProvider).onCallReceived.listen(_handleIncomingCall);
      ref.read(peerServiceProvider).onCallRequest.listen(_handleCallRequest);
    });
    
    return null;
  }
  
  Future<void> _initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  void _playRingtone() async {
    await _audioPlayer.setLoopMode(LoopMode.one);
    await _audioPlayer.setAsset('assets/audio/ringtone.wav');
    _audioPlayer.play();
  }

  void _stopRingtone() {
    _audioPlayer.stop();
  }

  Future<void> startCall(User peer, bool isVideo) async {
    if (state != null) return; // Already in a call
    
    final peerService = ref.read(peerServiceProvider);
    
    // Check if connected
    if (!peerService.isConnected(peer.id)) {
      // Connect first
      ref.read(chatThreadsProvider.notifier).connectToPeer(peer.id);
      
      // Wait a bit to let it connect
      await Future.delayed(const Duration(seconds: 2));
      
      if (!peerService.isConnected(peer.id)) {
        // Still not connected
        state = CallSession(peer: peer, isVideo: isVideo, state: CallState.ended);
        _showFullCall();
        Future.delayed(const Duration(seconds: 2), () {
          endCall();
        });
        return;
      }
    }
    
    // Send signaling request
    final myProfile = ref.read(chatThreadsProvider.notifier).myName ?? 'Someone';
    peerService.sendCallRequest(peer.id, isVideo, myProfile);
    
    state = CallSession(peer: peer, isVideo: isVideo, state: CallState.ringing);
    _showFullCall();
    _playRingtone();
    
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': isVideo ? {'facingMode': 'user'} : false,
      });
      localRenderer.srcObject = _localStream;
      
      final mediaConnection = ref.read(peerServiceProvider).makeCall(peer.id, _localStream!);
      
      if (mediaConnection != null) {
        state = state!.copyWith(mediaConnection: mediaConnection);
        
        mediaConnection.on("stream").listen((remoteStream) {
          remoteRenderer.srcObject = remoteStream as MediaStream;
          setConnected();
        });
        
        mediaConnection.on("close").listen((_) {
          endCall();
        });
        
        _timeoutTimer?.cancel();
        _timeoutTimer = Timer(const Duration(seconds: 30), () {
          if (state?.state == CallState.ringing) {
            debugPrint('Call timed out after 30 seconds');
            endCall();
          }
        });
      } else {
        endCall(); // Could not make call
      }
    } catch (e) {
      debugPrint('Error starting call stream: $e');
      endCall();
    }
  }

  void _handleCallRequest(Map<String, dynamic> request) {
    if (state != null) return;
    
    final peerId = request['peerId'] as String;
    final callerName = request['callerName'] as String;
    final isVideo = request['isVideo'] as bool;
    
    // Check contacts for real avatar/color
    User? knownUser;
    final contacts = ref.read(contactsProvider).value;
    if (contacts != null) {
      knownUser = contacts.where((c) => c.id == peerId).firstOrNull;
    }
    
    final peer = knownUser ?? User(id: peerId, name: callerName, avatarIcon: 0xe491, avatarColor: 0xFF6750A4);
    
    state = CallSession(
      peer: peer,
      isVideo: isVideo,
      state: CallState.ringing,
    );
    
    _showFullCall();
    _playRingtone();
  }

  void _handleIncomingCall(MediaConnection mediaConnection) {
    if (state != null && state!.mediaConnection != null) {
      // Busy, reject or ignore
      mediaConnection.close();
      return;
    }
    
    // If state is not null but mediaConnection IS null, it means we got the call_request first!
    if (state != null && state!.mediaConnection == null && state!.peer.id == mediaConnection.peer) {
      state = state!.copyWith(mediaConnection: mediaConnection);
    } else {
      // Fallback if we didn't get call_request
      final peerId = mediaConnection.peer;
      User? knownUser;
      final contacts = ref.read(contactsProvider).value;
      if (contacts != null) {
        knownUser = contacts.where((c) => c.id == peerId).firstOrNull;
      }
      final peer = knownUser ?? User(id: peerId, name: 'Peer $peerId', avatarIcon: 0xe491, avatarColor: 0xFF6750A4);
      
      state = CallSession(
        peer: peer, 
        isVideo: true, // assume true until we check
        state: CallState.ringing,
        mediaConnection: mediaConnection,
      );
      
      _showFullCall();
      _playRingtone();
    }
    
    mediaConnection.on("close").listen((_) {
      endCall();
    });
  }

  Future<void> answerCall() async {
    if (state == null || state!.mediaConnection == null) return;
    
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': state!.isVideo ? {'facingMode': 'user'} : false,
      });
      localRenderer.srcObject = _localStream;
      
      state!.mediaConnection!.answer(_localStream!);
      
      state!.mediaConnection!.on("stream").listen((remoteStream) {
        remoteRenderer.srcObject = remoteStream as MediaStream;
        setConnected();
      });
    } catch (e) {
      debugPrint('Error answering call: $e');
      endCall();
    }
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
      _stopRingtone();
      _timeoutTimer?.cancel();
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
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _stopRingtone();
    
    if (state?.mediaConnection != null) {
      state!.mediaConnection!.close();
    }
    
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _localStream = null;
    
    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;
    
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
