import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/core/utils/shared_prefs_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum NotificationPosition { top, bottom }

class AppSettings {
  final NotificationPosition notificationPosition;
  final bool systemNotificationsEnabled;
  final bool inAppNotificationsEnabled;
  final bool mediaAutoDownloadWifi;
  final bool mediaAutoDownloadCellular;

  AppSettings({
    required this.notificationPosition,
    required this.systemNotificationsEnabled,
    required this.inAppNotificationsEnabled,
    required this.mediaAutoDownloadWifi,
    required this.mediaAutoDownloadCellular,
  });

  AppSettings copyWith({
    NotificationPosition? notificationPosition,
    bool? systemNotificationsEnabled,
    bool? inAppNotificationsEnabled,
    bool? mediaAutoDownloadWifi,
    bool? mediaAutoDownloadCellular,
  }) {
    return AppSettings(
      notificationPosition: notificationPosition ?? this.notificationPosition,
      systemNotificationsEnabled: systemNotificationsEnabled ?? this.systemNotificationsEnabled,
      inAppNotificationsEnabled: inAppNotificationsEnabled ?? this.inAppNotificationsEnabled,
      mediaAutoDownloadWifi: mediaAutoDownloadWifi ?? this.mediaAutoDownloadWifi,
      mediaAutoDownloadCellular: mediaAutoDownloadCellular ?? this.mediaAutoDownloadCellular,
    );
  }
}

class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPrefsHelper.instance;
    return AppSettings(
      notificationPosition: prefs.getString('notificationPosition') == 'bottom' ? NotificationPosition.bottom : NotificationPosition.top,
      systemNotificationsEnabled: prefs.getBool('systemNotificationsEnabled') ?? !kIsWeb,
      inAppNotificationsEnabled: prefs.getBool('inAppNotificationsEnabled') ?? kIsWeb,
      mediaAutoDownloadWifi: prefs.getBool('mediaAutoDownloadWifi') ?? true,
      mediaAutoDownloadCellular: prefs.getBool('mediaAutoDownloadCellular') ?? false,
    );
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    final prefs = await SharedPrefsHelper.instance;
    await prefs.setString('notificationPosition', newSettings.notificationPosition.name);
    await prefs.setBool('systemNotificationsEnabled', newSettings.systemNotificationsEnabled);
    await prefs.setBool('inAppNotificationsEnabled', newSettings.inAppNotificationsEnabled);
    await prefs.setBool('mediaAutoDownloadWifi', newSettings.mediaAutoDownloadWifi);
    await prefs.setBool('mediaAutoDownloadCellular', newSettings.mediaAutoDownloadCellular);
    state = AsyncData(newSettings);
  }
}

final appSettingsProvider = AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(() {
  return AppSettingsNotifier();
});

class UpdateInfo {
  final bool hasUpdate;
  final String latestVersion;
  final String downloadUrl;
  UpdateInfo({required this.hasUpdate, required this.latestVersion, required this.downloadUrl});
}

final updateCheckProvider = FutureProvider<UpdateInfo>((ref) async {
  try {
    // Current hardcoded app version for check
    const currentVersion = 'v1.1.2'; // Changed to match pubspec (1.1.2)
    
    // Fetch latest release from GitHub API
    final response = await http.get(
      Uri.parse('https://api.github.com/repos/North-Abyss/abyss_chat/releases/latest'),
      headers: {'User-Agent': 'Abyss-Chat-App'},
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final tagName = data['tag_name'] as String;
      final downloadUrl = data['html_url'] as String;
      
      // Basic string comparison for version
      if (tagName != currentVersion) {
        return UpdateInfo(hasUpdate: true, latestVersion: tagName, downloadUrl: downloadUrl);
      }
    }
  } catch (e) {
    debugPrint('Failed to check for updates: $e');
  }
  return UpdateInfo(hasUpdate: false, latestVersion: '', downloadUrl: 'https://github.com/North-Abyss/abyss_chat/releases/latest');
});
