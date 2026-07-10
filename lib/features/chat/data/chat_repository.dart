import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/network/storage_service.dart';

final storageServiceProvider = Provider((ref) => StorageService());
