import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/features/chat/domain/chat_controller.dart';
import 'package:abyss_chat/features/contacts/domain/contacts_controller.dart';
import 'package:abyss_chat/network/mdns_service.dart';
import 'package:abyss_chat/core/widgets/user_avatar.dart';
import 'package:flutter/services.dart';

class UserSearchDelegate extends SearchDelegate<String?> {
  final WidgetRef ref;
  final bool isDesktop;

  UserSearchDelegate(this.ref, {this.isDesktop = false});

  @override
  String get searchFieldLabel => 'Search contacts or nearby...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList();
  }

  Widget _buildList() {
    final contacts = ref.watch(contactsProvider).value ?? [];
    final nearbyPeers = ref.watch(nearbyPeersProvider);

    // Combine them, avoid duplicates by ID
    final allUsers = [...contacts];
    for (var peer in nearbyPeers) {
      if (!allUsers.any((u) => u.id == peer.id)) {
        allUsers.add(peer);
      }
    }

    // Filter by query
    final filteredUsers = query.isEmpty
        ? allUsers
        : allUsers
              .where((u) => u.name.toLowerCase().contains(query.toLowerCase()))
              .toList();

    if (filteredUsers.isEmpty) {
      return const Center(child: Text('No users found.'));
    }

    int selectedIndex = 0;
    final ScrollController scrollController = ScrollController();

    return StatefulBuilder(
      builder: (context, setState) {
        return Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                setState(() {
                  selectedIndex = (selectedIndex + 1).clamp(0, filteredUsers.length - 1);
                });
                // Calculate scroll position
                final offset = selectedIndex * 72.0; // Approx height of ListTile
                if (offset > scrollController.offset + scrollController.position.viewportDimension - 72.0) {
                   scrollController.animateTo(
                     offset - scrollController.position.viewportDimension + 72.0,
                     duration: const Duration(milliseconds: 100),
                     curve: Curves.easeOut,
                   );
                }
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                setState(() {
                  selectedIndex = (selectedIndex - 1).clamp(0, filteredUsers.length - 1);
                });
                final offset = selectedIndex * 72.0;
                if (offset < scrollController.offset) {
                   scrollController.animateTo(
                     offset,
                     duration: const Duration(milliseconds: 100),
                     curve: Curves.easeOut,
                   );
                }
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                final user = filteredUsers[selectedIndex];
                ref
                    .read(chatThreadsProvider.notifier)
                    .startNewChat(user.id, peerName: user.name);
                close(context, user.id);
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: ListView.builder(
            controller: scrollController,
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              final isNearby = nearbyPeers.any((p) => p.id == user.id);
              final isSelected = index == selectedIndex;

              return Container(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) 
                    : null,
                child: ListTile(
                  leading: UserAvatar(user: user, radius: 20),
                  title: Text(user.name),
                  subtitle: Text(isNearby ? 'Nearby' : 'Contact'),
                  selected: isSelected,
                  onTap: () {
                    ref
                        .read(chatThreadsProvider.notifier)
                        .startNewChat(user.id, peerName: user.name);
                    close(context, user.id);
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
