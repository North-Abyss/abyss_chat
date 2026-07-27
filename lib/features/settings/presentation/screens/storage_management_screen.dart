import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'package:abyss_chat/features/settings/domain/settings_controller.dart';
import 'package:abyss_chat/core/widgets/abyss_snackbar.dart';
import 'package:abyss_chat/features/chat/data/chat_repository.dart';
import 'package:abyss_chat/features/chat/domain/chat_controller.dart';
import 'package:abyss_chat/core/widgets/user_avatar.dart';

class StorageManagementScreen extends ConsumerStatefulWidget {
  const StorageManagementScreen({super.key});

  @override
  ConsumerState<StorageManagementScreen> createState() =>
      _StorageManagementScreenState();
}

class _StorageManagementScreenState
    extends ConsumerState<StorageManagementScreen> {
  bool _isLoading = true;
  int _mediaUsage = 0;
  int _chatUsage = 0;
  Map<String, int> _chatStorageUsage = {};

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    setState(() => _isLoading = true);
    final storage = ref.read(storageServiceProvider);
    _mediaUsage = await storage.getMediaStorageUsage();
    _chatUsage = await storage.getChatStorageUsage();
    final threads = ref.read(chatThreadsProvider).value ?? [];
    _chatStorageUsage = await storage.getStorageUsageByChat(threads);
    if (mounted) setState(() => _isLoading = false);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<String?> _showPasswordDialog(BuildContext context, String title, String action) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Encryption Password',
            border: const OutlineInputBorder(),
            helperText: 'Keep this safe! If you lose it, your backup cannot be restored.',
            helperMaxLines: 2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, controller.text),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final password = await _showPasswordDialog(context, 'Export Backup', 'Export');
    if (password == null || password.isEmpty) return;

    if (!context.mounted) return;
    
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Generating backup...'),
          ],
        ),
      ),
    );

    try {
      final backupService = ref.read(backupServiceProvider);
      await backupService.exportBackup(password);
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        AbyssSnackBar.show(context, 'Backup exported successfully!', type: SnackBarType.success);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        AbyssSnackBar.show(context, 'Export failed: $e', type: SnackBarType.error);
      }
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final backupService = ref.read(backupServiceProvider);
    
    // 1. Pick file first
    Uint8List? fileBytes;
    try {
      fileBytes = await backupService.pickBackupFile();
    } catch (e) {
      if (context.mounted) AbyssSnackBar.show(context, 'Failed to read file: $e', type: SnackBarType.error);
      return;
    }

    if (fileBytes == null) return; // Cancelled

    if (!context.mounted) return;

    // 2. Ask for password
    final password = await _showPasswordDialog(context, 'Import Backup', 'Restore');
    if (password == null || password.isEmpty) return;

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Restoring backup...'),
          ],
        ),
      ),
    );

    try {
      await backupService.restoreBackup(fileBytes, password);
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => AlertDialog(
            title: const Text('Restore Complete'),
            content: const Text('Your backup has been restored successfully! The app needs to restart to load your data.'),
            actions: [
              FilledButton(
                onPressed: () {
                  // The user can manually restart or we can force hot restart in some environments
                  // On web, they can just refresh
                  Navigator.pop(c);
                  AbyssSnackBar.show(context, 'Please restart the app to see your restored data.', type: SnackBarType.info);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        AbyssSnackBar.show(context, 'Restore failed. Incorrect password or corrupted file.', type: SnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Storage')),
      body: settingsAsync.when(
        data: (settings) {
          final totalUsage = _mediaUsage + _chatUsage;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Storage Usage',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: cs.primary),
              ),
              const SizedBox(height: 16),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatBytes(totalUsage),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Total App Usage',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stacked Bar Chart
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 12,
                    child: Row(
                      children: [
                        if (_mediaUsage > 0)
                          Expanded(
                            flex: _mediaUsage,
                            child: Container(color: cs.primary),
                          ),
                        if (_chatUsage > 0)
                          Expanded(
                            flex: _chatUsage,
                            child: Container(color: cs.secondary),
                          ),
                        if (totalUsage == 0)
                          Expanded(
                            child: Container(color: cs.surfaceContainerHighest),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Media: ${_formatBytes(_mediaUsage)}'),
                    const Spacer(),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: cs.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Chats: ${_formatBytes(_chatUsage)}'),
                  ],
                ),

                const SizedBox(height: 32),

                FilledButton.tonalIcon(
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Clear All Media Cache'),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Clear All Media?'),
                        content: const Text(
                          'This will delete all downloaded photos, videos, and audio. Text messages will remain.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: cs.error,
                            ),
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await ref.read(storageServiceProvider).clearAllMedia();
                      await _loadStorageInfo();
                      if (context.mounted) {
                        AbyssSnackBar.show(
                          context,
                          'Media cache cleared successfully!',
                          type: SnackBarType.success,
                        );
                      }
                    }
                  },
                ),
              ],

              const Divider(height: 48),

              Text(
                'Data Backup & Recovery',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: cs.primary),
              ),
              const SizedBox(height: 8),
              Text(
                'Export your text data (chats, contacts, call logs) to an encrypted .abysschat file. Media files are NOT included in backups.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Import Backup'),
                      onPressed: () => _importBackup(context, ref),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.upload),
                      label: const Text('Export Backup'),
                      onPressed: () => _exportBackup(context, ref),
                    ),
                  ),
                ],
              ),

              const Divider(height: 48),

              Text(
                'Media Auto-Download',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: cs.primary),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('When using Wi-Fi'),
                value: settings.mediaAutoDownloadWifi,
                onChanged: (val) {
                  ref
                      .read(appSettingsProvider.notifier)
                      .updateSettings(
                        settings.copyWith(mediaAutoDownloadWifi: val),
                      );
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('When using Cellular'),
                value: settings.mediaAutoDownloadCellular,
                onChanged: (val) {
                  ref
                      .read(appSettingsProvider.notifier)
                      .updateSettings(
                        settings.copyWith(mediaAutoDownloadCellular: val),
                      );
                },
              ),

              const Divider(height: 48),

              Text(
                'Chat Breakdown',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: cs.primary),
              ),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, child) {
                  final threadsAsync = ref.watch(chatThreadsProvider);
                  return threadsAsync.when(
                    data: (threads) {
                      final sortedThreads =
                          threads
                              .where((t) => (_chatStorageUsage[t.id] ?? 0) > 0)
                              .toList()
                            ..sort(
                              (a, b) => (_chatStorageUsage[b.id] ?? 0)
                                  .compareTo(_chatStorageUsage[a.id] ?? 0),
                            );

                      if (sortedThreads.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No media stored for individual chats.'),
                        );
                      }

                      return Column(
                        children: sortedThreads.map((thread) {
                          final usage = _chatStorageUsage[thread.id] ?? 0;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: UserAvatar(user: thread.peer, radius: 20),
                            title: Text(thread.peer.name),
                            subtitle: Text(
                              '${thread.messages.length} messages',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatBytes(usage),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: cs.error,
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        title: Text(
                                          'Clear Media for ${thread.peer.name}?',
                                        ),
                                        content: const Text(
                                          'This will delete all downloaded photos, videos, and audio for this chat. Text messages will remain.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(c, false),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            style: FilledButton.styleFrom(
                                              backgroundColor: cs.error,
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(c, true),
                                            child: const Text('Clear'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await ref
                                          .read(storageServiceProvider)
                                          .clearMediaForChat(thread);
                                      await _loadStorageInfo();
                                      if (context.mounted) {
                                        AbyssSnackBar.show(
                                          context,
                                          'Media cleared for ${thread.peer.name}.',
                                          type: SnackBarType.success,
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (err, stack) => Text('Error: $err'),
                  );
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
