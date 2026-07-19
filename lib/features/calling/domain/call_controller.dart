// ==========================================
// Abyss Chat - Call Controller
// ==========================================
// Version: 1.2.0
// Description: 
//   Manages Voice and Video Call states, handles WebRTC peer connections,
//   negotiates media streams, and ensures flawless call synchronization
//   between devices.
// ==========================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:abyss_chat/features/contacts/domain/models/user.dart';
import 'package:abyss_chat/features/calling/presentation/screens/call_screen.dart';
import 'package:abyss_chat/features/chat/domain/chat_controller.dart';
import 'package:abyss_chat/features/contacts/domain/contacts_controller.dart';
import 'package:abyss_chat/network/mdns_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:abyss_chat/features/calling/domain/models/call_log.dart';

// Global navigator key to insert the overlay anywhere
final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

enum CallState { idle, ringing, connected, ended }

class CallSession {
  final List<User> peers;
  final bool isVideo;
  final CallState state;
  final DateTime? startTime;
  final Duration? currentDuration;
  final bool isGroup;

  CallSession({
    required this.peers,
    required this.isVideo,
    this.state = CallState.idle,
    this.startTime,
    this.currentDuration,
    this.isGroup = false,
  });

  CallSession copyWith({
    List<User>? peers,
    bool? isVideo,
    CallState? state, 
    DateTime? startTime, 
    Duration? currentDuration,
    bool? isGroup,
  }) {
    return CallSession(
      peers: peers ?? this.peers,
      isVideo: isVideo ?? this.isVideo,
      state: state ?? this.state,
      startTime: startTime ?? this.startTime,
      currentDuration: currentDuration ?? this.currentDuration,
      isGroup: isGroup ?? this.isGroup,
    );
  }
}

class CallNotifier extends Notifier<CallSession?> {
  OverlayEntry? _overlayEntry;
  Timer? _timer;
  MediaStream? _localStream;
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  AudioPlayer? _audioPlayer;
  Timer? _timeoutTimer;

  bool get _isAudioSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
           defaultTargetPlatform == TargetPlatform.iOS ||
           defaultTargetPlatform == TargetPlatform.macOS;
  }
  
  final StreamController<Map<String, dynamic>> _reactionStreamController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get reactionStream => _reactionStreamController.stream;
  
  final Map<String, dynamic> _activeConnections = {};
  final Map<String, RTCVideoRenderer> remoteRenderers = {};
  final Map<String, Map<String, bool>> remoteMediaStatus = {};

  bool get isLocalVideoEnabled => _localStream?.getVideoTracks().isNotEmpty == true ? _localStream!.getVideoTracks()[0].enabled : false;
  bool get isLocalAudioEnabled => _localStream?.getAudioTracks().isNotEmpty == true ? _localStream!.getAudioTracks()[0].enabled : false;

  @override
  CallSession? build() {
    _initLocalRenderer();
    if (_isAudioSupported) {
      _audioPlayer = AudioPlayer();
    }
    
    ref.onDispose(() {
      localRenderer.dispose();
      for (final r in remoteRenderers.values) {
        r.dispose();
      }
      _audioPlayer?.dispose();
    });
    
    // Subscribe to incoming calls from PeerDartService
    Future.microtask(() {
      final peerService = ref.read(peerServiceProvider);
      final lanService = ref.read(lanMessengerProvider);
      final localWebrtcService = ref.read(localWebrtcServiceProvider);
      
      peerService.onCallReceived.listen(_handleIncomingCall);
      localWebrtcService.onCallReceived.listen(_handleIncomingCall);
      
      peerService.onCallRequest.listen(_handleCallRequest);
      peerService.onCallEnded.listen(_handleCallEnded);
      peerService.onMediaStatus.listen(_handleMediaStatus);

      void handleTunneledSignal(Map<String, dynamic> msg) {
        switch (msg['type']) {
          case 'call_request':
            _handleCallRequest(msg);
            break;
          case 'call_ended':
            _handleCallEnded(msg['peerId'] as String);
            break;
          case 'call_accepted':
            _handleCallAccepted(msg['peerId'] as String);
            break;
          case 'media_status':
            _handleMediaStatus(msg);
            break;
          case 'reaction':
            _handleReaction(msg);
            break;
        }
      }
      
      lanService.onDataMessage.listen(handleTunneledSignal);
      peerService.onDataMessage.listen(handleTunneledSignal);
    });
    
    return null;
  }
  
  Future<void> _initLocalRenderer() async {
    await localRenderer.initialize();
  }

  void _playRingtone() async {
    if (_audioPlayer == null) return;
    try {
      await _audioPlayer!.setLoopMode(LoopMode.one);
      await _audioPlayer!.setAsset('assets/audio/ringtone.wav');
      _audioPlayer!.play();
    } catch (e) {
      debugPrint('Failed to play ringtone: $e');
    }
  }

  void _stopRingtone() {
    _audioPlayer?.stop();
  }

  Future<void> startCall(List<User> peers, bool isVideo, {bool isGroup = false}) async {
    if (state != null) return; // Already in a call
    
    final peerService = ref.read(peerServiceProvider);
    
    state = CallSession(peers: peers, isVideo: isVideo, state: CallState.ringing, isGroup: isGroup);
    _showFullCall();
    _playRingtone();
    
    try {
      try {
        _localStream = await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': isVideo ? (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) ? {'facingMode': 'user'} : true : false,
        });
      } catch (videoError) {
        debugPrint('Camera failed or locked. Falling back to Audio-only: $videoError');
        _localStream = await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': false,
        });
        state = state?.copyWith(isVideo: false); // Update state to audio-only
      }
      localRenderer.srcObject = _localStream;
      
      final myProfile = ref.read(chatThreadsProvider.notifier).myName ?? 'Someone';
      
      for (final peer in peers) {
        if (!peerService.isConnected(peer.id)) {
          ref.read(chatThreadsProvider.notifier).connectToPeer(peer.id);
        }
        
        // Send the call request via LAN and PeerJS metadata signaling
        final payload = {
          'type': 'call_request',
          'peerId': ref.read(chatThreadsProvider.notifier).myId,
          'callerName': myProfile,
          'isVideo': isVideo,
        };
        ref.read(lanMessengerProvider).sendCustomData(peer.id, payload);
        peerService.sendUrgentSignal(peer.id, payload);
      }
      
      _timeoutTimer?.cancel();
      _timeoutTimer = Timer(const Duration(seconds: 30), () {
        if (state?.state == CallState.ringing) {
          debugPrint('Call timed out after 30 seconds');
          endCall();
        }
      });
    } catch (e) {
      debugPrint('Error starting call stream: $e');
      endCall();
    }
  }

  void _setupMediaConnection(String peerId, dynamic mediaConnection) {
    _activeConnections[peerId] = mediaConnection;
    
    mediaConnection.on("stream").listen((remoteStream) async {
      if (!remoteRenderers.containsKey(peerId)) {
        final renderer = RTCVideoRenderer();
        await renderer.initialize();
        remoteRenderers[peerId] = renderer;
      }
      remoteRenderers[peerId]!.srcObject = remoteStream as MediaStream;
      
      if (_localStream != null) {
        setConnected();
      }
      
      // Force UI update
      state = state?.copyWith();
    });
    
    mediaConnection.on("close").listen((_) {
      _handlePeerDisconnected(peerId);
    });
    
    mediaConnection.on("error").listen((_) {
      _handlePeerDisconnected(peerId);
    });

    // Monitor ICE connection state for drops
    final pc = mediaConnection.peerConnection;
    if (pc != null && pc is RTCPeerConnection) {
      pc.onIceConnectionState = (RTCIceConnectionState state) {
        if (state == RTCIceConnectionState.RTCIceConnectionStateFailed || 
            state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
            state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
          debugPrint('🧊 ICE Connection state failed for $peerId: $state');
          _handlePeerDisconnected(peerId);
        }
      };
    }
  }

  void _handlePeerDisconnected(String peerId) {
    _activeConnections.remove(peerId);
    
    if (remoteRenderers.containsKey(peerId)) {
      remoteRenderers[peerId]!.srcObject = null;
      remoteRenderers[peerId]!.dispose();
      remoteRenderers.remove(peerId);
    }
    
    remoteMediaStatus.remove(peerId);

    if (state != null) {
      final remainingPeers = state!.peers.where((p) => p.id != peerId).toList();
      if (remainingPeers.isEmpty) {
        endCall(local: false);
      } else {
        state = state!.copyWith(peers: remainingPeers);
      }
    }
  }

  void _handleCallEnded(String peerId) {
    if (state != null && state!.peers.any((p) => p.id == peerId)) {
      _handlePeerDisconnected(peerId);
    }
  }
  void _handleCallAccepted(String peerId) {
    if (state != null && state!.state == CallState.ringing && state!.peers.any((p) => p.id == peerId)) {
      setConnected();
    }
  }

  void _handleMediaStatus(Map<String, dynamic> status) {
    final peerId = status['peerId'] as String;
    if (state != null && state!.peers.any((p) => p.id == peerId)) {
      remoteMediaStatus[peerId] = {
        'videoEnabled': status['videoEnabled'] as bool,
        'audioEnabled': status['audioEnabled'] as bool,
      };
      state = state!.copyWith(); // force UI update
    }
  }

  void _handleReaction(Map<String, dynamic> msg) {
    if (state != null) {
      _reactionStreamController.add(msg);
    }
  }

  void sendReaction(String emoji) {
    if (state == null) return;
    
    final msg = {
      'type': 'reaction',
      'emoji': emoji,
      'peerId': 'local', // Or use actual local ID if available
    };
    
    // Broadcast to all remote peers
    for (final peer in state!.peers) {
      ref.read(peerServiceProvider).sendCustomData(peer.id, msg);
    }
    
    // Show locally immediately
    _reactionStreamController.add(msg);
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
      peers: [peer],
      isVideo: isVideo,
      state: CallState.ringing,
    );
    
    _showFullCall(isIncoming: true);
    _playRingtone();
  }

  void _handleIncomingCall(dynamic mediaConnection) {
    final peerId = mediaConnection.peer;
    
    if (_activeConnections.containsKey(peerId)) {
      debugPrint('⏳ Already have active connection for $peerId. Ignoring duplicate media stream.');
      mediaConnection.close();
      return;
    }
    
    if (state != null) {
      // Are we already in a call? If it's a new peer and we're in a group call, maybe accept?
      // For now, if we're ringing and it's from the person calling us, we accept it when user answers.
      // Or if we are already connected, we can automatically accept it if it's part of the group.
      
      if (state!.state == CallState.connected && state!.isGroup) {
         // Auto-answer incoming from a group member
         if (_localStream != null) {
           _activeConnections[peerId] = mediaConnection;
           mediaConnection.answer(_localStream!);
           _setupMediaConnection(peerId, mediaConnection);
         }
      } else if (state!.state == CallState.connected && state!.peers.any((p) => p.id == peerId)) {
         // Auto-answer incoming if we already clicked Accept but the media connection arrived late
         if (_localStream != null) {
           _activeConnections[peerId] = mediaConnection;
           mediaConnection.answer(_localStream!);
           _setupMediaConnection(peerId, mediaConnection);
         }
      } else if (state!.state == CallState.ringing && state!.peers.any((p) => p.id == peerId)) {
        // We received the media connection. If we also initiated a call (localStream != null), auto-answer it to resolve simultaneous calls.
        _activeConnections[peerId] = mediaConnection;
        _setupMediaConnection(peerId, mediaConnection);
        
        if (_localStream != null) {
          mediaConnection.answer(_localStream!);
          setConnected();
        }
      } else {
        // Busy
        mediaConnection.close();
      }
      return;
    }
    
    // Fallback if we didn't get call_request
    User? knownUser;
    final contacts = ref.read(contactsProvider).value;
    if (contacts != null) {
      knownUser = contacts.where((c) => c.id == peerId).firstOrNull;
    }
    final peer = knownUser ?? User(id: peerId, name: 'Peer $peerId', avatarIcon: 0xe491, avatarColor: 0xFF6750A4);
    
    state = CallSession(
      peers: [peer], 
      isVideo: true, // assume true until we check
      state: CallState.ringing,
    );
    
    _activeConnections[peerId] = mediaConnection;
    _setupMediaConnection(peerId, mediaConnection);
    
    _showFullCall(isIncoming: true);
    _playRingtone();
  }

  Future<void> answerCall() async {
    if (state == null) return;
    
    try {
      try {
        _localStream = await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': state!.isVideo ? (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) ? {'facingMode': 'user'} : true : false,
        });
      } catch (videoError) {
        debugPrint('Camera failed or locked. Falling back to Audio-only: $videoError');
        _localStream = await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': false,
        });
        state = state?.copyWith(isVideo: false); // Update state to audio-only
      }
      localRenderer.srcObject = _localStream;
      
      final peerService = ref.read(peerServiceProvider);
      final localWebrtcService = ref.read(localWebrtcServiceProvider);
      
      for (final peer in state!.peers) {
        if (_activeConnections.containsKey(peer.id)) {
          // Backward compatibility / simultaneous calls
          _activeConnections[peer.id]!.answer(_localStream!);
        } else {
          // FLIP THE HOST: The Callee initiates the stream!
          dynamic mediaConnection;
          
          final mdnsPeers = ref.read(nearbyPeersProvider);
          var lanPeer = mdnsPeers.where((p) => p.id == peer.id).firstOrNull;
          
          if (lanPeer == null || lanPeer.ipAddress == null) {
            final contacts = await ref.read(contactsProvider.future);
            lanPeer = contacts.where((c) => c.id == peer.id).firstOrNull;
          }
          
          final isLocal = lanPeer != null && lanPeer.ipAddress != null;
          
          if (isLocal) {
            mediaConnection = await localWebrtcService.makeCall(peer.id, _localStream!);
          } else {
            mediaConnection = peerService.makeCall(peer.id, _localStream!);
          }
          
          if (mediaConnection != null) {
            _setupMediaConnection(peer.id, mediaConnection);
          }
        }
        final payload = {'type': 'call_accepted', 'peerId': peerService.myId ?? 'local'};
        ref.read(lanMessengerProvider).sendCustomData(peer.id, payload);
        peerService.sendUrgentSignal(peer.id, payload);
      }
      
      setConnected();
    } catch (e) {
      debugPrint('Error answering call: $e');
      endCall();
    }
  }

  void _showFullCall({bool isIncoming = false}) {
    debugPrint('📱 _showFullCall called, isIncoming: $isIncoming');
    if (_overlayEntry != null) return;
    
    final navState = globalNavigatorKey.currentState;
    debugPrint('📱 navState: $navState');
    final context = navState?.overlay?.context;
    debugPrint('📱 context: $context');
    
    if (context == null || state == null) {
      debugPrint('📱 Failed to show call: context=$context, state=$state');
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => CallScreen(isIncoming: isIncoming), 
    );
    globalNavigatorKey.currentState?.overlay?.insert(_overlayEntry!);
    debugPrint('📱 Overlay inserted successfully!');
  }

  void setConnected() {
    if (state != null && state!.state != CallState.connected) {
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

  Future<void> toggleVideo(bool enabled) async {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      
      if (enabled) {
        // We want to turn it back on
        if (videoTracks.isEmpty || !videoTracks[0].enabled) {
          try {
            final newStream = await navigator.mediaDevices.getUserMedia({
              'audio': false,
              'video': (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) ? {'facingMode': 'user'} : true,
            });
            final newTrack = newStream.getVideoTracks().first;
            
            // Remove old dead tracks
            for (final track in videoTracks.toList()) {
              _localStream!.removeTrack(track);
            }
            
            _localStream!.addTrack(newTrack);
            
            // Replace track in active peer connections
            for (final conn in _activeConnections.values) {
              final senders = await conn.peerConnection?.getSenders();
              if (senders != null) {
                final videoSender = senders.where((s) => s.track?.kind == 'video').firstOrNull;
                if (videoSender != null) {
                  await videoSender.replaceTrack(newTrack);
                }
              }
            }
            
            // Re-bind to local renderer
            localRenderer.srcObject = _localStream;
          } catch (e) {
            debugPrint('Failed to restart camera: $e');
          }
        } else {
          videoTracks[0].enabled = true;
        }
      } else {
        // We want to turn it off (kill hardware)
        if (videoTracks.isNotEmpty) {
          videoTracks[0].enabled = false;
          videoTracks[0].stop(); // Physically turn off camera LED
        }
      }
    }
    
    if (state != null) {
      final peerService = ref.read(peerServiceProvider);
      final audioEnabled = _localStream?.getAudioTracks().isNotEmpty == true ? _localStream!.getAudioTracks()[0].enabled : true;
      for (final peer in state!.peers) {
        peerService.sendMediaStatus(peer.id, videoEnabled: enabled, audioEnabled: audioEnabled);
      }
    }
  }

  Future<void> toggleAudio(bool enabled) async {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      
      if (enabled) {
        // We want to turn it back on
        if (audioTracks.isEmpty || !audioTracks[0].enabled) {
          try {
            final newStream = await navigator.mediaDevices.getUserMedia({
              'audio': true,
              'video': false,
            });
            final newTrack = newStream.getAudioTracks().first;
            
            // Remove old dead tracks
            for (final track in audioTracks.toList()) {
              _localStream!.removeTrack(track);
            }
            
            _localStream!.addTrack(newTrack);
            
            // Replace track in active peer connections
            for (final conn in _activeConnections.values) {
              final senders = await conn.peerConnection?.getSenders();
              if (senders != null) {
                final audioSender = senders.where((s) => s.track?.kind == 'audio').firstOrNull;
                if (audioSender != null) {
                  await audioSender.replaceTrack(newTrack);
                }
              }
            }
          } catch (e) {
            debugPrint('Failed to restart mic: $e');
          }
        } else {
          audioTracks[0].enabled = true;
        }
      } else {
        // We want to turn it off (kill hardware)
        if (audioTracks.isNotEmpty) {
          audioTracks[0].enabled = false;
          audioTracks[0].stop(); // Physically release mic permission
        }
      }
    }

    if (state != null) {
      final peerService = ref.read(peerServiceProvider);
      final videoEnabled = _localStream?.getVideoTracks().isNotEmpty == true ? _localStream!.getVideoTracks()[0].enabled : true;
      for (final peer in state!.peers) {
        peerService.sendMediaStatus(peer.id, videoEnabled: videoEnabled, audioEnabled: enabled);
      }
    }
  }

  void endCall({bool local = true}) {
    if (local && state != null) {
      final peerService = ref.read(peerServiceProvider);
      for (final peer in state!.peers) {
        peerService.sendCallEnded(peer.id);
        final payload = {'type': 'call_ended', 'peerId': peerService.myId ?? 'local'};
        peerService.sendUrgentSignal(peer.id, payload);
      }
      
      // Brief delay to ensure data channel message transmits before tearing down
      Future.delayed(const Duration(milliseconds: 300), _cleanupCallConnections);
    } else {
      _cleanupCallConnections();
    }
  }

  void _cleanupCallConnections() {
    _timer?.cancel();
    _timer = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _stopRingtone();
    
    for (final conn in _activeConnections.values) {
      conn.close();
    }
    _activeConnections.clear();
    
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _localStream = null;
    
    localRenderer.srcObject = null;
    
    for (final renderer in remoteRenderers.values) {
      renderer.srcObject = null;
      renderer.dispose();
    }
    remoteRenderers.clear();
    
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
    if (state == null) return;
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
    }
    
    final context = globalNavigatorKey.currentState?.overlay?.context;
    if (context == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => const CallScreen(isIncoming: false),
    );
    globalNavigatorKey.currentState?.overlay?.insert(_overlayEntry!);
  }
}

final callProvider = NotifierProvider<CallNotifier, CallSession?>(() => CallNotifier());

class MiniCallOverlay extends ConsumerStatefulWidget {
  const MiniCallOverlay({super.key});

  @override
  ConsumerState<MiniCallOverlay> createState() => _MiniCallOverlayState();
}

class _MiniCallOverlayState extends ConsumerState<MiniCallOverlay> {
  Offset position = const Offset(20, 60);
  double width = 130;
  double height = 190;

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callProvider);
    if (callState == null) return const SizedBox.shrink();

    final isConnected = callState.state == CallState.connected;
    final remoteRenderers = ref.read(callProvider.notifier).remoteRenderers;

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            position += details.delta;
          });
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Maximize Area & Video Content
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => ref.read(callProvider.notifier).maximizeCall(),
                    behavior: HitTestBehavior.opaque,
                    child: _buildVideoContent(callState, isConnected, remoteRenderers),
                  ),
                ),
                
                // Call Controls
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (callState.isVideo)
                        GestureDetector(
                          onTap: () {
                            final notifier = ref.read(callProvider.notifier);
                            final currentVideo = notifier.isLocalVideoEnabled;
                            notifier.toggleVideo(!currentVideo);
                            // Force rebuild since toggleVideo doesn't rebuild state anymore
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ref.read(callProvider.notifier).isLocalVideoEnabled ? Colors.white24 : Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              ref.read(callProvider.notifier).isLocalVideoEnabled ? Icons.videocam : Icons.videocam_off,
                              color: ref.read(callProvider.notifier).isLocalVideoEnabled ? Colors.white : Colors.black,
                              size: 16,
                            ),
                          ),
                        ),
                      GestureDetector(
                        onTap: () {
                          final notifier = ref.read(callProvider.notifier);
                          final currentAudio = notifier.isLocalAudioEnabled;
                          notifier.toggleAudio(!currentAudio);
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ref.read(callProvider.notifier).isLocalAudioEnabled ? Colors.white24 : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            ref.read(callProvider.notifier).isLocalAudioEnabled ? Icons.mic : Icons.mic_off,
                            color: ref.read(callProvider.notifier).isLocalAudioEnabled ? Colors.white : Colors.black,
                            size: 16,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          ref.read(callProvider.notifier).endCall();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call_end, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Resize Handle
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        width = (width + details.delta.dx).clamp(130.0, MediaQuery.of(context).size.width - 40);
                        height = (height + details.delta.dy).clamp(190.0, MediaQuery.of(context).size.height - 100);
                      });
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: const Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.open_in_full, size: 14, color: Colors.white54),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContent(CallSession callState, bool isConnected, Map<String, RTCVideoRenderer> remoteRenderers) {
    if (!isConnected || !callState.isVideo) {
      return _buildPlaceholder(callState.peers.isNotEmpty ? callState.peers.first.name : 'Unknown');
    }

    if (width > 250 && remoteRenderers.length > 1) {
      // Show Grid
      final count = remoteRenderers.length;
      int columns = count > 4 ? 3 : 2;
      return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          childAspectRatio: count == 1 ? 0.75 : 1.0,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: remoteRenderers.length,
        itemBuilder: (context, index) {
          final peerId = remoteRenderers.keys.elementAt(index);
          final renderer = remoteRenderers[peerId]!;
          if (!(ref.read(callProvider.notifier).remoteMediaStatus[peerId]?['videoEnabled'] ?? true)) {
             return _buildPlaceholder('Participant');
          }
          return RTCVideoView(renderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover);
        },
      );
    } else {
      // Show Single Active Speaker
      final activeRenderer = remoteRenderers.isNotEmpty ? remoteRenderers.values.first : null;
      if (activeRenderer != null && (ref.read(callProvider.notifier).remoteMediaStatus[callState.peers.first.id]?['videoEnabled'] ?? true)) {
        return RTCVideoView(
          activeRenderer,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        );
      } else {
        return _buildPlaceholder(callState.peers.isNotEmpty ? callState.peers.first.name : 'Unknown');
      }
    }
  }

  Widget _buildPlaceholder(String name) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person, color: Colors.white54, size: 48),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class CallLogsNotifier extends AsyncNotifier<List<CallLog>> {
  @override
  Future<List<CallLog>> build() async {
    return []; // We will fix the implementation during import fixes
  }

  void addCallLog(CallLog log) {
    if (!state.hasValue) return;
    final logs = List<CallLog>.from(state.value!);
    logs.insert(0, log);
    state = AsyncData(logs);
  }
}

final callLogsProvider = AsyncNotifierProvider<CallLogsNotifier, List<CallLog>>(() => CallLogsNotifier());
