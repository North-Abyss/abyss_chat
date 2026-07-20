import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/core/theme/theme_provider.dart';
import 'package:abyss_chat/features/chat/domain/chat_controller.dart';
import 'package:abyss_chat/features/auth/presentation/login_screen.dart';
import 'package:abyss_chat/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:abyss_chat/core/widgets/user_avatar.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:abyss_chat/app/layout_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:abyss_chat/network/notification_service.dart';
import 'package:abyss_chat/network/crypto_service.dart';
import 'package:abyss_chat/features/settings/domain/settings_controller.dart';
import 'package:abyss_chat/features/settings/presentation/widgets/about_abyss_dialog.dart';
import 'package:abyss_chat/features/chat/data/chat_repository.dart';
import 'package:abyss_chat/features/calling/domain/call_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:abyss_chat/features/settings/presentation/screens/storage_management_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, dynamic profile) {
    final nameController = TextEditingController(text: profile.name);
    int selectedIcon = profile.avatarIcon;
    int selectedColor = profile.avatarColor;

    final icons = [Icons.person, Icons.face, Icons.pets, Icons.rocket_launch, Icons.star, Icons.local_florist, Icons.sports_esports, Icons.music_note];
    final colors = [
      Colors.black,
      Colors.white,
      ...predefinedThemes.values,
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Profile'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (profile.profileImagePath != null) ...[
                      const Text('Profile Photo', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: FileImage(File(profile.profileImagePath!)),
                          ),
                          Positioned(
                            right: -10,
                            top: -10,
                            child: IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () {
                                ref.read(chatThreadsProvider.notifier).updateMyProfile(nameController.text, selectedIcon, selectedColor, removeImage: true);
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    FilledButton.icon(
                      onPressed: () async {
                        String? imagePath;
                        if (Platform.isAndroid || Platform.isIOS) {
                          final picker = ImagePicker();
                          final xfile = await picker.pickImage(source: ImageSource.gallery);
                          imagePath = xfile?.path;
                        } else {
                          final result = await FilePicker.pickFiles(type: FileType.image);
                          imagePath = result?.files.single.path;
                        }

                        if (imagePath != null) {
                          final savedPath = await ref.read(storageServiceProvider).saveProfileImage(profile.id, File(imagePath));
                          ref.read(chatThreadsProvider.notifier).updateMyProfile(nameController.text, selectedIcon, selectedColor, newImagePath: savedPath);
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.upload),
                      label: const Text('Upload Photo'),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Display Name'),
                    ),
                    const SizedBox(height: 24),
                    const Text('Avatar Icon', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: icons.map((icon) {
                        return GestureDetector(
                          onTap: () => setState(() => selectedIcon = icon.codePoint),
                          child: CircleAvatar(
                            backgroundColor: selectedIcon == icon.codePoint ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Icon(icon, color: selectedIcon == icon.codePoint ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text('Avatar Color', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: colors.map((color) {
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = color.toARGB32()),
                          child: CircleAvatar(
                            backgroundColor: color,
                            child: selectedColor == color.toARGB32() ? const Icon(Icons.check, color: Colors.white) : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      ref.read(chatThreadsProvider.notifier).updateMyProfile(name, selectedIcon, selectedColor);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showCustomColorPicker(BuildContext context, WidgetRef ref) {
    final customColors = <Color>[
      const Color(0xFF1E88E5), // Blue
      const Color(0xFF43A047), // Green
      const Color(0xFFE53935), // Red
      const Color(0xFFFB8C00), // Orange
      const Color(0xFF8E24AA), // Purple
      const Color(0xFF00ACC1), // Cyan
      const Color(0xFF3949AB), // Indigo
      const Color(0xFFD81B60), // Pink
      const Color(0xFF00897B), // Teal
      const Color(0xFF546E7A), // Blue Grey
      const Color(0xFF6D4C41), // Brown
      const Color(0xFFF9A825), // Yellow
      const Color(0xFF2E7D32), // Dark Green
      const Color(0xFF1565C0), // Dark Blue
      const Color(0xFFAD1457), // Dark Pink
      const Color(0xFF4E342E), // Dark Brown
      const Color(0xFF283593), // Deep Indigo
      const Color(0xFF00695C), // Deep Teal
      const Color(0xFF558B2F), // Light Green
      const Color(0xFFEF6C00), // Deep Orange
    ];
    final hexController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a Custom Color'),
          content: SizedBox(
            width: 300,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('#', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: hexController,
                          decoration: const InputDecoration(
                            hintText: 'Hex (e.g. FF0055)',
                            isDense: true,
                          ),
                          onSubmitted: (value) {
                            if (value.length >= 6) {
                              final color = Color(int.parse(value.replaceAll('#', '').padLeft(8, 'FF'), radix: 16));
                              ref.read(themeProvider.notifier).setCustomColor(color);
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: customColors.map((color) {
                      return GestureDetector(
                        onTap: () {
                          ref.read(themeProvider.notifier).setCustomColor(color);
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 2),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeStateAsync = ref.watch(themeProvider);
    final myProfileAsync = ref.watch(myProfileProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: themeStateAsync.when(
        data: (themeState) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Card
              myProfileAsync.when(
                data: (profile) {
                  if (profile == null) return const SizedBox.shrink();
                  return Card(
                    elevation: 0,
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          UserAvatar(user: profile, radius: 36),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(profile.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: profile.id));
                                    NotificationService.showMessageNotification('Abyss Chat', 'Copied ID to clipboard');
                                  },
                                  child: Text('#${profile.id}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.primary)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditProfileDialog(context, ref, profile),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // Appearance Section
              Text(
                'Appearance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.brightness_6, color: cs.primary),
                title: const Text('Theme Mode'),
                subtitle: Text(themeState.mode.name.toUpperCase()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Select Mode'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: ThemeMode.values.map((mode) {
                            final isSelected = themeState.mode == mode;
                            return ListTile(
                              title: Text(mode.name.toUpperCase()),
                              trailing: isSelected
                                  ? Icon(Icons.check_circle, color: cs.primary)
                                  : const Icon(Icons.circle_outlined),
                              onTap: () {
                                ref.read(themeProvider.notifier).setThemeMode(mode);
                                Navigator.pop(context);
                              },
                            );
                          }).toList(),
                        ),
                      );
                    },
                  );
                },
              ),
              const Divider(),
              const SizedBox(height: 16),

              // Layout Section
              Text(
                'Layout',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final layoutStateAsync = ref.watch(layoutProvider);
                  return layoutStateAsync.when(
                    data: (layoutState) {
                      return ListTile(
                        leading: Icon(Icons.dock, color: cs.primary),
                        title: const Text('Dock Position'),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: SegmentedButton<DockPosition>(
                            segments: const [
                              ButtonSegment(
                                value: DockPosition.bottom,
                                icon: Icon(Icons.margin),
                                label: Text('Bottom'),
                              ),
                              ButtonSegment(
                                value: DockPosition.left,
                                icon: Icon(Icons.vertical_align_center),
                                label: Text('Left'),
                              ),
                            ],
                            selected: {layoutState.dockPosition},
                            onSelectionChanged: (Set<DockPosition> newSelection) {
                              ref.read(layoutProvider.notifier).setDockPosition(newSelection.first);
                            },
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Text('Error: $e'),
                  );
                },
              ),
              const Divider(height: 32),

              // Color Palette
              Text(
                'Color Palette',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    // Dynamic Theme Option
                    GestureDetector(
                      onTap: () => ref.read(themeProvider.notifier).setTheme('Default'),
                      child: Container(
                        margin: const EdgeInsets.only(right: 16),
                        width: 100,
                        height: 120,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: themeState.themeName == 'Default' ? cs.primary : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: themeState.themeName == 'Default' ? [BoxShadow(color: cs.primary.withValues(alpha: 0.3), blurRadius: 12)] : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome, size: 32, color: themeState.themeName == 'Default' ? cs.primary : cs.onSurfaceVariant),
                            const SizedBox(height: 12),
                            Text('Dynamic\nColor', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: themeState.themeName == 'Default' ? cs.primary : cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                    
                    // Predefined themes
                    ...predefinedThemes.entries.map((entry) {
                      final isSelected = themeState.themeName == entry.key;
                      return GestureDetector(
                        onTap: () => ref.read(themeProvider.notifier).setTheme(entry.key),
                        child: Container(
                          margin: const EdgeInsets.only(right: 16),
                          width: 100,
                          height: 120,
                          decoration: BoxDecoration(
                            color: entry.value,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? cs.onSurface : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected ? [BoxShadow(color: entry.value.withValues(alpha: 0.5), blurRadius: 12, offset: const Offset(0, 4))] : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isSelected)
                                Icon(Icons.check_circle, size: 32, color: entry.value.computeLuminance() > 0.5 ? Colors.black : Colors.white),
                              if (isSelected) const SizedBox(height: 12),
                              Text(
                                entry.key.split(' ').last,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 13, 
                                  color: entry.value.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // Custom color option
                    GestureDetector(
                      onTap: () => _showCustomColorPicker(context, ref),
                      child: Container(
                        width: 100,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: themeState.themeName == 'Custom' ? cs.onSurface : Colors.transparent,
                            width: 3,
                          ),
                          gradient: const SweepGradient(
                            colors: [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple, Colors.red],
                          ),
                          boxShadow: themeState.themeName == 'Custom' ? [BoxShadow(color: cs.onSurface.withValues(alpha: 0.3), blurRadius: 12)] : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (themeState.themeName == 'Custom')
                               const Icon(Icons.color_lens, size: 32, color: Colors.white),
                            if (themeState.themeName == 'Custom') const SizedBox(height: 12),
                            const Text('Custom', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white, shadows: [Shadow(color: Colors.black54, blurRadius: 4)])),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 32),

              // Chat Features
              Text(
                'Chat Features',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.wallpaper, color: cs.primary),
                title: const Text('Chat Wallpaper'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  NotificationService.showMessageNotification('Chat Wallpaper', 'Coming soon in a future update!');
                },
              ),
              ListTile(
                leading: Icon(Icons.notifications_outlined, color: cs.primary),
                title: const Text('Notifications'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                },
              ),
              ListTile(
                leading: Icon(Icons.data_usage, color: cs.primary),
                title: const Text('Storage and Data'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const StorageManagementScreen()));
                },
              ),
              const Divider(height: 32),

              // App Info
              Text(
                'App Info',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About Abyss Chat'),
                subtitle: const Text('Version info and updates'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => const AboutAbyssDialog(),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.devices, color: cs.primary),
                title: const Text('Chat from Other Devices'),
                subtitle: const Text('Download for Desktop/Web (P2P Support)'),
                trailing: const Icon(Icons.open_in_new, size: 20),
                onTap: () {
                  launchUrl(Uri.parse('https://github.com/North-Abyss/abyss_chat/releases/latest'), mode: LaunchMode.externalApplication);
                },
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('Source Code (GitHub)'),
                subtitle: const Text('github.com/North-Abyss/abyss_chat'),
                trailing: const Icon(Icons.copy, size: 20),
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: 'https://github.com/North-Abyss/abyss_chat'));
                  NotificationService.showMessageNotification('App Info', 'Repository link copied to clipboard');
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
                },
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: cs.surfaceContainerHighest,
                  foregroundColor: cs.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Log Out'),
                onPressed: () {
                  ref.read(peerServiceProvider).dispose();
                  ref.invalidate(peerServiceProvider);
                  ref.invalidate(chatThreadsProvider);
                  ref.invalidate(callLogsProvider);
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: cs.errorContainer,
                  foregroundColor: cs.onErrorContainer,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.delete_forever),
                label: const Text('Delete Account & Data'),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Delete Account?'),
                      content: const Text('This will permanently delete all your chats, contacts, and settings. This cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: cs.error),
                          onPressed: () => Navigator.pop(c, true), 
                          child: const Text('Delete')
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm == true) {
                    await ref.read(storageServiceProvider).clearAllData();
                    CryptoService.reset();
                    ref.read(peerServiceProvider).dispose();
                    ref.invalidate(peerServiceProvider);
                    ref.invalidate(chatThreadsProvider);
                    ref.invalidate(callLogsProvider);
                    ref.invalidate(myProfileProvider);
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
              const SizedBox(height: 32),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading settings: $err')),
      ),
    );
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: settingsAsync.when(
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('System Notifications'),
                subtitle: const Text('Show notifications outside the app'),
                value: settings.systemNotificationsEnabled,
                onChanged: (val) {
                  ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(systemNotificationsEnabled: val));
                },
              ),
              SwitchListTile(
                title: const Text('In-App Chat Notifications'),
                subtitle: const Text('Show floating notifications for new messages'),
                value: settings.inAppNotificationsEnabled,
                onChanged: (val) {
                  ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(inAppNotificationsEnabled: val));
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('In-App Notification Position'),
                subtitle: const Text('Where floating notifications appear'),
                trailing: SegmentedButton<NotificationPosition>(
                  segments: const [
                    ButtonSegment(value: NotificationPosition.top, label: Text('Top')),
                    ButtonSegment(value: NotificationPosition.bottom, label: Text('Bottom')),
                  ],
                  selected: {settings.notificationPosition},
                  onSelectionChanged: (Set<NotificationPosition> newSelection) {
                    ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(notificationPosition: newSelection.first));
                    NotificationService.showMessageNotification('Position Changed', 'Notifications will appear here!');
                  },
                ),
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

// StorageManagementScreen was moved to its own file
