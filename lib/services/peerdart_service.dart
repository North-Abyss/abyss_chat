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
  
  // Stream controller to broadcast incoming messages to Riverpod
  final StreamController<Message> _incomingMessages = StreamController<Message>.broadcast();
  Stream<Message> get onMessageReceived => _incomingMessages.stream;

  final StreamController<String> _connectionStatus = StreamController<String>.broadcast();
  Stream<String> get onConnectionStatus => _connectionStatus.stream;

  final StreamController<MediaConnection> _incomingCalls = StreamController<MediaConnection>.broadcast();
  Stream<MediaConnection> get onCallReceived => _incomingCalls.stream;

  String? _myId;
  String? get myId => _myId;

  /// Initializes the local peer with a specific UUID or generates one
  Future<void> initialize([String? customId]) async {
    _myId = customId ?? const Uuid().v4().substring(0, 8); // Short ID for ease of use
    
    // Connect to the free public PeerJS signaling server
    _peer = Peer(id: _myId);

    _peer!.on("open").listen((id) {
      debugPrint('✅ Connected to Signaling Server. My ID: $id');
      _connectionStatus.add('Connected as $id');
    });

    _peer!.on("connection").listen((connection) {
      final DataConnection conn = connection as DataConnection;
      _setupConnection(conn);
    });

    _peer!.on("call").listen((call) {
      debugPrint('📞 Incoming call from ${call.peer}');
      _incomingCalls.add(call as MediaConnection);
    });

    _peer!.on("error").listen((err) {
      debugPrint('❌ Peer Error: $err');
      _connectionStatus.add('Error: $err');
    });
  }

  /// Connects to a remote peer using their UUID
  void connectToPeer(String peerId) {
    if (_peer == null) return;
    
    debugPrint('🔄 Attempting to connect to $peerId...');
    final conn = _peer!.connect(peerId);
    _setupConnection(conn);
  }

  void _setupConnection(DataConnection conn) {
    conn.on("open").listen((_) {
      debugPrint('🤝 Data connection established with ${conn.peer}');
      _activeConnections[conn.peer] = conn;
      _connectionStatus.add('Connected to ${conn.peer}');
    });

    conn.on("data").listen((data) {
      debugPrint('📨 Received raw data from ${conn.peer}: $data');
      try {
        final decoded = jsonDecode(data.toString());
        if (decoded['type'] == 'p2p_message') {
          final msg = Message.fromJson(decoded['payload']);
          _incomingMessages.add(msg);
        }
      } catch (e) {
        debugPrint('Error parsing incoming P2P data: $e');
      }
    });

    conn.on("close").listen((_) {
      debugPrint('🛑 Connection closed with ${conn.peer}');
      _activeConnections.remove(conn.peer);
    });
  }

  /// Sends a message to a specific peer over the WebRTC Data Channel
  void sendMessage(String peerId, Message message) {
    final conn = _activeConnections[peerId];
    if (conn != null) {
      final payload = jsonEncode({
        'type': 'p2p_message',
        'payload': message.toJson(),
      });
      conn.send(payload);
      debugPrint('📤 Sent message to $peerId');
    } else {
      debugPrint('⚠️ Cannot send message. Not connected to $peerId');
      // For a robust app, we would attempt to reconnect here
      connectToPeer(peerId);
      // We might need to queue this message, but for now we just attempt connection
    }
  }

  /// Initiates a WebRTC media call to a peer
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
  }
}
