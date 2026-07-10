import 'dart:async';
import 'dart:io';

Future<Stream<List<int>>?> getFileStream(String path) async {
  final file = File(path);
  if (await file.exists()) {
    return file.openRead();
  }
  return null;
}

Future<int> getFileSize(String path) async {
  return await File(path).length();
}

Future<bool> fileExists(String path) async {
  return await File(path).exists();
}
