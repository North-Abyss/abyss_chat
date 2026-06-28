import 'package:flutter/material.dart';
import 'package:abyss_chat/providers/call_provider.dart';

class NotificationService {
  static void showMessageNotification(String senderName, String message) {
    final overlayState = globalNavigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    OverlayEntry? entry;

    entry = OverlayEntry(
      builder: (context) => SlidableNotificationWidget(
        senderName: senderName,
        message: message,
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
  final VoidCallback onDismiss;

  const SlidableNotificationWidget({
    super.key,
    required this.senderName,
    required this.message,
    required this.onDismiss,
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
    return Positioned(
      bottom: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _offsetAnimation,
          child: GestureDetector(
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
