import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/models/user.dart';
import 'package:abyss_chat/providers/chat_provider.dart';
import 'package:abyss_chat/widgets/user_avatar.dart';
import 'package:abyss_chat/services/mdns_service.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final List<User> _selectedMembers = [];

  void _createGroup() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    // Add myself to the group members
    final myId = ref.read(peerServiceProvider).myId ?? 'me';
    final myProfile = ref.read(myProfileProvider).value;
    
    final allMembers = List<User>.from(_selectedMembers);
    if (myProfile != null) {
      allMembers.add(myProfile);
    } else {
      allMembers.add(User(id: myId, name: 'You', avatarIcon: 0xe491, avatarColor: 0xFF6750A4));
    }

    ref.read(chatThreadsProvider.notifier).createGroup(name, allMembers);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(contactsProvider).value ?? [];
    final nearbyPeers = ref.watch(nearbyPeersProvider);
    
    // Combine contacts and nearby peers, removing duplicates by ID
    final allAvailable = <String, User>{};
    for (var c in contacts) {
      allAvailable[c.id] = c;
    }
    for (var p in nearbyPeers) {
      allAvailable[p.id] = p;
    }
    final usersList = allAvailable.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Group'),
        actions: [
          TextButton(
            onPressed: _nameController.text.trim().isEmpty ? null : _createGroup,
            child: const Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.camera_alt, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Type group subject here...',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            width: double.infinity,
            child: Text('Add Participants: ${_selectedMembers.length} selected'),
          ),
          Expanded(
            child: usersList.isEmpty
                ? const Center(child: Text('No contacts found to add.'))
                : ListView.builder(
                    itemCount: usersList.length,
                    itemBuilder: (context, index) {
                      final user = usersList[index];
                      final isSelected = _selectedMembers.any((m) => m.id == user.id);
                      
                      return ListTile(
                        leading: UserAvatar(user: user, radius: 20),
                        title: Text(user.name),
                        subtitle: Text(user.id),
                        trailing: isSelected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedMembers.removeWhere((m) => m.id == user.id);
                            } else {
                              _selectedMembers.add(user);
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
