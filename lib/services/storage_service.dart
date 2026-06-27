import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:abyss_chat/models/chat_thread.dart';
import 'package:abyss_chat/models/user.dart';
import 'package:abyss_chat/models/call_log.dart';

class StorageService {
  static const String _threadsKey = 'abyss_chat_threads';
  static const String _contactsKey = 'abyss_chat_contacts';
  static const String _callLogsKey = 'abyss_chat_call_logs';

  Future<List<ChatThread>> loadThreads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? contents = prefs.getString(_threadsKey);
      if (contents == null || contents.isEmpty) {
        return [];
      }
      
      final List<dynamic> parsed = jsonDecode(contents);
      return parsed.map((e) => ChatThread.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error loading data from SharedPreferences: $e');
      return [];
    }
  }

  Future<void> saveThreads(List<ChatThread> threads) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonStr = jsonEncode(threads.map((t) => t.toJson()).toList());
      await prefs.setString(_threadsKey, jsonStr);
    } catch (e) {
      debugPrint('Error saving data to SharedPreferences: $e');
    }
  }

  Future<void> saveUserProfile(String id, String name, {int avatarIcon = 0xe491, int avatarColor = 0xFF6750A4}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('my_id', id);
    await prefs.setString('my_name', name);
    await prefs.setInt('my_avatar_icon', avatarIcon);
    await prefs.setInt('my_avatar_color', avatarColor);
  }

  Future<Map<String, dynamic>?> loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('my_id');
    final name = prefs.getString('my_name');
    final icon = prefs.getInt('my_avatar_icon') ?? 0xe491;
    final color = prefs.getInt('my_avatar_color') ?? 0xFF6750A4;
    
    if (id != null && name != null) {
      if (id.startsWith('#')) {
        id = id.substring(1);
        await saveUserProfile(id, name, avatarIcon: icon, avatarColor: color);
      }
      return {
        'id': id, 
        'name': name,
        'avatarIcon': icon,
        'avatarColor': color,
      };
    }
    return null;
  }

  // Contacts
  Future<List<User>> loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_contactsKey);
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => User.fromJson(e)).toList();
  }

  Future<void> saveContacts(List<User> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = contacts.map((c) => c.toJson()).toList();
    await prefs.setString(_contactsKey, jsonEncode(jsonList));
  }

  // Call Logs
  Future<List<CallLog>> loadCallLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_callLogsKey);
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => CallLog.fromJson(e)).toList();
  }

  Future<void> saveCallLogs(List<CallLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = logs.map((l) => l.toJson()).toList();
    await prefs.setString(_callLogsKey, jsonEncode(jsonList));
  }
}
