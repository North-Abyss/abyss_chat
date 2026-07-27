import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:abyss_chat/network/http_file_transfer_server.dart';
import 'package:abyss_chat/network/file_reader.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class FileTransferProgress {
  final String fileId;
  final String fileName;
  final int totalSize;
  final int bytesTransferred;
  final bool isSending;
  final bool isCompleted;

  double get progress => totalSize == 0 ? 0 : bytesTransferred / totalSize;

  FileTransferProgress({
    required this.fileId,
    required this.fileName,
    required this.totalSize,
    required this.bytesTransferred,
    required this.isSending,
    this.isCompleted = false,
  });
}

class FileTransferService {
  final bool Function(String peerId, Map<String, dynamic> payload) sendData;

  // Streams for progress updates
  final _progressController =
      StreamController<FileTransferProgress>.broadcast();
  Stream<FileTransferProgress> get onProgress => _progressController.stream;

  // State for receiving files
  final Map<String, _ReceivingFile> _receivingFiles = {};

  // Callback when a file finishes receiving
  Function(String fileId, String fileName, Uint8List data)? onFileReceived;
  
  // Callback for file paths (for large files)
  Function(String fileId, String fileName, String filePath)? onFileDownloaded;

  final HttpFileTransferServer _httpServer = HttpFileTransferServer();

  FileTransferService(this.sendData) {
    if (!kIsWeb) {
      _httpServer.start();
    }
  }

  void handleIncomingPayload(Map<String, dynamic> payload) {
    if (payload['type'] == 'file_meta') {
      _handleFileMeta(payload);
    } else if (payload['type'] == 'file_chunk') {
      _handleFileChunk(payload);
    } else if (payload['type'] == 'large_file_meta') {
      _handleLargeFileMeta(payload);
    }
  }

  Future<String?> _getLocalIp() async {
    if (kIsWeb) return null;
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static const int chunkSize = 64 * 1024; // 64KB per chunk

  Future<void> sendFile(
    String peerId,
    String filePath,
    String fileName, {
    String? fileId,
  }) async {
    if (kIsWeb) return; // For Web, use sendFileFromBytes

    if (!await fileExists(filePath)) return;

    final totalSize = await getFileSize(filePath);
    final id = fileId ?? DateTime.now().millisecondsSinceEpoch.toString();

    // Use HTTP server for file transfer
    final ip = await _getLocalIp();
    final port = _httpServer.port;
    if (ip != null && port != null) {
      final token = DateTime.now().millisecondsSinceEpoch.toString();
      _httpServer.addFile(filePath, token);
      final url = 'http://$ip:$port/download?token=$token';

      sendData(peerId, {
        'type': 'large_file_meta',
        'fileId': id,
        'fileName': fileName,
        'totalSize': totalSize,
        'url': url,
      });

      // We immediately mark it as completed for the sender since it's hosted
      _progressController.add(
        FileTransferProgress(
          fileId: id,
          fileName: fileName,
          totalSize: totalSize,
          bytesTransferred: totalSize,
          isSending: true,
          isCompleted: true,
        ),
      );
      return;
    }

    // Fallback to WebRTC chunks (unlikely to reach here if networking is fine)
    sendData(peerId, {
      'type': 'file_meta',
      'fileId': id,
      'fileName': fileName,
      'totalSize': totalSize,
    });

    int bytesSent = 0;
    final stream = await getFileStream(filePath);
    if (stream == null) return;

    await for (final chunk in stream) {
      final base64Chunk = base64Encode(chunk);
      sendData(peerId, {
        'type': 'file_chunk',
        'fileId': id,
        'data': base64Chunk,
      });
      bytesSent += chunk.length;
      _progressController.add(
        FileTransferProgress(
          fileId: id,
          fileName: fileName,
          totalSize: totalSize,
          bytesTransferred: bytesSent,
          isSending: true,
          isCompleted: bytesSent >= totalSize,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 5));
    }
  }

  Future<void> sendFileFromBytes(
    String peerId,
    Uint8List fileBytes,
    String fileName, {
    String? fileId,
  }) async {
    final totalSize = fileBytes.length;
    final id = fileId ?? DateTime.now().millisecondsSinceEpoch.toString();

    // 1. Send Metadata
    sendData(peerId, {
      'type': 'file_meta',
      'fileId': id,
      'fileName': fileName,
      'totalSize': totalSize,
    });

    // 2. Read and Send Chunks
    int bytesSent = 0;
    for (int i = 0; i < totalSize; i += chunkSize) {
      final end = (i + chunkSize < totalSize) ? i + chunkSize : totalSize;
      final chunk = fileBytes.sublist(i, end);
      final base64Chunk = base64Encode(chunk);

      sendData(peerId, {
        'type': 'file_chunk',
        'fileId': id,
        'data': base64Chunk,
      });

      bytesSent += chunk.length;

      _progressController.add(
        FileTransferProgress(
          fileId: id,
          fileName: fileName,
          totalSize: totalSize,
          bytesTransferred: bytesSent,
          isSending: true,
          isCompleted: bytesSent >= totalSize,
        ),
      );

      // Delay to not choke buffer
      await Future.delayed(const Duration(milliseconds: 5));
    }
  }

  void _handleFileMeta(Map<String, dynamic> data) {
    final fileId = data['fileId'];
    _receivingFiles[fileId] = _ReceivingFile(
      fileId: fileId,
      fileName: data['fileName'],
      totalSize: (data['totalSize'] as num).toInt(),
    );
  }

  void _handleFileChunk(Map<String, dynamic> data) {
    final fileId = data['fileId'];
    final receiving = _receivingFiles[fileId];
    if (receiving == null) return;

    final chunkBytes = base64Decode(data['data']);
    receiving.chunks.add(chunkBytes);
    receiving.receivedBytes += chunkBytes.length;

    _progressController.add(
      FileTransferProgress(
        fileId: fileId,
        fileName: receiving.fileName,
        totalSize: receiving.totalSize,
        bytesTransferred: receiving.receivedBytes,
        isSending: false,
        isCompleted: receiving.receivedBytes >= receiving.totalSize,
      ),
    );

    // Check completion
    if (receiving.receivedBytes >= receiving.totalSize) {
      _receivingFiles.remove(fileId);
      final completeData = BytesBuilder();
      for (final c in receiving.chunks) {
        completeData.add(c);
      }
      if (onFileReceived != null) {
        onFileReceived!(fileId, receiving.fileName, completeData.takeBytes());
      }
    }
  }

  void dispose() {
    _progressController.close();
    _httpServer.stop();
  }

  Future<void> _handleLargeFileMeta(Map<String, dynamic> data) async {
    if (kIsWeb) return; // Cannot easily save direct files on Web without UI interaction
    final fileId = data['fileId'];
    final fileName = data['fileName'];
    final totalSize = (data['totalSize'] as num).toInt();
    final url = data['url'];

    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await request.send();
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final savePath = '${tempDir.path}/$fileId-$fileName';
        final file = File(savePath);
        final sink = file.openWrite();

        int receivedBytes = 0;
        await for (var chunk in response.stream) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          _progressController.add(
            FileTransferProgress(
              fileId: fileId,
              fileName: fileName,
              totalSize: totalSize,
              bytesTransferred: receivedBytes,
              isSending: false,
              isCompleted: receivedBytes >= totalSize,
            ),
          );
        }
        await sink.close();
        
        if (onFileDownloaded != null) {
          onFileDownloaded!(fileId, fileName, savePath);
        }
      }
    } catch (e) {
      debugPrint('Error downloading large file: $e');
    }
  }
}

class _ReceivingFile {
  final String fileId;
  final String fileName;
  final int totalSize;
  int receivedBytes = 0;
  final List<Uint8List> chunks = [];

  _ReceivingFile({
    required this.fileId,
    required this.fileName,
    required this.totalSize,
  });
}
