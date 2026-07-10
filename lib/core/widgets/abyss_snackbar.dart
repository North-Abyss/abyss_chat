import 'package:flutter/material.dart';
import 'package:abyss_chat/network/notification_service.dart';


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

    // Completely replace the old bottom snackbar with our sleek sliding in-app notification!
    NotificationService.showMessageNotification(
      title, 
      message, 
      inAppOnly: true, // Only show the overlay, don't trigger OS native notifications
    );
  }
}
