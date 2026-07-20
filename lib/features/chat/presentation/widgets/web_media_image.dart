import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:abyss_chat/features/chat/domain/models/message.dart';
import 'package:abyss_chat/network/web_storage.dart';

class WebMediaImage extends StatefulWidget {
  final Message msg;
  final BoxFit fit;
  
  const WebMediaImage({super.key, required this.msg, this.fit = BoxFit.cover});

  @override
  State<WebMediaImage> createState() => _WebMediaImageState();
}

class _WebMediaImageState extends State<WebMediaImage> {
  String? _blobUrl;

  @override
  void initState() {
    super.initState();
    _resolveUrl();
  }

  @override
  void didUpdateWidget(WebMediaImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.msg.fileData != widget.msg.fileData) {
      _resolveUrl();
    }
  }

  void _resolveUrl() {
    if (kIsWeb && widget.msg.fileData != null && widget.msg.fileData!.startsWith('web_idb:')) {
      final id = widget.msg.fileData!.split(':')[1];
      WebStorage.getMediaUrl(id).then((url) {
        if (mounted) {
          setState(() {
            _blobUrl = url;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.msg.fileData != null && widget.msg.fileData!.startsWith('web_idb:')) {
      if (_blobUrl == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return Image.network(_blobUrl!, fit: widget.fit);
    }

    // Fallbacks
    if (widget.msg.fileData != null && widget.msg.fileData!.startsWith('http')) {
       if (widget.msg.fileData!.toLowerCase().endsWith('.gif')) {
          // using Image.network for gif or GifView? We'll assume GifPlayer exists.
          return Image.network(widget.msg.fileData!, fit: widget.fit);
       }
       return CachedNetworkImage(imageUrl: widget.msg.fileData!, fit: widget.fit);
    }
    if (widget.msg.fileData != null && widget.msg.fileData!.isNotEmpty) {
      try {
        if (widget.msg.fileData!.startsWith('data:')) {
           final b64 = widget.msg.fileData!.split(',').last;
           return Image.memory(base64Decode(b64), fit: widget.fit);
        }
        return Image.memory(base64Decode(widget.msg.fileData!), fit: widget.fit);
      } catch (e) {
        debugPrint('WebMediaImage base64 decode error: $e');
        return const Icon(Icons.broken_image);
      }
    }
    if (widget.msg.localFilePath != null && !kIsWeb) {
      return Image.file(File(widget.msg.localFilePath!), fit: widget.fit);
    }
    return const Icon(Icons.broken_image);
  }
}
