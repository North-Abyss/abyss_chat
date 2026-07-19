import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/features/chat/domain/chat_controller.dart';

import 'dart:convert';

class MyQRScreen extends ConsumerStatefulWidget {
  const MyQRScreen({super.key});

  @override
  ConsumerState<MyQRScreen> createState() => _MyQRScreenState();
}

class _MyQRScreenState extends ConsumerState<MyQRScreen> {
  String? _localIp;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchIp();
  }

  Future<void> _fetchIp() async {
    final messenger = ref.read(lanMessengerProvider);
    final ip = await messenger.getLocalIp();
    if (mounted) {
      setState(() {
        _localIp = ip;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(chatThreadsProvider.notifier).myId ?? 'Unknown ID';
    
    // Construct robust JSON payload for QR code
    final payloadMap = {
      'id': myId,
      if (_localIp != null) 'ip': _localIp,
      if (_localIp != null) 'port': ref.read(lanMessengerProvider).serverPort,
    };
    final payloadString = jsonEncode(payloadMap);
    
    return Scaffold(
      appBar: AppBar(title: const Text('My QR Code')),
      body: Center(
        child: _isLoading 
        ? const CircularProgressIndicator()
        : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Scan this QR code to connect with me',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copy JSON Payload for Web'),
              onPressed: () {
                debugPrint('📋 PASTE THIS INTO WEB CLIENT: $payloadString');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payload printed to terminal. Copy and paste it into the Web Client!')),
                );
              },
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: payloadString,
                version: QrVersions.auto,
                size: 250.0,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ID: $myId',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            if (_localIp != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Local IP: $_localIp',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
