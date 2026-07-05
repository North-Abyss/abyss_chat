import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/services/shared_prefs_helper.dart';
import 'package:flutter/foundation.dart';

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
      systemNotificationsEnabled: prefs.getBool('systemNotificationsEnabled') ?? true,
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
