import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/models/user.dart';

class NearbyPeersNotifier extends Notifier<List<User>> {
  Registration? _registration;
  Discovery? _discovery;
  
  final String _serviceType = '_abysschat._tcp';
  
  String _myId = '';
  String _myName = '';

  @override
  List<User> build() {
    ref.onDispose(() => stop());
    return [];
  }

  Future<void> startBroadcasting(String id, String name, {bool wps = false, int port = 45885}) async {
    _myId = id;
    _myName = name;
    
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
          host: InternetAddress.anyIPv4.address,
          port: port,
          txt: {
            'id': Uint8List.fromList(id.codeUnits),
            'name': Uint8List.fromList(name.codeUnits),
            'wps': Uint8List.fromList((wps ? '1' : '0').codeUnits),
          },
        ),
      );
      debugPrint('📡 mDNS Broadcasting as $name ($id) | WPS: $wps');
    } catch (e) {
      debugPrint('Error starting mDNS broadcast: $e');
    }
  }

  Future<void> toggleWps(bool isActive) async {
    if (_myId.isNotEmpty) {
      await startBroadcasting(_myId, _myName, wps: isActive);
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
      );

      _discovery!.addListener(() {
        final List<User> newPeers = [];
        for (final service in _discovery!.services) {
          if (service.txt != null && service.txt!.containsKey('id')) {
            final peerId = String.fromCharCodes(service.txt!['id']!);
            if (peerId == myId) continue;

            final peerName = service.txt!.containsKey('name') 
              ? String.fromCharCodes(service.txt!['name']!) 
              : 'Unknown Peer';

            final isWps = service.txt!.containsKey('wps') && String.fromCharCodes(service.txt!['wps']!) == '1';

            newPeers.add(User(
              id: peerId,
              name: peerName,
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
}

final nearbyPeersProvider = NotifierProvider<NearbyPeersNotifier, List<User>>(() {
  return NearbyPeersNotifier();
});
