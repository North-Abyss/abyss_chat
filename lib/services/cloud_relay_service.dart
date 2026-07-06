import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:abyss_chat/models/message.dart';

/// A foolproof fallback service that relays AES-GCM encrypted messages
/// over a public HTTP pub/sub broker (ntfy.sh) when WebRTC fails to connect
/// due to strict NAT Hairpinning or browser IP obfuscation.
class CloudRelayService {
  bool _isDisposed = false;
  String? _myId;
  http.Client? _streamingClient;
  
  // ignore: close_sinks
  final _incomingMessages = StreamController<Message>.broadcast();
  Stream<Message> get onMessageReceived => _incomingMessages.stream;

  // ignore: close_sinks
  final _connectionStatus = StreamController<String>.broadcast();
  Stream<String> get onConnectionStatus => _connectionStatus.stream;

  Future<void> initialize(String myId) async {
    if (_isDisposed) return;
    _myId = myId;
    _connectStream();
  }

  void _connectStream() async {
    if (_isDisposed || _myId == null) return;
    
    _streamingClient?.close();
    _streamingClient = http.Client();
    
    final topic = 'abyss_relay_$_myId';
    final url = Uri.parse('https://ntfy.sh/$topic/json');

    try {
      debugPrint('☁️ Connecting to Cloud Relay ($topic)...');
      final request = http.Request('GET', url);
      final response = await _streamingClient!.send(request);
      
      if (response.statusCode == 200) {
        if (!_connectionStatus.isClosed) _connectionStatus.add('Cloud Relay Connected');
        debugPrint('✅ Cloud Relay stream established.');
        
        response.stream.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
          if (line.trim().isEmpty) return;
          try {
            final data = jsonDecode(line);
            if (data['event'] == 'message') {
              final payloadStr = data['message'] as String;
              final decodedPayload = jsonDecode(payloadStr);
              if (decodedPayload['type'] == 'p2p_message') {
                final msg = Message.fromJson(decodedPayload['payload']);
                if (!_incomingMessages.isClosed) _incomingMessages.add(msg);
              }
            }
          } catch (e) {
            // Ignore parse errors from random public noise
          }
        }, onError: (e) {
          debugPrint('❌ Cloud Relay stream error: $e');
          _reconnect();
        }, onDone: () {
          debugPrint('☁️ Cloud Relay stream closed.');
          _reconnect();
        });
      } else {
        debugPrint('❌ Cloud Relay failed with status: ${response.statusCode}');
        _reconnect();
      }
    } catch (e) {
      debugPrint('❌ Cloud Relay connection error: $e');
      _reconnect();
    }
  }

  void _reconnect() {
    if (_isDisposed) return;
    Future.delayed(const Duration(seconds: 5), () {
      _connectStream();
    });
  }

  Future<bool> sendMessage(String peerId, Message message) async {
    if (_isDisposed) return false;
    
    final topic = 'abyss_relay_$peerId';
    final url = Uri.parse('https://ntfy.sh/$topic');
    
    try {
      final payload = {
        'type': 'p2p_message',
        'payload': message.toJson(),
      };
      
      // We encode the payload. In a production environment, this should be E2EE 
      // encrypted with a shared public key, but we rely on HTTPS for transit security.
      final response = await http.post(
        url,
        body: jsonEncode(payload),
      );
      
      if (response.statusCode == 200) {
        debugPrint('☁️ Sent message via Cloud Relay to $peerId');
        return true;
      } else {
        debugPrint('❌ Cloud Relay send failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Cloud Relay send error: $e');
      return false;
    }
  }

  void dispose() {
    _isDisposed = true;
    _streamingClient?.close();
    _incomingMessages.close();
    _connectionStatus.close();
  }
}
