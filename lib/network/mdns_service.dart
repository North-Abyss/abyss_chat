
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/features/contacts/domain/models/user.dart';
import 'package:abyss_chat/core/constants/app_constants.dart';

class NearbyPeersNotifier extends Notifier<List<User>> {
  Registration? _registration;
  Discovery? _discovery;
  
  final String _serviceType = AppConstants.mDnsServiceType;
  
  String _myId = '';
  String _myName = '';
  String? _myUsername;

  @override
  List<User> build() {
    ref.onDispose(() => stop());
    return [];
  }

  Future<void> startBroadcasting(String id, String name, {String? username, bool wps = false, int? port}) async {
    final activePort = port ?? AppConstants.lanServerPort;
    _myId = id;
    _myName = name;
    _myUsername = username;
    
    if (kIsWeb) {
      debugPrint('🌐 Web browser detected: Skipping mDNS broadcast.');
      return;
    }
    
    if (_registration != null) {
      await unregister(_registration!);
      _registration = null;
    }
    
    try {
      _registration = await register(
        Service(
          name: 'AbyssChat-$id',
          type: _serviceType,
          host: '0.0.0.0',
          port: activePort,
          txt: {
            'id': Uint8List.fromList(id.codeUnits),
            'name': Uint8List.fromList(name.codeUnits),
            if (username != null) 'username': Uint8List.fromList(username.codeUnits),
            'wps': Uint8List.fromList((wps ? '1' : '0').codeUnits),
          },
        ),
      ).timeout(const Duration(seconds: 2));
      debugPrint('📡 mDNS Broadcasting as $name ($id) | WPS: $wps');
    } on TimeoutException {
      debugPrint('⚠️ mDNS Broadcasting timed out. The native Android daemon might be locked up.');
    } catch (e) {
      debugPrint('Error starting mDNS broadcast: $e');
    }
  }

  Future<void> toggleWps(bool isActive) async {
    if (_myId.isNotEmpty) {
      await startBroadcasting(_myId, _myName, username: _myUsername, wps: isActive);
    }
  }

  Future<void> startScanning(String myId) async {
    if (kIsWeb) {
      debugPrint('🌐 Web browser detected: Skipping mDNS scanning.');
      return;
    }

    try {
      _discovery = await startDiscovery(
        _serviceType,
        autoResolve: true,
      ).timeout(const Duration(seconds: 2));

      _discovery!.addListener(() {
        final List<User> newPeers = [];
        for (final service in _discovery!.services) {
          if (service.txt != null && service.txt!.containsKey('id')) {
            final peerId = String.fromCharCodes(service.txt!['id']!);
            if (peerId == myId) continue;

            final peerName = service.txt!.containsKey('name') 
              ? String.fromCharCodes(service.txt!['name']!) 
              : 'Unknown Peer';
              
            final peerUsername = service.txt!.containsKey('username')
              ? String.fromCharCodes(service.txt!['username']!)
              : null;

            final isWps = service.txt!.containsKey('wps') && String.fromCharCodes(service.txt!['wps']!) == '1';

            newPeers.add(User(
              id: peerId,
              name: peerName,
              username: peerUsername,
              avatarIcon: 0xe491, // default icon (person)
              avatarColor: 0xFF6750A4, // default color
              isWpsActive: isWps,
              ipAddress: service.host,
              port: service.port,
            ));
          }
        }
        state = newPeers;
      });
      debugPrint('🔍 mDNS Scanning started');
    } catch (e) {
      debugPrint('Error starting mDNS scan: $e');
    }
  }

  Future<void> stop() async {
    if (_registration != null) {
      await unregister(_registration!);
      _registration = null;
    }
    if (_discovery != null) {
      await stopDiscovery(_discovery!);
      _discovery = null;
    }
  }
  
  void addManualPeer(User peer) {
    if (!state.any((p) => p.id == peer.id)) {
      state = [...state, peer];
    } else {
      // Update existing peer's IP and port if they changed
      state = [
        for (final p in state)
          if (p.id == peer.id) peer else p
      ];
    }
  }
}

final nearbyPeersProvider = NotifierProvider<NearbyPeersNotifier, List<User>>(() {
  return NearbyPeersNotifier();
});
