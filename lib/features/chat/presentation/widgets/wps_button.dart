import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:abyss_chat/network/mdns_service.dart';
import 'package:abyss_chat/features/chat/domain/chat_controller.dart';
import 'package:abyss_chat/core/widgets/abyss_snackbar.dart';
import 'package:abyss_chat/features/chat/presentation/screens/chat_screen.dart';

class WpsButton extends ConsumerStatefulWidget {
  final bool isDesktop;
  const WpsButton({super.key, this.isDesktop = false});

  @override
  ConsumerState<WpsButton> createState() => _WpsButtonState();
}

class _WpsButtonState extends ConsumerState<WpsButton> {
  bool _isPairing = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPairing() {
    setState(() {
      _isPairing = true;
    });

    final mdnsNotifier = ref.read(nearbyPeersProvider.notifier);
    mdnsNotifier.toggleWps(true);
    
    AbyssSnackBar.show(context, 'WPS Pairing active for 30s...', type: SnackBarType.info);

    _timer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() {
          _isPairing = false;
        });
        mdnsNotifier.toggleWps(false);
      }
    });
  }

  void _connectToPeer(String peerId, String peerName) {
    if (_isPairing) {
      setState(() {
        _isPairing = false;
      });
      _timer?.cancel();
      ref.read(nearbyPeersProvider.notifier).toggleWps(false);
    }

    ref.read(chatThreadsProvider.notifier).startNewChat(peerId, peerName: peerName);
    AbyssSnackBar.show(context, 'Paired with \$peerName!', type: SnackBarType.success);

    if (widget.isDesktop) {
      ref.read(selectedThreadIdProvider.notifier).select(peerId);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(threadId: peerId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for any peers that are ALSO in WPS mode
    ref.listen(nearbyPeersProvider, (previous, next) {
      if (_isPairing) {
        final wpsPeer = next.where((p) => p.isWpsActive).firstOrNull;
        if (wpsPeer != null) {
          _connectToPeer(wpsPeer.id, wpsPeer.name);
        }
      }
    });

    return IconButton(
      icon: _isPairing 
        ? const Icon(Icons.wifi_tethering)
            .animate(onPlay: (controller) => controller.repeat())
            .scale(duration: 800.ms, begin: const Offset(1, 1), end: const Offset(1.2, 1.2))
            .fade(duration: 800.ms, begin: 1.0, end: 0.3)
        : const Icon(Icons.wifi_protected_setup),
      tooltip: 'WPS Quick Connect',
      color: _isPairing ? Theme.of(context).colorScheme.primary : null,
      onPressed: _isPairing ? null : _startPairing,
    );
  }
}
