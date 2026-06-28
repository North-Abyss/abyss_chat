import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:abyss_chat/models/message.dart';

class LanMessenger {
  ServerSocket? _serverSocket;
  final Map<String, Socket> _activeSockets = {};
  
  // Stream controller to broadcast incoming messages to Riverpod
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

  String? _myId;
  int _port = 45886; // Dedicated port for Abyss TCP messaging

  Future<int> startServer(String myId) async {
    _myId = myId;
    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
      _port = _serverSocket!.port;
      debugPrint('🟢 LAN Server listening on port $_port');
      
      _serverSocket!.listen((Socket socket) {
        debugPrint('🤝 Inbound connection from ${socket.remoteAddress.address}');
        _handleSocket(socket);
      });
      return _port;
    } catch (e) {
      debugPrint('🔴 Failed to start LAN Server: $e');
      return 0;
    }
  }

  Future<bool> connectToPeer(String peerId, String ipAddress, int port) async {
    if (_activeSockets.containsKey(peerId)) {
      debugPrint('Already connected to $peerId over LAN');
      return true;
    }

    try {
      debugPrint('🔄 Attempting LAN connection to $ipAddress:$port');
      final socket = await Socket.connect(ipAddress, port, timeout: const Duration(seconds: 3));
      
      // Handshake: tell the other peer who we are
      socket.writeln(jsonEncode({'type': 'handshake', 'peerId': _myId}));
      
      _activeSockets[peerId] = socket;
      _handleSocket(socket, peerId: peerId);
      
      debugPrint('✅ LAN connection established to $peerId');
      _connectionStatus.add('LAN Connected to $peerId');
      return true;
    } catch (e) {
      debugPrint('❌ LAN connection failed for $peerId: $e');
      return false;
    }
  }

  void _handleSocket(Socket socket, {String? peerId}) {
    String buffer = '';
    
    socket.listen((List<int> data) {
      final String decodedData = utf8.decode(data);
      buffer += decodedData;
      
      final messages = buffer.split('\n');
      buffer = messages.removeLast(); 
      
      for (final jsonStr in messages) {
        if (jsonStr.trim().isEmpty) continue;
        
        try {
          final decoded = jsonDecode(jsonStr);
          final type = decoded['type'];
          
          if (type == 'handshake') {
            final remoteId = decoded['peerId'];
            _activeSockets[remoteId] = socket;
            _connectionStatus.add('LAN Connected to $remoteId');
            debugPrint('🤝 Handshake complete with $remoteId');
          } else if (type == 'p2p_message') {
            final msg = Message.fromJson(decoded['payload']);
            _incomingMessages.add(msg);
            
            // Auto-send delivery receipt
            final remoteId = msg.senderId;
            _sendPayload(remoteId, {
              'type': 'delivery_receipt',
              'messageId': msg.id,
              'peerId': _myId,
            });
            debugPrint('📨 Received LAN message from ${msg.senderId}');
          } else if (type == 'delivery_receipt') {
            _deliveryReceipts.add(decoded);
          } else if (type == 'read_receipt') {
            _readReceipts.add(decoded);
          } else if (type == 'typing') {
            _typingIndicators.add(decoded['peerId']);
          }
        } catch (e) {
          debugPrint('Error parsing LAN message: $e');
        }
      }
    }, onDone: () {
      debugPrint('🛑 LAN Socket closed for ${_getPeerId(socket)}');
      _removeSocket(socket);
    }, onError: (e) {
      debugPrint('❌ LAN Socket error: $e');
      _removeSocket(socket);
    });
  }

  String _getPeerId(Socket socket) {
    return _activeSockets.entries
        .firstWhere((e) => e.value == socket, orElse: () => MapEntry('unknown', socket))
        .key;
  }

  void _removeSocket(Socket socket) {
    _activeSockets.removeWhere((key, value) => value == socket);
  }

  bool _sendPayload(String peerId, Map<String, dynamic> payload) {
    final socket = _activeSockets[peerId];
    if (socket != null) {
      socket.writeln(jsonEncode(payload));
      socket.flush();
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
    _serverSocket?.close();
    for (final socket in _activeSockets.values) {
      socket.destroy();
    }
    _activeSockets.clear();
    _incomingMessages.close();
    _connectionStatus.close();
    _deliveryReceipts.close();
    _readReceipts.close();
    _typingIndicators.close();
  }
}

