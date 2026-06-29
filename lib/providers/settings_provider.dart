import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NotificationPosition { top, bottom }

class AppSettings {
  final NotificationPosition notificationPosition;
  final bool systemNotificationsEnabled;
  final bool mediaAutoDownloadWifi;
  final bool mediaAutoDownloadCellular;

  AppSettings({
    required this.notificationPosition,
    required this.systemNotificationsEnabled,
    required this.mediaAutoDownloadWifi,
    required this.mediaAutoDownloadCellular,
  });

  AppSettings copyWith({
    NotificationPosition? notificationPosition,
    bool? systemNotificationsEnabled,
    bool? mediaAutoDownloadWifi,
    bool? mediaAutoDownloadCellular,
  }) {
    return AppSettings(
      notificationPosition: notificationPosition ?? this.notificationPosition,
      systemNotificationsEnabled: systemNotificationsEnabled ?? this.systemNotificationsEnabled,
      mediaAutoDownloadWifi: mediaAutoDownloadWifi ?? this.mediaAutoDownloadWifi,
      mediaAutoDownloadCellular: mediaAutoDownloadCellular ?? this.mediaAutoDownloadCellular,
    );
  }
}

class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      notificationPosition: prefs.getString('notificationPosition') == 'top' ? NotificationPosition.top : NotificationPosition.bottom,
      systemNotificationsEnabled: prefs.getBool('systemNotificationsEnabled') ?? true,
      mediaAutoDownloadWifi: prefs.getBool('mediaAutoDownloadWifi') ?? true,
      mediaAutoDownloadCellular: prefs.getBool('mediaAutoDownloadCellular') ?? false,
    );
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notificationPosition', newSettings.notificationPosition.name);
    await prefs.setBool('systemNotificationsEnabled', newSettings.systemNotificationsEnabled);
    await prefs.setBool('mediaAutoDownloadWifi', newSettings.mediaAutoDownloadWifi);
    await prefs.setBool('mediaAutoDownloadCellular', newSettings.mediaAutoDownloadCellular);
    state = AsyncData(newSettings);
  }
}

final appSettingsProvider = AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(() {
  return AppSettingsNotifier();
});
