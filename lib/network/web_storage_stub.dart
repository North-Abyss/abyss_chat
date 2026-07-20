import 'dart:typed_data';

class WebStorage {
  static Future<void> saveMedia(String id, Uint8List data, String mimeType) async {}
  static Future<String?> getMediaUrl(String id) async => null;
  static Future<int> getMediaSize(String id) async => 0;
  static Future<int> getMediaStorageSize() async => 0;
  static Future<void> clearAllMedia() async {}
  static Future<void> deleteMedia(String id) async {}
  static Future<void> triggerDownload(String id, String fileName) async {}
}
