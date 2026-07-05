import 'package:flutter/material.dart';
import 'package:abyss_chat/providers/call_provider.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart'; // Add this for kIsWeb
import 'package:abyss_chat/providers/settings_provider.dart';
import 'package:abyss_chat/services/shared_prefs_helper.dart';
import 'package:abyss_chat/services/web_notification.dart'; // Add conditional import

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const LinuxInitializationSettings linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open notification');
    const DarwinInitializationSettings darwinSettings = DarwinInitializationSettings();
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      linux: linuxSettings,
      macOS: darwinSettings,
      iOS: darwinSettings,
    );
    
    await _plugin.initialize(
      settings: initSettings,
    );
    _initialized = true;
  }

  static void showMessageNotification(String title, String body, {VoidCallback? onTap, bool inAppOnly = false}) async {
    final prefs = await SharedPrefsHelper.instance;
    final systemEnabled = prefs.getBool('systemNotificationsEnabled') ?? true;
    final inAppEnabled = prefs.getBool('inAppNotificationsEnabled') ?? kIsWeb;
    final positionStr = prefs.getString('notificationPosition') ?? 'top';
    final position = positionStr == 'bottom' ? NotificationPosition.bottom : NotificationPosition.top;

    if (systemEnabled && !inAppOnly) {
      if (kIsWeb) {
        // Use browser's native Notification API
        showWebNotification(title, body);
        if (!inAppEnabled) return; // Prevent in-app duplicate
      } else {
        if (!_initialized) {
          await initialize();
        }
        
        try {
          const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
            'abyss_chat_messages',
            'Messages',
            importance: Importance.high,
            priority: Priority.high,
          );
          const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
          
          await _plugin.show(
            id: DateTime.now().millisecond,
            title: title,
            body: body,
            notificationDetails: platformDetails,
          );
          if (!inAppEnabled) return; // Prevent in-app duplicate on success
        } catch (e) {
          // Fallback to in-app
        }
      }
    }
    
    // In-app fallback or if system notifications are disabled
    final overlayState = globalNavigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (context) => SlidableNotificationWidget(
        senderName: title,
        message: body,
        position: position,
        onTap: onTap,
        onDismiss: () {
          entry?.remove();
        },
      ),
    );
    overlayState.insert(entry);
  }
}

class SlidableNotificationWidget extends StatefulWidget {
  final String senderName;
  final String message;
  final NotificationPosition position;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;

  const SlidableNotificationWidget({
    super.key,
    required this.senderName,
    required this.message,
    required this.position,
    required this.onDismiss,
    this.onTap,
  });

  @override
  State<SlidableNotificationWidget> createState() => _SlidableNotificationWidgetState();
}

class _SlidableNotificationWidgetState extends State<SlidableNotificationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0), // Start off-screen right
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    final isTop = widget.position == NotificationPosition.top;
    
    return Positioned(
      bottom: isTop ? null : 24,
      top: isTop ? 24 : null,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _offsetAnimation,
          child: GestureDetector(
            onTap: () {
              if (widget.onTap != null) {
                widget.onTap!();
              }
              _dismiss();
            },
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
                // Swipe right to dismiss
                _dismiss();
              }
            },
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    child: Icon(Icons.message, color: cs.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.senderName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(widget.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _dismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
