import 'package:flutter/material.dart';
import 'package:abyss_chat/features/chat/domain/models/chat_thread.dart';
import 'package:abyss_chat/features/chat/domain/models/message.dart';
import 'dart:io';

class ChatMediaScreen extends StatelessWidget {
  final ChatThread thread;

  const ChatMediaScreen({super.key, required this.thread});

  @override
  Widget build(BuildContext context) {
    final mediaMessages = thread.messages.where((m) => m.type == MessageType.image).toList();
    final docMessages = thread.messages.where((m) => m.type == MessageType.file).toList();
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Media, Links, and Docs'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Media'),
              Tab(text: 'Docs'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMediaGrid(mediaMessages),
            _buildDocsList(docMessages),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGrid(List<Message> messages) {
    if (messages.isEmpty) {
      return const Center(child: Text('No media found'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        if (msg.localFilePath != null && File(msg.localFilePath!).existsSync()) {
          return Image.file(File(msg.localFilePath!), fit: BoxFit.cover);
        }
        return Container(
          color: Colors.grey.shade300,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      },
    );
  }

  Widget _buildDocsList(List<Message> messages) {
    if (messages.isEmpty) {
      return const Center(child: Text('No documents found'));
    }
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return ListTile(
          leading: const Icon(Icons.insert_drive_file),
          title: Text(msg.fileName ?? 'Document'),
          subtitle: Text('${msg.timestamp.month}/${msg.timestamp.day}/${msg.timestamp.year}'),
          onTap: () {
            // Handle opening file
          },
        );
      },
    );
  }
}
