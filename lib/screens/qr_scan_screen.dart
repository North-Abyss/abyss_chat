import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abyss_chat/widgets/abyss_snackbar.dart';

class QRScanScreen extends ConsumerStatefulWidget {
  const QRScanScreen({super.key});

  @override
  ConsumerState<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends ConsumerState<QRScanScreen> {
  late final bool _isUnsupportedPlatform;
  MobileScannerController? cameraController;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _isUnsupportedPlatform = kIsWeb || 
        defaultTargetPlatform == TargetPlatform.linux || 
        defaultTargetPlatform == TargetPlatform.windows;
    
    if (!_isUnsupportedPlatform) {
      cameraController = MobileScannerController();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: _isUnsupportedPlatform
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    const Text(
                      'QR Camera Scanning is optimized for Mobile & macOS.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 250,
                      child: TextField(
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            Navigator.pop(context, val.trim());
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Enter Peer ID manually',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: () {},
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            )
          : MobileScanner(
              controller: cameraController!,
              placeholderBuilder: (context) => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Starting Camera...'),
                  ],
                ),
              ),
              onDetect: (capture) {
                if (!_isScanning) return;
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                  final String code = barcodes.first.rawValue!;
                  setState(() {
                    _isScanning = false;
                  });
                  
                  AbyssSnackBar.show(context, 'Connecting to peer...', type: SnackBarType.info);
                  Navigator.pop(context, code);
                }
              },
            ),
    );
  }
  
  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }
}
