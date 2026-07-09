import 'package:flutter/material.dart';
import 'package:abyss_chat/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:abyss_chat/services/shared_prefs_helper.dart';

enum SnackBarType { success, error, info }

class AbyssSnackBar {
  static void show(
    BuildContext context, 
    String message, {
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    String title;
    switch (type) {
      case SnackBarType.success:
        title = 'Success';
        break;
      case SnackBarType.error:
        title = 'Error';
        break;
      case SnackBarType.info:
        title = 'Abyss Chat';
        break;
    }

    // First check if in-app notifications are enabled
    _showWithFallback(context, title, message);
  }

  static Future<void> _showWithFallback(BuildContext context, String title, String message) async {
    final prefs = await SharedPrefsHelper.instance;
    final inAppEnabled = prefs.getBool('inAppNotificationsEnabled') ?? kIsWeb;

    if (inAppEnabled) {
      // Completely replace the old bottom snackbar with our sleek sliding in-app notification!
      NotificationService.showMessageNotification(
        title, 
        message, 
        inAppOnly: true, // Only show the overlay, don't trigger OS native notifications
      );
    } else {
      // Fallback to normal SnackBar if they disabled our premium slide-in notifications
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title: $message'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
