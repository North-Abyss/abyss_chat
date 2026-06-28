import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/providers/chat_provider.dart';
import 'package:abyss_chat/widgets/abyss_snackbar.dart';

class QRScanScreen extends ConsumerStatefulWidget {
  const QRScanScreen({super.key});

  @override
  ConsumerState<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends ConsumerState<QRScanScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) {
          if (!_isScanning) return;
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            final String code = barcodes.first.rawValue!;
            setState(() {
              _isScanning = false;
            });
            
            AbyssSnackBar.show(context, 'Connecting to peer...', type: SnackBarType.info);
            ref.read(chatThreadsProvider.notifier).connectToPeer(code);
            
            Navigator.pop(context);
          }
        },
      ),
    );
  }
  
  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
