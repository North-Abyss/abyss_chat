import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/features/contacts/domain/models/user.dart';
import 'package:abyss_chat/features/chat/data/chat_repository.dart';
import 'package:abyss_chat/features/chat/domain/chat_controller.dart';

class ContactsNotifier extends AsyncNotifier<List<User>> {
  @override
  Future<List<User>> build() async {
    final storage = ref.watch(storageServiceProvider);
    final contacts = await storage.loadContacts();
    
    // Automatically clean up any accidental "self" contacts (duplicate bug)
    final profile = await storage.loadUserProfile();
    if (profile != null && profile['id'] != null) {
      final myId = profile['id'] as String;
      final filtered = contacts.where((c) => c.id != myId).toList();
      if (filtered.length != contacts.length) {
        storage.saveContacts(filtered);
        return filtered;
      }
    }
    return contacts;
  }

  void upsertContact(User user) {
    if (!state.hasValue) return;
    final contacts = List<User>.from(state.value!);
    final idx = contacts.indexWhere((c) => c.id == user.id);
    if (idx == -1) {
      contacts.add(user);
      state = AsyncData(contacts);
      ref.read(storageServiceProvider).saveContacts(contacts);
    } else {
      final existing = contacts[idx];
      bool shouldUpdate = false;
      
      if (user.profileUpdatedAt != null) {
        if (existing.profileUpdatedAt == null || user.profileUpdatedAt!.isAfter(existing.profileUpdatedAt!)) {
          shouldUpdate = true;
        }
      } else {
        if (existing.name != user.name || 
            existing.avatarIcon != user.avatarIcon || 
            existing.avatarColor != user.avatarColor || 
            existing.profileImagePath != user.profileImagePath) {
          shouldUpdate = true;
        }
      }

      // Always update networking info if it changes, regardless of profile timestamp
      if (existing.ipAddress != user.ipAddress || existing.port != user.port) {
        shouldUpdate = true;
      }

      if (shouldUpdate) {
        contacts[idx] = user;
        state = AsyncData(contacts);
        ref.read(storageServiceProvider).saveContacts(contacts);
      }
    }
  }

  void deleteContact(String id) {
    if (!state.hasValue) return;
    final contacts = List<User>.from(state.value!);
    contacts.removeWhere((c) => c.id == id);
    state = AsyncData(contacts);
    ref.read(storageServiceProvider).saveContacts(contacts);
    
    // Also delete chat thread history
    ref.read(chatThreadsProvider.notifier).deleteThread(id);
    
    // Add to deleted contacts so mDNS doesn't auto-re-add them
    ref.read(deletedContactsProvider.notifier).markDeleted(id);
  }

  void blockContact(String id) {
    ref.read(blockedContactsProvider.notifier).blockPeer(id);
    deleteContact(id); // Blocking also removes from contacts and deletes thread
  }
}

class DeletedContactsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    return await ref.watch(storageServiceProvider).loadDeletedPeers();
  }

  void markDeleted(String id) {
    if (!state.hasValue) return;
    final deleted = List<String>.from(state.value!);
    if (!deleted.contains(id)) {
      deleted.add(id);
      state = AsyncData(deleted);
      ref.read(storageServiceProvider).saveDeletedPeers(deleted);
    }
  }
}

final deletedContactsProvider = AsyncNotifierProvider<DeletedContactsNotifier, List<String>>(() => DeletedContactsNotifier());

class BlockedContactsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    return await ref.watch(storageServiceProvider).loadBlockedPeers();
  }

  void blockPeer(String id) {
    if (!state.hasValue) return;
    final blocked = List<String>.from(state.value!);
    if (!blocked.contains(id)) {
      blocked.add(id);
      state = AsyncData(blocked);
      ref.read(storageServiceProvider).saveBlockedPeers(blocked);
    }
  }
}

final blockedContactsProvider = AsyncNotifierProvider<BlockedContactsNotifier, List<String>>(() => BlockedContactsNotifier());

final contactsProvider = AsyncNotifierProvider<ContactsNotifier, List<User>>(() => ContactsNotifier());
