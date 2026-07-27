import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:abyss_chat/network/storage_service.dart';
import 'package:abyss_chat/features/chat/domain/models/chat_thread.dart';
import 'package:abyss_chat/features/calling/domain/models/call_log.dart';
import 'dart:io';

class BackupService {
  final StorageService storageService;

  BackupService(this.storageService);

  encrypt.Key _deriveKey(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(digest.bytes));
  }

  Future<void> exportBackup(String password) async {
    final profile = await storageService.loadUserProfile();
    final threads = await storageService.loadThreads();
    final callLogs = await storageService.loadCallLogs();
    
    final backupData = {
      'version': 1,
      'profile': profile,
      'threads': threads.map((t) => t.toJson()).toList(),
      'callLogs': callLogs.map((c) => c.toJson()).toList(),
    };

    final plainText = jsonEncode(backupData);

    final key = _deriveKey(password);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
    );

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    
    final combinedBytes = Uint8List(16 + encrypted.bytes.length);
    combinedBytes.setAll(0, iv.bytes);
    combinedBytes.setAll(16, encrypted.bytes);

    try {
      final fileName = 'abyss_backup_${DateTime.now().millisecondsSinceEpoch}.abysschat';
      
      if (kIsWeb) {
        await FilePicker.saveFile(
          dialogTitle: 'Save Backup',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['abysschat'],
          bytes: combinedBytes,
        );
      } else {
        final path = await FilePicker.saveFile(
          dialogTitle: 'Save Backup',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['abysschat'],
          bytes: combinedBytes,
        );

        if (path != null) {
          final file = File(path);
          await file.writeAsBytes(combinedBytes);
        }
      }
    } catch (e) {
      debugPrint('Export backup failed: $e');
      rethrow;
    }
  }

  Future<Uint8List?> pickBackupFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['abysschat'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    Uint8List? fileBytes = result.files.first.bytes;
    if (fileBytes == null && !kIsWeb && result.files.first.path != null) {
      final file = File(result.files.first.path!);
      fileBytes = await file.readAsBytes();
    }
    return fileBytes;
  }

  Future<void> restoreBackup(Uint8List fileBytes, String password) async {
    try {
      if (fileBytes.length < 16) {
        throw Exception('Invalid or corrupted backup file.');
      }

      final key = _deriveKey(password);
      
      final ivBytes = fileBytes.sublist(0, 16);
      final iv = encrypt.IV(ivBytes);

      final encryptedBytes = fileBytes.sublist(16);
      final encryptedData = encrypt.Encrypted(encryptedBytes);

      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
      );

      final decrypted = encrypter.decrypt(encryptedData, iv: iv);
      final Map<String, dynamic> backupData = jsonDecode(decrypted);

      if (backupData['profile'] != null) {
        final profile = backupData['profile'] as Map<String, dynamic>;
        await storageService.saveUserProfile(
          profile['id'],
          profile['name'],
          username: profile['username'],
          avatarIcon: profile['avatarIcon'],
          avatarColor: profile['avatarColor'],
          profileImagePath: profile['profileImagePath'], 
        );
      }

      if (backupData['threads'] != null) {
        final threadsList = backupData['threads'] as List<dynamic>;
        final threads = threadsList.map((e) => ChatThread.fromJson(e)).toList();
        await storageService.saveThreads(threads);
      }

      if (backupData['callLogs'] != null) {
        final callLogsList = backupData['callLogs'] as List<dynamic>;
        final callLogs = callLogsList.map((e) => CallLog.fromJson(e)).toList();
        await storageService.saveCallLogs(callLogs);
      }
    } catch (e) {
      debugPrint('Restore backup failed: $e');
      rethrow; 
    }
  }
}
