import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/network/storage_service.dart';
import 'package:abyss_chat/network/backup_service.dart';

final storageServiceProvider = Provider((ref) => StorageService());
final backupServiceProvider = Provider((ref) => BackupService(ref.read(storageServiceProvider)));
