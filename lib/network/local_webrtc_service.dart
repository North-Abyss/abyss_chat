// ==========================================
// Abyss Chat - Local WebRTC Service
// ==========================================
// Version: 1.2.0
// Description: 
//   Manages robust WebRTC P2P connections over the Local Area Network,
//   bypassing external signaling servers entirely. Handles ultra high-bandwidth 
//   video and audio media streams directly between devices.
// ==========================================
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:abyss_chat/network/lan_messenger.dart';
import 'package:abyss_chat/features/chat/domain/models/message.dart' hide MessageType;

class LocalMediaEvent {
  final String type; // 'stream', 'close', 'error'
  final dynamic data;
  LocalMediaEvent(this.type, this.data);
}

class LocalMediaConnection {
  final String peer;
  final RTCPeerConnection peerConnection;
  
  final StreamController<LocalMediaEvent> _events = StreamController.broadcast();
  
  LocalMediaConnection(this.peer, this.peerConnection) {
    peerConnection.onAddStream = (stream) {
      _events.add(LocalMediaEvent('stream', stream));
    };
    peerConnection.onIceConnectionState = (state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
        _events.add(LocalMediaEvent('close', null));
      }
    };
  }
  
  Stream<dynamic> on(String eventType) {
    return _events.stream.where((e) => e.type == eventType).map((e) => e.data);
  }
  
  void close() {
    peerConnection.close();
    _events.add(LocalMediaEvent('close', null));
  }
  
  void answer(MediaStream localStream) {
    localStream.getTracks().forEach((track) {
      peerConnection.addTrack(track, localStream);
    });
  }
}

class LocalDataConnection {
  final String peer;
  final RTCPeerConnection peerConnection;
  RTCDataChannel? dataChannel;
  
  final StreamController<dynamic> _data = StreamController.broadcast();
  Stream<dynamic> get onData => _data.stream;

  final StreamController<void> _close = StreamController.broadcast();
  Stream<void> get onClose => _close.stream;
  
  final StreamController<void> _open = StreamController.broadcast();
  Stream<void> get onOpen => _open.stream;
  
  LocalDataConnection(this.peer, this.peerConnection) {
    peerConnection.onIceConnectionState = (state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
        _close.add(null);
      }
    };
  }
  
  void attachDataChannel(RTCDataChannel dc) {
    dataChannel = dc;
    dc.onMessage = (RTCDataChannelMessage message) {
      if (message.type == MessageType.text) {
        _data.add(message.text);
      }
    };
    dc.onDataChannelState = (RTCDataChannelState state) {
      if (state == RTCDataChannelState.RTCDataChannelClosed) {
        _close.add(null);
      } else if (state == RTCDataChannelState.RTCDataChannelOpen) {
        _open.add(null);
      }
    };
  }
  
  void send(String data) {
    if (dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen) {
      dataChannel?.send(RTCDataChannelMessage(data));
    }
  }
  
  void close() {
    dataChannel?.close();
    peerConnection.close();
    _close.add(null);
  }
}

class LocalWebrtcService {
  final LanMessenger lanMessenger;
  final String Function() getMyId;
  
  String get myId => getMyId();
  
  final Map<String, LocalMediaConnection> _activeCalls = {};
  final Map<String, LocalDataConnection> _activeDataConnections = {};
  
  final StreamController<LocalMediaConnection> _incomingCalls = StreamController.broadcast();
  Stream<LocalMediaConnection> get onCallReceived => _incomingCalls.stream;

  final StreamController<LocalDataConnection> _incomingDataConnections = StreamController.broadcast();
  Stream<LocalDataConnection> get onDataConnectionReceived => _incomingDataConnections.stream;
  
  final StreamController<Message> _incomingMessages = StreamController.broadcast();
  Stream<Message> get onMessageReceived => _incomingMessages.stream;
  
  LocalWebrtcService(this.lanMessenger, this.getMyId) {
    lanMessenger.onDataMessage.listen(_handleSignalingData);
    
    _incomingDataConnections.stream.listen((conn) {
      conn.onClose.listen((_) {
        _activeDataConnections.remove(conn.peer);
      });
    });
    
    _incomingCalls.stream.listen((conn) {
      conn.on('close').listen((_) {
        _activeCalls.remove(conn.peer);
      });
    });
  }
  
  Future<LocalMediaConnection?> makeCall(String peerId, MediaStream localStream) async {
    try {
      final pc = await _createPeerConnection(peerId, isData: false);
      final mediaConn = LocalMediaConnection(peerId, pc);
      _activeCalls[peerId] = mediaConn;
      
      localStream.getTracks().forEach((track) {
        pc.addTrack(track, localStream);
      });
      
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      
      lanMessenger.sendCustomData(peerId, {
        'type': 'webrtc_offer',
        'sdp': offer.sdp,
        'peerId': myId,
        'isData': false,
      });
      
      return mediaConn;
    } catch (e) {
      debugPrint('Error making local call: $e');
      return null;
    }
  }
  
  Future<LocalDataConnection?> connectData(String peerId) async {
    debugPrint('🚀 [LocalWebrtcService] Initiating WebRTC Data connection to $peerId');
    try {
      final pc = await _createPeerConnection(peerId, isData: true);
      final dataConn = LocalDataConnection(peerId, pc);
      _activeDataConnections[peerId] = dataConn;
      
      final dcInit = RTCDataChannelInit()
        ..negotiated = false
        ..id = 1;
      final dc = await pc.createDataChannel('abyss_local_chat', dcInit);
      dataConn.attachDataChannel(dc);
      
      dataConn.onClose.listen((_) {
        _activeDataConnections.remove(peerId);
      });
      
      dataConn.onData.listen((data) {
        try {
          final json = jsonDecode(data);
          _incomingMessages.add(Message.fromJson(json));
        } catch (e) {
          debugPrint('Failed to parse local webrtc data: $e');
        }
      });
      
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      
      lanMessenger.sendCustomData(peerId, {
        'type': 'webrtc_offer',
        'sdp': offer.sdp,
        'peerId': myId,
        'isData': true,
      });
      
      return dataConn;
    } catch (e) {
      debugPrint('Error making local data connection: $e');
      return null;
    }
  }
  
  Future<RTCPeerConnection> _createPeerConnection(String peerId, {required bool isData}) async {
    final pc = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {
          "urls": [
            "turn:openrelay.metered.ca:80",
            "turn:openrelay.metered.ca:443",
            "turn:openrelay.metered.ca:443?transport=tcp"
          ],
          "username": "openrelayproject",
          "credential": "openrelayproject",
        },
      ],
      'sdpSemantics': 'unified-plan',
    });
    
    pc.onIceCandidate = (candidate) {
      lanMessenger.sendCustomData(peerId, {
        'type': 'webrtc_candidate',
        'candidate': candidate.toMap(),
        'peerId': myId,
        'isData': isData,
      });
    };
    
    return pc;
  }
  
  bool sendMessage(String peerId, Message message) {
    final conn = _activeDataConnections[peerId];
    if (conn != null && conn.dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen) {
      final messageJson = jsonEncode(message.toJson());
      conn.send(messageJson);
      return true;
    }
    return false;
  }
  
  void _handleSignalingData(Map<String, dynamic> data) async {
    final type = data['type'];
    final peerId = data['peerId'] as String?;
    if (peerId == null) return;
    
    debugPrint('📡 [LocalWebrtcService] Received signaling data: type=$type from=$peerId');
    
    final bool isData = data['isData'] == true;
    
    if (type == 'webrtc_offer') {
      final pc = await _createPeerConnection(peerId, isData: isData);
      
      if (isData) {
        final dataConn = LocalDataConnection(peerId, pc);
        _activeDataConnections[peerId] = dataConn;
        pc.onDataChannel = (channel) {
          dataConn.attachDataChannel(channel);
          dataConn.onData.listen((data) {
            try {
              final json = jsonDecode(data);
              _incomingMessages.add(Message.fromJson(json));
            } catch (e) {
              debugPrint('Failed to parse local webrtc data: $e');
            }
          });
        };
        _incomingDataConnections.add(dataConn);
      } else {
        final mediaConn = LocalMediaConnection(peerId, pc);
        _activeCalls[peerId] = mediaConn;
        _incomingCalls.add(mediaConn);
      }
      
      final offer = RTCSessionDescription(data['sdp'], 'offer');
      await pc.setRemoteDescription(offer);
      
      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      
      lanMessenger.sendCustomData(peerId, {
        'type': 'webrtc_answer',
        'sdp': answer.sdp,
        'peerId': myId,
        'isData': isData,
      });
      
    } else if (type == 'webrtc_answer') {
      if (isData) {
        final dataConn = _activeDataConnections[peerId];
        if (dataConn != null) {
          final answer = RTCSessionDescription(data['sdp'], 'answer');
          await dataConn.peerConnection.setRemoteDescription(answer);
        }
      } else {
        final mediaConn = _activeCalls[peerId];
        if (mediaConn != null) {
          final answer = RTCSessionDescription(data['sdp'], 'answer');
          await mediaConn.peerConnection.setRemoteDescription(answer);
        }
      }
    } else if (type == 'webrtc_candidate') {
      final candidateMap = data['candidate'];
      final candidate = RTCIceCandidate(
        candidateMap['candidate'],
        candidateMap['sdpMid'],
        candidateMap['sdpMLineIndex'],
      );
      
      if (isData) {
        final dataConn = _activeDataConnections[peerId];
        if (dataConn != null) {
          await dataConn.peerConnection.addCandidate(candidate);
        }
      } else {
        final mediaConn = _activeCalls[peerId];
        if (mediaConn != null) {
          await mediaConn.peerConnection.addCandidate(candidate);
        }
      }
    }
  }
}
