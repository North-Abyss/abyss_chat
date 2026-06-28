import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CryptoService {
  static encrypt.Key? _key;
  static final _random = Random.secure();

  static Future<void> init(String userId) async {
    if (_key != null) return;
    
    final prefs = await SharedPreferences.getInstance();
    String? saltHex = prefs.getString('device_salt');
    
    if (saltHex == null) {
      // Generate a new 16-byte salt
      final saltBytes = List<int>.generate(16, (i) => _random.nextInt(256));
      saltHex = saltBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      await prefs.setString('device_salt', saltHex);
    }
    
    // Derive key using SHA-256 on (userId + salt)
    final input = utf8.encode(userId + saltHex);
    final digest = sha256.convert(input);
    _key = encrypt.Key(Uint8List.fromList(digest.bytes));
  }

  static String encryptData(String plaintext) {
    if (_key == null) throw Exception('CryptoService not initialized');
    
    // Generate random 16-byte IV for AES-CBC
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(_key!, mode: encrypt.AESMode.cbc, padding: 'PKCS7'));
    
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    
    // Prepend IV to ciphertext (Base64)
    final combined = iv.bytes + encrypted.bytes;
    return base64Encode(combined);
  }

  static String decryptData(String ciphertextBase64) {
    if (_key == null) throw Exception('CryptoService not initialized');
    
    final combined = base64Decode(ciphertextBase64);
    if (combined.length < 16) throw Exception('Invalid ciphertext length');
    
    // Extract IV (first 16 bytes)
    final ivBytes = combined.sublist(0, 16);
    final iv = encrypt.IV(Uint8List.fromList(ivBytes));
    
    // Extract actual ciphertext
    final encryptedBytes = combined.sublist(16);
    final encrypted = encrypt.Encrypted(Uint8List.fromList(encryptedBytes));
    
    final encrypter = encrypt.Encrypter(encrypt.AES(_key!, mode: encrypt.AESMode.cbc, padding: 'PKCS7'));
    return encrypter.decrypt(encrypted, iv: iv);
  }
}
