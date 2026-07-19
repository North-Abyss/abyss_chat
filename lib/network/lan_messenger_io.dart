import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:abyss_chat/features/chat/domain/models/message.dart';
import 'package:abyss_chat/core/constants/app_constants.dart';

// --- SERVICE DEFINITION ---

class LanMessenger {
  HttpServer? _httpServer;
  final Map<String, WebSocket> _activeSockets = {};
  
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

  final StreamController<Map<String, dynamic>> _dataMessages = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onDataMessage => _dataMessages.stream;

  String? _myId;
  int _port = AppConstants.lanServerPort;
  int get serverPort => _port;

  // --- SERVER LIFECYCLE ---
  Future<int> startServer(String myId) async {
    _myId = myId;
    if (kIsWeb) return 0;
    try {
      _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, AppConstants.lanServerPort);
      _port = _httpServer!.port;
      debugPrint('🟢 LAN WebSocket Server listening on port $_port');
      
      _httpServer!.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
           final socket = await WebSocketTransformer.upgrade(request);
           debugPrint('🤝 Inbound WebSocket connection from ${request.connectionInfo?.remoteAddress.address}');
           _handleSocket(socket);
        }
      });
      return _port;
    } catch (e) {
      debugPrint('🔴 Failed to start LAN WebSocket Server: $e');
      return 0;
    }
  }

  Future<bool> connectToPeer(String peerId, String ipAddress, int port) async {
    if (kIsWeb) return false;
    if (_activeSockets.containsKey(peerId)) {
      debugPrint('Already connected to $peerId over LAN');
      return true;
    }

    try {
      debugPrint('🔄 Attempting LAN WebSocket connection to ws://$ipAddress:$port');
      final socket = await WebSocket.connect('ws://$ipAddress:$port')
          .timeout(AppConstants.webrtcSignalingTimeout);
      
      // Handshake: tell the other peer who we are
      socket.add(jsonEncode({'type': 'handshake', 'peerId': _myId}));
      
      _activeSockets[peerId] = socket;
      _handleSocket(socket, peerId: peerId);
      
      debugPrint('✅ LAN connection established to $peerId');
      if (!_connectionStatus.isClosed) _connectionStatus.add('LAN Connected to $peerId');
      return true;
    } catch (e) {
      debugPrint('❌ LAN connection failed for $peerId: $e');
      return false;
    }
  }

  void _handleSocket(WebSocket socket, {String? peerId}) {
    socket.listen((dynamic data) {
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

  String _getPeerId(WebSocket socket) {
    return _activeSockets.entries
        .firstWhere((e) => e.value == socket, orElse: () => MapEntry('unknown', socket))
        .key;
  }

  void _removeSocket(WebSocket socket) {
    _activeSockets.removeWhere((key, value) => value == socket);
  }

  bool _sendPayload(String peerId, Map<String, dynamic> payload) {
    final socket = _activeSockets[peerId];
    if (socket != null && socket.readyState == WebSocket.open) {
      socket.add(jsonEncode(payload));
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
    _httpServer?.close(force: true);
    for (final socket in _activeSockets.values) {
      socket.close();
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
    if (kIsWeb) return null;
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting IP: $e');
    }
    return null;
  }
}

