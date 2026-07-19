import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:abyss_chat/features/chat/domain/models/message.dart';
import 'package:abyss_chat/core/constants/app_constants.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// --- SERVICE DEFINITION (WEB STUB) ---

class LanMessenger {
  final Map<String, WebSocketChannel> _activeSockets = {};
  String? _myId;
  
  // Stream controllers to match the IO implementation
  final StreamController<Message> _incomingMessages = StreamController<Message>.broadcast();
  Stream<Message> get onMessageReceived => _incomingMessages.stream;

  final StreamController<String> _connectionStatus = StreamController<String>.broadcast();
  Stream<String> get onConnectionStatus => _connectionStatus.stream;

  final StreamController<Map<String, dynamic>> _deliveryReceipts = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onDeliveryReceipt => _deliveryReceipts.stream;

  final StreamController<Map<String, dynamic>> _readReceipts = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onReadReceipt => _readReceipts.stream;

  final StreamController<String> _typingIndicators = StreamController<String>.broadcast();
  Stream<String> get onTypingReceived => _typingIndicators.stream;

  final StreamController<Map<String, dynamic>> _dataMessages = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onDataMessage => _dataMessages.stream;

  int get serverPort => AppConstants.lanServerPort;

  Future<int> startServer(String myId) async {
    _myId = myId;
    // LAN Server is not supported on Web (browsers cannot listen on ports)
    return 0;
  }

  Future<bool> connectToPeer(String peerId, String ipAddress, int port) async {
    if (_activeSockets.containsKey(peerId)) {
      debugPrint('Already connected to $peerId over LAN');
      return true;
    }

    try {
      debugPrint('🔄 Attempting LAN WebSocket connection to ws://$ipAddress:$port');
      final uri = Uri.parse('ws://$ipAddress:$port');
      final channel = WebSocketChannel.connect(uri);
      
      // Wait for connection to be ready
      await channel.ready;
      
      // Handshake: tell the other peer who we are
      channel.sink.add(jsonEncode({'type': 'handshake', 'peerId': _myId}));
      
      _activeSockets[peerId] = channel;
      _handleSocket(channel, peerId: peerId);
      
      debugPrint('✅ LAN connection established to $peerId');
      if (!_connectionStatus.isClosed) _connectionStatus.add('LAN Connected to $peerId');
      return true;
    } catch (e) {
      debugPrint('❌ LAN connection failed for $peerId: $e');
      return false;
    }
  }

  void _handleSocket(WebSocketChannel socket, {String? peerId}) {
    socket.stream.listen((dynamic data) {
      if (data is! String) return;
      
      try {
        final decoded = jsonDecode(data);
        final type = decoded['type'];
        
        if (type == 'handshake') {
          final remoteId = decoded['peerId'];
          _activeSockets[remoteId] = socket;
          if (!_connectionStatus.isClosed) _connectionStatus.add('LAN Connected to $remoteId');
          debugPrint('🤝 Handshake complete with $remoteId');
        } else if (type == 'p2p_message') {
          final msg = Message.fromJson(decoded['payload']);
          msg.networkSenderId = _getPeerId(socket);
          if (!_incomingMessages.isClosed) _incomingMessages.add(msg);
          
          // Auto-send delivery receipt
          final remoteId = msg.networkSenderId ?? msg.senderId;
          _sendPayload(remoteId, {
            'type': 'delivery_receipt',
            'messageId': msg.id,
            'peerId': _myId,
          });
          debugPrint('📨 Received LAN message from ${msg.senderId}');
        } else if (type == 'delivery_receipt') {
          if (!_deliveryReceipts.isClosed) _deliveryReceipts.add(decoded);
        } else if (type == 'read_receipt') {
          if (!_readReceipts.isClosed) _readReceipts.add(decoded);
        } else if (type == 'typing') {
          if (!_typingIndicators.isClosed) _typingIndicators.add(decoded['peerId']);
        } else {
          // Forward any other custom data (like call signaling or WebRTC handshake) to the data stream
          if (!_dataMessages.isClosed) _dataMessages.add(decoded as Map<String, dynamic>);
        }
      } catch (e) {
        debugPrint('Error parsing LAN message: $e');
      }
    }, onDone: () {
      debugPrint('🛑 LAN Socket closed for ${_getPeerId(socket)}');
      _removeSocket(socket);
    }, onError: (e) {
      debugPrint('❌ LAN Socket error: $e');
      _removeSocket(socket);
    });
  }

  String _getPeerId(WebSocketChannel socket) {
    return _activeSockets.entries
        .firstWhere((e) => e.value == socket, orElse: () => MapEntry('unknown', socket))
        .key;
  }

  void _removeSocket(WebSocketChannel socket) {
    _activeSockets.removeWhere((key, value) => value == socket);
  }

  bool _sendPayload(String peerId, Map<String, dynamic> payload) {
    final socket = _activeSockets[peerId];
    if (socket != null && socket.closeCode == null) {
      socket.sink.add(jsonEncode(payload));
      return true;
    }
    return false;
  }

  bool sendCustomData(String peerId, Map<String, dynamic> payload) {
    return _sendPayload(peerId, payload);
  }

  bool sendMessage(String peerId, Message message) {
    final success = _sendPayload(peerId, {
      'type': 'p2p_message',
      'payload': message.toJson(),
    });
    if (success) {
      debugPrint('📤 Sent LAN message to $peerId');
      return true;
    }
    return false;
  }

  void sendReadReceipt(String peerId, List<String> messageIds) {
    _sendPayload(peerId, {
      'type': 'read_receipt',
      'messageIds': messageIds,
      'peerId': _myId,
    });
  }

  void sendTypingIndicator(String peerId) {
    _sendPayload(peerId, {
      'type': 'typing',
      'peerId': _myId,
    });
  }

  void dispose() {
    for (final socket in _activeSockets.values) {
      socket.sink.close();
    }
    _activeSockets.clear();
    _incomingMessages.close();
    _connectionStatus.close();
    _deliveryReceipts.close();
    _readReceipts.close();
    _typingIndicators.close();
    _dataMessages.close();
  }

  Future<String?> getLocalIp() async {
    return null;
  }
}
