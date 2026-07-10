import 'dart:async';
import 'dart:convert';
import 'package:abyss_chat/network/file_reader.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:abyss_chat/network/peerdart_service.dart';

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
  final PeerDartService _peerService;
  
  // Streams for progress updates
  final _progressController = StreamController<FileTransferProgress>.broadcast();
  Stream<FileTransferProgress> get onProgress => _progressController.stream;

  // State for receiving files
  final Map<String, _ReceivingFile> _receivingFiles = {};
  
  // Callback when a file finishes receiving
  Function(String fileId, String fileName, Uint8List data)? onFileReceived;

  FileTransferService(this._peerService) {
    // Listen to incoming raw data messages from peerService
    _peerService.onDataMessage.listen((payload) {
      if (payload['type'] == 'file_meta') {
        _handleFileMeta(payload);
      } else if (payload['type'] == 'file_chunk') {
        _handleFileChunk(payload);
      }
    });
  }

  static const int chunkSize = 64 * 1024; // 64KB per chunk

  Future<void> sendFile(String peerId, String filePath, String fileName) async {
    if (kIsWeb) return; // For Web, use sendFileFromBytes
    
    if (!await fileExists(filePath)) return;
    
    final totalSize = await getFileSize(filePath);
    final fileId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // 1. Send Metadata
    _peerService.sendCustomData(peerId, {
      'type': 'file_meta',
      'fileId': fileId,
      'fileName': fileName,
      'totalSize': totalSize,
    });
    
    // 2. Read and Send Chunks
    int bytesSent = 0;
    final stream = await getFileStream(filePath);
    if (stream == null) return;
    
    await for (final chunk in stream) {
      final base64Chunk = base64Encode(chunk);
      
      _peerService.sendCustomData(peerId, {
        'type': 'file_chunk',
        'fileId': fileId,
        'data': base64Chunk,
      });
      
      bytesSent += chunk.length;
      
      // Update progress
      _progressController.add(FileTransferProgress(
        fileId: fileId,
        fileName: fileName,
        totalSize: totalSize,
        bytesTransferred: bytesSent,
        isSending: true,
        isCompleted: bytesSent >= totalSize,
      ));
      
      // Add a tiny delay to not choke the WebRTC data channel buffer
      await Future.delayed(const Duration(milliseconds: 5));
    }
  }

  Future<void> sendFileFromBytes(String peerId, Uint8List fileBytes, String fileName) async {
    final totalSize = fileBytes.length;
    final fileId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // 1. Send Metadata
    _peerService.sendCustomData(peerId, {
      'type': 'file_meta',
      'fileId': fileId,
      'fileName': fileName,
      'totalSize': totalSize,
    });
    
    // 2. Read and Send Chunks
    int bytesSent = 0;
    for (int i = 0; i < totalSize; i += chunkSize) {
      final end = (i + chunkSize < totalSize) ? i + chunkSize : totalSize;
      final chunk = fileBytes.sublist(i, end);
      final base64Chunk = base64Encode(chunk);
      
      _peerService.sendCustomData(peerId, {
        'type': 'file_chunk',
        'fileId': fileId,
        'data': base64Chunk,
      });
      
      bytesSent += chunk.length;
      
      _progressController.add(FileTransferProgress(
        fileId: fileId,
        fileName: fileName,
        totalSize: totalSize,
        bytesTransferred: bytesSent,
        isSending: true,
        isCompleted: bytesSent >= totalSize,
      ));
      
      // Delay to not choke buffer
      await Future.delayed(const Duration(milliseconds: 5));
    }
  }

  void _handleFileMeta(Map<String, dynamic> data) {
    final fileId = data['fileId'];
    _receivingFiles[fileId] = _ReceivingFile(
      fileId: fileId,
      fileName: data['fileName'],
      totalSize: data['totalSize'],
    );
  }

  void _handleFileChunk(Map<String, dynamic> data) {
    final fileId = data['fileId'];
    final receiving = _receivingFiles[fileId];
    if (receiving == null) return;
    
    final chunkBytes = base64Decode(data['data']);
    receiving.chunks.add(chunkBytes);
    receiving.receivedBytes += chunkBytes.length;
    
    _progressController.add(FileTransferProgress(
      fileId: fileId,
      fileName: receiving.fileName,
      totalSize: receiving.totalSize,
      bytesTransferred: receiving.receivedBytes,
      isSending: false,
      isCompleted: receiving.receivedBytes >= receiving.totalSize,
    ));
    
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
