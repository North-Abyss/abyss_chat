import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peerdart/peerdart.dart';
import 'package:abyss_chat/models/message.dart';
import 'package:uuid/uuid.dart';
import 'package:abyss_chat/constants/app_constants.dart';

// --- SERVICE DEFINITION ---

class PeerDartService {
  Peer? _peer;
  final Map<String, DataConnection> _activeConnections = {};
  final Set<String> _pendingConnections = {};
  final Map<String, List<StreamSubscription>> _subscriptions = {};
  bool _isDisposed = false;
  bool _isPeerOpen = false;
  final List<String> _connectionQueue = [];
  int _reconnectAttempts = 0;
  final Map<String, Timer> _pingTimers = {};
  final Map<String, int> _pingMisses = {};
  
  // Stream controllers for different events
  final StreamController<Message> _incomingMessages = StreamController<Message>.broadcast();
  Stream<Message> get onMessageReceived => _incomingMessages.stream;

  final StreamController<String> _connectionStatus = StreamController<String>.broadcast();
  Stream<String> get onConnectionStatus => _connectionStatus.stream;

  final StreamController<MediaConnection> _incomingCalls = StreamController<MediaConnection>.broadcast();
  Stream<MediaConnection> get onCallReceived => _incomingCalls.stream;

  // New streams for receipts and typing
  final StreamController<Map<String, dynamic>> _deliveryReceipts = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onDeliveryReceipt => _deliveryReceipts.stream;

  final StreamController<Map<String, dynamic>> _readReceipts = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onReadReceipt => _readReceipts.stream;

  final StreamController<String> _typingIndicators = StreamController<String>.broadcast();
  Stream<String> get onTypingReceived => _typingIndicators.stream;

  final StreamController<String> _connectionOpened = StreamController<String>.broadcast();
  Stream<String> get onConnectionOpened => _connectionOpened.stream;

  final StreamController<Map<String, dynamic>> _profileSyncs = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onProfileSyncReceived => _profileSyncs.stream;

  final StreamController<Map<String, dynamic>> _callRequests = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onCallRequest => _callRequests.stream;

  final StreamController<String> _callEnded = StreamController<String>.broadcast();
  Stream<String> get onCallEnded => _callEnded.stream;

  final StreamController<Map<String, dynamic>> _mediaStatus = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onMediaStatus => _mediaStatus.stream;

  final StreamController<Map<String, dynamic>> _dataMessages = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onDataMessage => _dataMessages.stream;

  String? _myId;
  String? get myId => _myId;

  Future<void> initialize(String? customId) async {
    if (_isDisposed) return;
    _myId = customId ?? const Uuid().v4();
    _isPeerOpen = false;
    
    // Inject reliable free TURN server (OpenRelay) to bypass strict NAT/Hairpinning
    // without requiring users to change browser mDNS flags
    final customConfig = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
        {'urls': 'stun:stun2.l.google.com:19302'},
        {'urls': 'stun:stun3.l.google.com:19302'},
        {'urls': 'stun:stun4.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    };

    _peer = Peer(
      id: _myId,
      options: PeerOptions(config: customConfig),
    );

    _peer!.on("open").listen((id) {
      if (_isDisposed) return;
      _isPeerOpen = true;
      _reconnectAttempts = 0;
      debugPrint('✅ Connected to Signaling Server. My ID: $id');
      Future.microtask(() {
        if (!_connectionStatus.isClosed) _connectionStatus.add('Connected as $id');
      });
      
      for (final peerId in _connectionQueue) {
         connectToPeer(peerId);
      }
      _connectionQueue.clear();
    });

    _peer!.on("connection").listen((connection) {
      if (_isDisposed) return;
      final DataConnection conn = connection as DataConnection;
      _setupConnection(conn);
      
      // Process any urgent signals embedded in the connection metadata
      try {
        dynamic meta = conn.metadata;
        if (meta is String) {
          meta = jsonDecode(meta);
        }
        if (meta != null && meta is Map && meta.containsKey('urgent_signal')) {
          final decoded = meta['urgent_signal'];
          if (decoded is Map) {
            _processDecodedPayload(conn.peer, Map<String, dynamic>.from(decoded));
          } else if (decoded is String) {
            _processDecodedPayload(conn.peer, jsonDecode(decoded));
          }
        }
      } catch (e) {
        debugPrint('Failed to process urgent signal from metadata: $e');
      }
    });

    _peer!.on("disconnected").listen((_) {
      if (_isDisposed) return;
      _isPeerOpen = false;
      _reconnectAttempts++;
      final backoffSeconds = (1 << _reconnectAttempts).clamp(1, 30);
      debugPrint('⚠️ Disconnected from signaling server. Reconnecting in $backoffSeconds seconds... (Attempt $_reconnectAttempts)');
      
      Future.delayed(Duration(seconds: backoffSeconds), () {
        if (_isDisposed) return;
        if (!_peer!.destroyed && _peer!.disconnected) {
          _peer!.reconnect();
        }
      });
    });

    _peer!.on("call").listen((call) {
      if (_isDisposed) return;
      final mediaCall = call as MediaConnection;
      debugPrint('📞 Incoming call from ${mediaCall.peer}');
      if (!_incomingCalls.isClosed) _incomingCalls.add(mediaCall);
    });

    _peer!.on("error").listen((err) {
      if (_isDisposed) return;
      debugPrint('❌ Peer Error: $err');
      
      // Handle hot-reload zombie connections
      if (err.toString().toLowerCase().contains('taken')) {
        debugPrint('ID is taken. Server still holds the zombie connection. Retrying in ${AppConstants.webrtcReconnectDelay.inSeconds} seconds...');
        Future.delayed(AppConstants.webrtcReconnectDelay, () {
          if (_isDisposed) return;
          if (!_connectionStatus.isClosed) {
            _peer?.dispose();
            initialize(_myId); // Retry initialization
          }
        });
      }
      
      Future.microtask(() {
        if (!_connectionStatus.isClosed) _connectionStatus.add('Error: $err');
      });
    });
  }

  bool isConnected(String peerId) {
    return _activeConnections.containsKey(peerId) && _activeConnections[peerId]!.open;
  }

  void connectToPeer(String peerId, {dynamic metadata}) {
    if (_peer == null) return;

    if (_peer!.disconnected || _peer!.destroyed) {
       debugPrint('Peer is disconnected or destroyed. Re-initializing...');
       if (_peer!.destroyed) {
         initialize(_myId).then((_) {
            // It will be queued because _isPeerOpen is false
            connectToPeer(peerId);
         });
       } else {
         _peer!.reconnect();
         Future.delayed(AppConstants.webrtcSignalingTimeout, () {
           connectToPeer(peerId);
         });
       }
       return;
    }

    if (!_isPeerOpen) {
      if (!_connectionQueue.contains(peerId)) {
        debugPrint('⏳ Queuing connection to $peerId until signaling server is ready.');
        _connectionQueue.add(peerId);
      }
      return;
    }

    if (_activeConnections.containsKey(peerId)) {
      if (_activeConnections[peerId]!.open) return;
      // Close stale connection to trigger cleanup asynchronously to avoid bad state
      final staleConn = _activeConnections.remove(peerId);
      Future.microtask(() {
        try {
          if (staleConn != null) {
            staleConn.close();
          }
        } catch (e) {
          debugPrint('Suppressed close error: $e');
        }
      });
      _cancelSubscriptions(peerId);
    }
    
    if (_pendingConnections.contains(peerId)) {
      debugPrint('⏳ Already attempting to connect to $peerId. Ignoring duplicate request.');
      return;
    }
    
    _pendingConnections.add(peerId);
    debugPrint('🔄 Attempting to connect to $peerId...');
    try {
      final options = metadata != null ? PeerConnectOption(metadata: metadata) : null;
      final conn = _peer!.connect(peerId, options: options);
      _setupConnection(conn);
    } catch (e) {
      _pendingConnections.remove(peerId);
      debugPrint('❌ Peer connect exception: $e');
      if (e.toString().contains('disconnected')) {
        _peer!.reconnect();
        // Wait and retry
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_peer != null && !_peer!.disconnected) {
            connectToPeer(peerId);
          }
        });
      }
    }
  }

  void _cancelSubscriptions(String peerId) {
    if (_subscriptions.containsKey(peerId)) {
      for (final sub in _subscriptions[peerId]!) {
        sub.cancel();
      }
      _subscriptions.remove(peerId);
    }
    _pingTimers[peerId]?.cancel();
    _pingTimers.remove(peerId);
    _pingMisses.remove(peerId);
  }

  // --- CONNECTION MANAGEMENT ---
  void _setupConnection(DataConnection conn) {
    _cancelSubscriptions(conn.peer);
    final subs = <StreamSubscription>[];

    subs.add(conn.on("open").listen((_) {
      if (_activeConnections.containsKey(conn.peer) && _activeConnections[conn.peer] != conn) {
        try { _activeConnections[conn.peer]?.close(); } catch (_) {}
      }
      debugPrint('🤝 Data connection established with ${conn.peer}');
      _activeConnections[conn.peer] = conn;
      _pendingConnections.remove(conn.peer);
      
      // Start ping/pong health check
      _pingMisses[conn.peer] = 0;
      _pingTimers[conn.peer]?.cancel();
      _pingTimers[conn.peer] = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (!_activeConnections.containsKey(conn.peer) || !_activeConnections[conn.peer]!.open) {
          timer.cancel();
          return;
        }
        
        _pingMisses[conn.peer] = (_pingMisses[conn.peer] ?? 0) + 1;
        if ((_pingMisses[conn.peer] ?? 0) > 3) {
          debugPrint('⏱️ Ping timeout for ${conn.peer}, forcing disconnect');
          conn.close();
          timer.cancel();
          return;
        }
        
        _sendPayload(conn.peer, {'type': 'ping'});
      });

      Future.microtask(() {
        if (!_connectionStatus.isClosed) _connectionStatus.add('Connected to ${conn.peer}');
      });
      if (!_connectionOpened.isClosed) _connectionOpened.add(conn.peer);
    }));

    subs.add(conn.on("data").listen((data) {
      try {
        final decoded = jsonDecode(data.toString());
        _processDecodedPayload(conn.peer, decoded);
      } catch (e) {
        debugPrint('Error parsing incoming P2P data: $e');
      }
    }));

    subs.add(conn.on("close").listen((_) {
      debugPrint('🛑 Connection closed with ${conn.peer}');
      _activeConnections.remove(conn.peer);
      _pendingConnections.remove(conn.peer);
      _cancelSubscriptions(conn.peer);
    }));

    subs.add(conn.on("error").listen((err) {
      debugPrint('❌ Connection error with ${conn.peer}: $err');
      _activeConnections.remove(conn.peer);
      _pendingConnections.remove(conn.peer);
      _cancelSubscriptions(conn.peer);
    }));

    _subscriptions[conn.peer] = subs;
  }
  
  void _processDecodedPayload(String sourcePeerId, Map<String, dynamic> decoded) {
    final type = decoded['type'];

    if (type == 'p2p_message') {
      final msg = Message.fromJson(decoded['payload']);
      // Fallback: If we don't have the connection object handy in this scope (e.g. from metadata), we rely on msg.senderId
      msg.networkSenderId = msg.senderId; 
      if (!_incomingMessages.isClosed) _incomingMessages.add(msg);
      // Auto-send delivery receipt
      _sendPayload(msg.senderId, {
        'type': 'delivery_receipt',
        'messageId': msg.id,
        'peerId': _myId,
      });
    } else if (type == 'delivery_receipt') {
      if (!_deliveryReceipts.isClosed) _deliveryReceipts.add(decoded);
    } else if (type == 'read_receipt') {
      if (!_readReceipts.isClosed) _readReceipts.add(decoded);
    } else if (type == 'call_ended') {
      if (!_callEnded.isClosed) _callEnded.add(decoded['peerId']);
    } else if (type == 'media_status') {
      if (!_mediaStatus.isClosed) _mediaStatus.add(decoded);
    } else if (type == 'typing') {
      if (!_typingIndicators.isClosed) _typingIndicators.add(decoded['peerId']);
    } else if (type == 'profile_sync') {
      if (!_profileSyncs.isClosed) _profileSyncs.add(decoded);
    } else if (type == 'call_request') {
      if (!_callRequests.isClosed) _callRequests.add(decoded);
    } else if (type == 'ping') {
      // Respond with pong to keep connection alive
      _sendPayload(sourcePeerId, {'type': 'pong'});
    } else if (type == 'pong') {
      _pingMisses[sourcePeerId] = 0;
    } else {
      // Broadcast unhandled raw JSON for generic listeners (e.g., custom call signaling)
      if (!_dataMessages.isClosed) _dataMessages.add(decoded);
    }
  }

  bool _sendPayload(String peerId, Map<String, dynamic> payload) {
    final conn = _activeConnections[peerId];
    if (conn != null && conn.open) {
      conn.send(jsonEncode(payload));
      return true;
    }
    return false;
  }

  bool sendMessage(String peerId, Message message) {
    final success = _sendPayload(peerId, {
      'type': 'p2p_message',
      'payload': message.toJson(),
    });
    
    if (success) {
      debugPrint('📤 Sent message to $peerId via WebRTC');
      return true;
    } else {
      debugPrint('⚠️ Cannot send message. Not connected to $peerId');
      return false;
    }
  }

  bool sendCustomData(String peerId, Map<String, dynamic> payload) {
    final success = _sendPayload(peerId, payload);
    return success;
  }

  /// Sends a payload, and if the data channel is closed, it immediately initiates a 
  /// new connection with the payload embedded in the PeerJS SDP metadata.
  /// This ensures delivery even if ICE candidates fail to resolve (Native->Web on LAN).
  void sendUrgentSignal(String peerId, Map<String, dynamic> payload) {
    final success = _sendPayload(peerId, payload);
    if (!success && _peer != null) {
      debugPrint('🚀 Sending urgent signal via PeerJS metadata to $peerId');
      connectToPeer(peerId, metadata: jsonEncode({'urgent_signal': payload}));
    }
  }

  void sendReadReceipt(String peerId, List<String> messageIds) {
    _sendPayload(peerId, {
      'type': 'read_receipt',
      'messageIds': messageIds,
      'peerId': _myId,
    });
  }

  void sendCallRequest(String peerId, bool isVideo, String callerName) {
    _sendPayload(peerId, {
      'type': 'call_request',
      'peerId': _myId,
      'callerName': callerName,
      'isVideo': isVideo,
    });
  }

  void sendCallEnded(String peerId) {
    _sendPayload(peerId, {
      'type': 'call_ended',
      'peerId': _myId,
    });
  }

  void sendMediaStatus(String peerId, {required bool videoEnabled, required bool audioEnabled}) {
    _sendPayload(peerId, {
      'type': 'media_status',
      'peerId': _myId,
      'videoEnabled': videoEnabled,
      'audioEnabled': audioEnabled,
    });
  }

  void sendTypingIndicator(String peerId) {
    _sendPayload(peerId, {
      'type': 'typing',
      'peerId': _myId,
    });
  }

  void sendProfileSync(String peerId, Map<String, dynamic> profileData) {
    _sendPayload(peerId, {
      'type': 'profile_sync',
      'peerId': _myId,
      'profile': profileData,
    });
  }

  MediaConnection? makeCall(String peerId, MediaStream stream) {
    if (_peer == null) return null;
    debugPrint('🎥 Initiating call to $peerId...');
    return _peer!.call(peerId, stream);
  }

  void dispose() {
    _isDisposed = true;
    _peer?.dispose();
    _incomingMessages.close();
    _connectionStatus.close();
    _incomingCalls.close();
    _deliveryReceipts.close();
    _readReceipts.close();
    _typingIndicators.close();
    _connectionOpened.close();
    _profileSyncs.close();
    _callRequests.close();
    _callEnded.close();
    _mediaStatus.close();
    
    for (final subs in _subscriptions.values) {
      for (final sub in subs) {
        sub.cancel();
      }
    }
    _subscriptions.clear();
  }
}
