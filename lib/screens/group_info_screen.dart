import 'dart:io';
//import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
//import 'package:qr_flutter/qr_flutter.dart';
import 'package:abyss_chat/models/chat_thread.dart';
import 'package:abyss_chat/models/user.dart';
import 'package:abyss_chat/providers/chat_provider.dart';
import 'package:abyss_chat/services/mdns_service.dart';
import 'package:abyss_chat/widgets/user_avatar.dart';
import 'package:abyss_chat/screens/group_qr_screen.dart';

class GroupInfoScreen extends ConsumerStatefulWidget {
  final ChatThread thread;
  const GroupInfoScreen({super.key, required this.thread});

  @override
  ConsumerState<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends ConsumerState<GroupInfoScreen> {
  
  Future<void> _pickImage() async {
    String? imagePath;
    if (Platform.isAndroid || Platform.isIOS) {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(source: ImageSource.gallery);
      imagePath = xfile?.path;
    } else {
      final result = await FilePicker.pickFiles(type: FileType.image);
      imagePath = result?.files.single.path;
    }

    if (imagePath != null) {
      ref.read(chatThreadsProvider.notifier).updateGroupProfile(
        widget.thread.id, 
        null, 
        imagePath
      );
    }
  }

  Future<void> _renameGroup(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Group'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Group Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      ref.read(chatThreadsProvider.notifier).updateGroupProfile(
        widget.thread.id, 
        newName, 
        null
      );
    }
  }

  void _showGroupQR(ChatThread liveThread) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => GroupQRScreen(thread: liveThread)));
  }

  @override
  Widget build(BuildContext context) {
    final liveThread = ref.watch(singleThreadProvider(widget.thread.id)) ?? widget.thread;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            actions: [
              IconButton(icon: const Icon(Icons.qr_code), onPressed: () => _showGroupQR(liveThread)),
              IconButton(icon: const Icon(Icons.edit), onPressed: () => _renameGroup(liveThread.groupName ?? 'Group Info')),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(liveThread.groupName ?? 'Group Info'),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: liveThread.groupImagePath != null
                        ? Image.file(File(liveThread.groupImagePath!), fit: BoxFit.cover)
                        : Center(
                            child: Icon(Icons.group, size: 100, color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.5)),
                          ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton.small(
                      heroTag: 'group_pic_fab',
                      onPressed: _pickImage,
                      child: const Icon(Icons.camera_alt),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${liveThread.members.length} Participants',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(Icons.person_add, color: Colors.white),
                  ),
                  title: const Text('Add Participants'),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => _AddParticipantsSheet(thread: liveThread),
                    );
                  },
                ),
                const Divider(),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: liveThread.members.length,
                  itemBuilder: (context, index) {
                    final member = liveThread.members[index];
                    return ListTile(
                      leading: UserAvatar(user: member, radius: 20),
                      title: Text(member.name),
                      subtitle: Text(member.id),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title: const Text('Exit Group', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddParticipantsSheet extends ConsumerStatefulWidget {
  final ChatThread thread;
  const _AddParticipantsSheet({required this.thread});

  @override
  ConsumerState<_AddParticipantsSheet> createState() => _AddParticipantsSheetState();
}

class _AddParticipantsSheetState extends ConsumerState<_AddParticipantsSheet> {
  final List<User> _selected = [];

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(contactsProvider).value ?? [];
    final nearbyPeers = ref.watch(nearbyPeersProvider);
    
    final allAvailable = <String, User>{};
    for (var c in contacts) {
      allAvailable[c.id] = c;
    }
    for (var p in nearbyPeers) {
      allAvailable[p.id] = p;
    }
    
    final existingIds = widget.thread.members.map((m) => m.id).toSet();
    final usersList = allAvailable.values.where((u) => !existingIds.contains(u.id)).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Add Participants', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: _selected.isEmpty ? null : () {
                  final threads = List<ChatThread>.from(ref.read(chatThreadsProvider).value ?? []);
                  final threadIndex = threads.indexWhere((t) => t.id == widget.thread.id);
                  if (threadIndex != -1) {
                    final updatedMembers = List<User>.from(threads[threadIndex].members)..addAll(_selected);
                    threads[threadIndex] = threads[threadIndex].copyWith(members: updatedMembers);
                    ref.read(chatThreadsProvider.notifier).updateGroupMembers(widget.thread.id, updatedMembers);
                  }
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: usersList.isEmpty
                ? const Center(child: Text('No new contacts found.'))
                : ListView.builder(
                    itemCount: usersList.length,
                    itemBuilder: (context, index) {
                      final user = usersList[index];
                      final isSelected = _selected.any((m) => m.id == user.id);
                      
                      return ListTile(
                        leading: UserAvatar(user: user, radius: 20),
                        title: Text(user.name),
                        subtitle: Text(user.id),
                        trailing: isSelected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selected.removeWhere((m) => m.id == user.id);
                            } else {
                              _selected.add(user);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
