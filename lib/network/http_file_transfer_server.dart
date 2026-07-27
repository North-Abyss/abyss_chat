import 'dart:io';
import 'package:flutter/foundation.dart';

class HttpFileTransferServer {
  HttpServer? _server;
  final Map<String, String> _activeTransfers = {}; // token -> filePath

  Future<void> start() async {
    if (kIsWeb) return;
    if (_server != null) return;
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 0); // Random port
      _server!.listen(_handleRequest);
      debugPrint('HTTP File Transfer Server running on port ${_server!.port}');
    } catch (e) {
      debugPrint('Failed to start HTTP File Transfer Server: $e');
    }
  }

  void stop() {
    _server?.close(force: true);
    _server = null;
  }

  int? get port => _server?.port;

  String addFile(String filePath, String token) {
    _activeTransfers[token] = filePath;
    return token;
  }

  void removeFile(String token) {
    _activeTransfers.remove(token);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (request.method != 'GET') {
      request.response.statusCode = HttpStatus.methodNotAllowed;
      await request.response.close();
      return;
    }

    final token = request.uri.queryParameters['token'];
    if (token == null || !_activeTransfers.containsKey(token)) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    final filePath = _activeTransfers[token]!;
    final file = File(filePath);
    
    if (!await file.exists()) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    try {
      final stat = await file.stat();
      request.response.headers.contentType = ContentType.binary;
      request.response.headers.contentLength = stat.size;
      request.response.headers.add('Access-Control-Allow-Origin', '*');
      
      await request.response.addStream(file.openRead());
    } catch (e) {
      debugPrint('Error serving file: $e');
      request.response.statusCode = HttpStatus.internalServerError;
    } finally {
      await request.response.close();
    }
  }
}
