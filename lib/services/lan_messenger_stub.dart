import 'dart:async';
import 'package:abyss_chat/models/message.dart';

// --- SERVICE DEFINITION (WEB STUB) ---

class LanMessenger {
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

  Future<int> startServer(String myId) async {
    // LAN Server is not supported on Web
    return 0;
  }

  Future<bool> connectToPeer(String peerId, String ipAddress, int port) async {
    // TCP sockets are not supported on Web
    return false;
  }

  bool sendCustomData(String peerId, Map<String, dynamic> payload) {
    return false;
  }

  bool sendMessage(String peerId, Message message) {
    return false;
  }

  void sendReadReceipt(String peerId, List<String> messageIds) {
    // No-op
  }

  void sendTypingIndicator(String peerId) {
    // No-op
  }

  void dispose() {
    _incomingMessages.close();
    _connectionStatus.close();
    _deliveryReceipts.close();
    _readReceipts.close();
    _typingIndicators.close();
    _dataMessages.close();
  }
}
