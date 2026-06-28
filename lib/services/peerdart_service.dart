import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peerdart/peerdart.dart';
import 'package:abyss_chat/models/message.dart';
import 'package:uuid/uuid.dart';

class PeerDartService {
  Peer? _peer;
  final Map<String, DataConnection> _activeConnections = {};
  final Map<String, List<StreamSubscription>> _subscriptions = {};
  
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

  String? _myId;
  String? get myId => _myId;

  Future<void> initialize([String? customId]) async {
    _myId = customId ?? const Uuid().v4().substring(0, 8);
    _peer = Peer(id: _myId);

    _peer!.on("open").listen((id) {
      debugPrint('✅ Connected to Signaling Server. My ID: $id');
      if (!_connectionStatus.isClosed) _connectionStatus.add('Connected as $id');
    });

    _peer!.on("connection").listen((connection) {
      final DataConnection conn = connection as DataConnection;
      _setupConnection(conn);
    });

    _peer!.on("call").listen((call) {
      debugPrint('📞 Incoming call from ${call.peer}');
      if (!_incomingCalls.isClosed) _incomingCalls.add(call as MediaConnection);
    });

    _peer!.on("error").listen((err) {
      debugPrint('❌ Peer Error: $err');
      if (!_connectionStatus.isClosed) _connectionStatus.add('Error: $err');
    });
  }

  bool isConnected(String peerId) {
    return _activeConnections.containsKey(peerId) && _activeConnections[peerId]!.open;
  }

  void connectToPeer(String peerId) {
    if (_peer == null) return;
    if (_activeConnections.containsKey(peerId)) {
      if (_activeConnections[peerId]!.open) return;
      // Close stale connection to trigger cleanup
      _activeConnections[peerId]!.close();
      _cancelSubscriptions(peerId);
      _activeConnections.remove(peerId);
    }
    
    debugPrint('🔄 Attempting to connect to $peerId...');
    final conn = _peer!.connect(peerId);
    _setupConnection(conn);
  }

  void _cancelSubscriptions(String peerId) {
    if (_subscriptions.containsKey(peerId)) {
      for (final sub in _subscriptions[peerId]!) {
        sub.cancel();
      }
      _subscriptions.remove(peerId);
    }
  }

  void _setupConnection(DataConnection conn) {
    _cancelSubscriptions(conn.peer);
    final subs = <StreamSubscription>[];

    subs.add(conn.on("open").listen((_) {
      debugPrint('🤝 Data connection established with ${conn.peer}');
      _activeConnections[conn.peer] = conn;
      if (!_connectionStatus.isClosed) _connectionStatus.add('Connected to ${conn.peer}');
      if (!_connectionOpened.isClosed) _connectionOpened.add(conn.peer);
    }));

    subs.add(conn.on("data").listen((data) {
      try {
        final decoded = jsonDecode(data.toString());
        final type = decoded['type'];

        if (type == 'p2p_message') {
          final msg = Message.fromJson(decoded['payload']);
          if (!_incomingMessages.isClosed) _incomingMessages.add(msg);
          // Auto-send delivery receipt
          _sendPayload(conn.peer, {
            'type': 'delivery_receipt',
            'messageId': msg.id,
            'peerId': _myId,
          });
        } else if (type == 'delivery_receipt') {
          if (!_deliveryReceipts.isClosed) _deliveryReceipts.add(decoded);
        } else if (type == 'read_receipt') {
          if (!_readReceipts.isClosed) _readReceipts.add(decoded);
        } else if (type == 'typing') {
          if (!_typingIndicators.isClosed) _typingIndicators.add(decoded['peerId']);
        } else if (type == 'profile_sync') {
          if (!_profileSyncs.isClosed) _profileSyncs.add(decoded);
        } else if (type == 'call_request') {
          if (!_callRequests.isClosed) _callRequests.add(decoded);
        }
      } catch (e) {
        debugPrint('Error parsing incoming P2P data: $e');
      }
    }));

    subs.add(conn.on("close").listen((_) {
      debugPrint('🛑 Connection closed with ${conn.peer}');
      _activeConnections.remove(conn.peer);
      _cancelSubscriptions(conn.peer);
    }));

    subs.add(conn.on("error").listen((err) {
      debugPrint('❌ Connection error with ${conn.peer}: $err');
      _activeConnections.remove(conn.peer);
      _cancelSubscriptions(conn.peer);
    }));

    _subscriptions[conn.peer] = subs;
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
      connectToPeer(peerId);
      return false;
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
    
    for (final subs in _subscriptions.values) {
      for (final sub in subs) {
        sub.cancel();
      }
    }
    _subscriptions.clear();
  }
}
