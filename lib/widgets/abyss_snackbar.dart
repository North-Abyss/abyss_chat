import 'package:flutter/material.dart';

enum SnackBarType { success, error, info }

class AbyssSnackBar {
  static void show(
    BuildContext context, 
    String message, {
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    IconData icon;
    Color bgColor;
    Color fgColor;
    
    switch (type) {
      case SnackBarType.success:
        icon = Icons.check_circle;
        bgColor = const Color(0xFF005C4B); // Dark green
        fgColor = Colors.white;
        break;
      case SnackBarType.error:
        icon = Icons.error;
        bgColor = Theme.of(context).colorScheme.errorContainer;
        fgColor = Theme.of(context).colorScheme.onErrorContainer;
        break;
      case SnackBarType.info:
        icon = Icons.info;
        bgColor = Theme.of(context).colorScheme.primaryContainer;
        fgColor = Theme.of(context).colorScheme.onPrimaryContainer;
        break;
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fgColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: fgColor, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
