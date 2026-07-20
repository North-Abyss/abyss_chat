// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:typed_data';
import 'package:idb_shim/idb_browser.dart';
import 'dart:html' as html;

class WebStorage {
  static const String _dbName = 'abyss_media.db';
  static const String _storeName = 'media';
  static Database? _db;
  static final Map<String, String> _urlCache = {};

  static Future<Database> _getDb() async {
    if (_db != null) return _db!;
    final idbFactory = idbFactoryBrowser;
    _db = await idbFactory.open(_dbName, version: 1, onUpgradeNeeded: (VersionChangeEvent event) {
      final db = event.database;
      db.createObjectStore(_storeName);
    });
    return _db!;
  }

  static Future<void> saveMedia(String id, Uint8List data, String mimeType) async {
    final db = await _getDb();
    final txn = db.transaction(_storeName, idbModeReadWrite);
    final store = txn.objectStore(_storeName);
    
    // We store as a Dart map with bytes and mimeType
    await store.put({
      'data': data,
      'mimeType': mimeType,
      'size': data.length,
    }, id);
    await txn.completed;
  }

  static Future<String?> getMediaUrl(String id) async {
    if (_urlCache.containsKey(id)) {
      return _urlCache[id];
    }

    final db = await _getDb();
    final txn = db.transaction(_storeName, idbModeReadOnly);
    final store = txn.objectStore(_storeName);
    final value = await store.getObject(id) as Map?;
    if (value != null) {
      final data = value['data'] as Uint8List;
      final mimeType = value['mimeType'] as String;
      
      final blob = html.Blob([data], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      _urlCache[id] = url;
      return url;
    }
    return null;
  }

  static Future<void> triggerDownload(String id, String fileName) async {
    final db = await _getDb();
    final txn = db.transaction(_storeName, idbModeReadOnly);
    final store = txn.objectStore(_storeName);
    final value = await store.getObject(id) as Map?;
    if (value != null) {
      final data = value['data'] as Uint8List;
      final mimeType = value['mimeType'] as String;
      
      final blob = html.Blob([data], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  static Future<int> getMediaSize(String id) async {
    try {
      final db = await _getDb();
      final txn = db.transaction(_storeName, idbModeReadOnly);
      final store = txn.objectStore(_storeName);
      final value = await store.getObject(id) as Map?;
      if (value != null) {
        return (value['size'] as int?) ?? 0;
      }
    } catch (e) {
      // ignore
    }
    return 0;
  }

  static Future<int> getMediaStorageSize() async {
    int totalSize = 0;
    try {
      final db = await _getDb();
      final txn = db.transaction(_storeName, idbModeReadOnly);
      final store = txn.objectStore(_storeName);
      final keys = await store.getAllKeys();
      for (final key in keys) {
        final value = await store.getObject(key) as Map?;
        if (value != null) {
          totalSize += (value['size'] as int?) ?? 0;
        }
      }
    } catch (e) {
      // ignore
    }
    return totalSize;
  }

  static Future<void> clearAllMedia() async {
    final db = await _getDb();
    final txn = db.transaction(_storeName, idbModeReadWrite);
    final store = txn.objectStore(_storeName);
    await store.clear();
    await txn.completed;

    for (final url in _urlCache.values) {
      html.Url.revokeObjectUrl(url);
    }
    _urlCache.clear();
  }

  static Future<void> deleteMedia(String id) async {
    final db = await _getDb();
    final txn = db.transaction(_storeName, idbModeReadWrite);
    final store = txn.objectStore(_storeName);
    await store.delete(id);
    await txn.completed;

    if (_urlCache.containsKey(id)) {
      html.Url.revokeObjectUrl(_urlCache[id]!);
      _urlCache.remove(id);
    }
  }
}
