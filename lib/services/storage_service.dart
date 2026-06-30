import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:abyss_chat/models/chat_thread.dart';
import 'package:abyss_chat/models/user.dart';
import 'package:abyss_chat/models/call_log.dart';
import 'package:abyss_chat/services/crypto_service.dart';

class StorageService {
  static const String _threadsFile = 'conversations.abyss';
  static const String _contactsFile = 'contacts.abyss';
  static const String _callLogsFile = 'call_logs.abyss';
  static const String _blockedFile = 'blocked.abyss';

  Future<String> _getAppDirPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final abyssDir = Directory('${dir.path}/AbyssChat');
    if (!await abyssDir.exists()) {
      await abyssDir.create(recursive: true);
    }
    return abyssDir.path;
  }

  Future<File> _getFile(String filename) async {
    final path = await _getAppDirPath();
    return File('$path/$filename');
  }

  Future<String?> _readEncryptedFile(String filename) async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final ciphertext = prefs.getString('web_$filename');
        if (ciphertext == null || ciphertext.isEmpty) return null;
        return CryptoService.decryptData(ciphertext);
      }
      
      final file = await _getFile(filename);
      if (!await file.exists()) return null;
      final ciphertext = await file.readAsString();
      if (ciphertext.isEmpty) return null;
      return CryptoService.decryptData(ciphertext);
    } catch (e) {
      debugPrint('Error reading encrypted file $filename: $e');
      try {
        if (kIsWeb) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('web_$filename');
        } else {
          final file = await _getFile(filename);
          if (await file.exists()) await file.delete();
        }
      } catch (_) {}
      return null;
    }
  }

  Future<void> _writeEncryptedFile(String filename, String plaintext) async {
    try {
      final ciphertext = CryptoService.encryptData(plaintext);
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('web_$filename', ciphertext);
      } else {
        final file = await _getFile(filename);
        await file.writeAsString(ciphertext);
      }
    } catch (e) {
      debugPrint('Error writing encrypted file $filename: $e');
    }
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    if (!kIsWeb) {
      try {
        final path = await _getAppDirPath();
        final dir = Directory(path);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      } catch (e) {
        debugPrint('Error clearing app data dir: $e');
      }
    }
  }

  // --- Threads ---
  Future<List<ChatThread>> loadThreads() async {
    final jsonStr = await _readEncryptedFile(_threadsFile);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> parsed = jsonDecode(jsonStr);
      return parsed.map((e) => ChatThread.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error parsing threads: $e');
      return [];
    }
  }

  Future<void> saveThreads(List<ChatThread> threads) async {
    final jsonStr = jsonEncode(threads.map((t) => t.toJson()).toList());
    await _writeEncryptedFile(_threadsFile, jsonStr);
  }

  // --- Contacts ---
  Future<List<User>> loadContacts() async {
    final data = await _readEncryptedFile(_contactsFile);
    if (data == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveContacts(List<User> contacts) async {
    final jsonList = contacts.map((c) => c.toJson()).toList();
    await _writeEncryptedFile(_contactsFile, jsonEncode(jsonList));
  }
  
  Future<List<String>> loadBlockedPeers() async {
    final data = await _readEncryptedFile(_blockedFile);
    if (data == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.cast<String>();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveBlockedPeers(List<String> blockedIds) async {
    await _writeEncryptedFile(_blockedFile, jsonEncode(blockedIds));
  }

  // --- Call Logs ---
  Future<List<CallLog>> loadCallLogs() async {
    final jsonStr = await _readEncryptedFile(_callLogsFile);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> parsed = jsonDecode(jsonStr);
      return parsed.map((e) => CallLog.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error parsing call logs: $e');
      return [];
    }
  }

  Future<void> saveCallLogs(List<CallLog> logs) async {
    final jsonStr = jsonEncode(logs.map((l) => l.toJson()).toList());
    await _writeEncryptedFile(_callLogsFile, jsonStr);
  }

  // --- Profile Image ---
  Future<String> saveProfileImage(String userId, File imageFile) async {
    if (kIsWeb) {
      return imageFile.path; // Web typically returns an object URL from FilePicker
    }
    final path = await _getAppDirPath();
    final profileDir = Directory('$path/profiles');
    if (!await profileDir.exists()) {
      await profileDir.create(recursive: true);
    }
    
    // We get file extension
    final ext = imageFile.path.split('.').last;
    final targetPath = '${profileDir.path}/$userId.$ext';
    
    await imageFile.copy(targetPath);
    return targetPath;
  }

  // --- User Profile (Unencrypted/Prefs) ---
  Future<void> saveUserProfile(String id, String name, {int avatarIcon = 0xe491, int avatarColor = 0xFF6750A4, String? profileImagePath}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('my_id', id);
    await prefs.setString('my_name', name);
    await prefs.setInt('my_avatar_icon', avatarIcon);
    await prefs.setInt('my_avatar_color', avatarColor);
    if (profileImagePath != null) {
      await prefs.setString('my_profile_image', profileImagePath);
    } else {
      await prefs.remove('my_profile_image');
    }
  }

  Future<Map<String, dynamic>?> loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('my_id');
    final name = prefs.getString('my_name');
    final icon = prefs.getInt('my_avatar_icon') ?? 0xe491;
    final color = prefs.getInt('my_avatar_color') ?? 0xFF6750A4;
    final imagePath = prefs.getString('my_profile_image');
    
    if (id != null && name != null) {
      if (id.startsWith('#')) {
        id = id.substring(1);
        await saveUserProfile(id, name, avatarIcon: icon, avatarColor: color, profileImagePath: imagePath);
      }
      return {
        'id': id, 
        'name': name,
        'avatarIcon': icon,
        'avatarColor': color,
        'profileImagePath': imagePath,
      };
    }
    return null;
  }
}
