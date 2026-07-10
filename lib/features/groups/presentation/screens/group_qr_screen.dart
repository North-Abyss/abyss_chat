import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:abyss_chat/features/chat/domain/models/chat_thread.dart';

class GroupQRScreen extends StatelessWidget {
  final ChatThread thread;

  const GroupQRScreen({super.key, required this.thread});

  @override
  Widget build(BuildContext context) {
    final payload = jsonEncode({
      'type': 'group_join',
      'id': thread.id,
      'name': thread.groupName ?? 'Group',
    });

    return Scaffold(
      appBar: AppBar(title: Text('${thread.groupName ?? 'Group'} QR Code')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Scan this QR code to join the group',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: payload,
                version: QrVersions.auto,
                size: 250.0,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              thread.groupName ?? 'Group',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
