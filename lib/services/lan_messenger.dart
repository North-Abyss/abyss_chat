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
      
      // Split by newline (if messages are newline-delimited)
      final messages = buffer.split('\n');
      buffer = messages.removeLast(); // keep incomplete part
      
      for (final jsonStr in messages) {
        if (jsonStr.trim().isEmpty) continue;
        
        try {
          final decoded = jsonDecode(jsonStr);
          
          if (decoded['type'] == 'handshake') {
            final remoteId = decoded['peerId'];
            _activeSockets[remoteId] = socket;
            _connectionStatus.add('LAN Connected to $remoteId');
            debugPrint('🤝 Handshake complete with $remoteId');
          } else if (decoded['type'] == 'p2p_message') {
            final msg = Message.fromJson(decoded['payload']);
            _incomingMessages.add(msg);
            debugPrint('📨 Received LAN message from ${msg.senderId}');
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

  bool sendMessage(String peerId, Message message) {
    final socket = _activeSockets[peerId];
    if (socket != null) {
      final payload = jsonEncode({
        'type': 'p2p_message',
        'payload': message.toJson(),
      });
      socket.writeln(payload);
      socket.flush();
      debugPrint('📤 Sent LAN message to $peerId');
      return true;
    }
    return false;
  }

  void dispose() {
    _serverSocket?.close();
    for (final socket in _activeSockets.values) {
      socket.destroy();
    }
    _activeSockets.clear();
    _incomingMessages.close();
    _connectionStatus.close();
  }
}
