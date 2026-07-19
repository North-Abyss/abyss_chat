import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAbyssDialog extends StatefulWidget {
  const AboutAbyssDialog({super.key});

  @override
  State<AboutAbyssDialog> createState() => _AboutAbyssDialogState();
}

class _AboutAbyssDialogState extends State<AboutAbyssDialog> {
  PackageInfo? _packageInfo;
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingUpdate = true;
    });
    
    // Simulate network delay for update check
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() {
        _isCheckingUpdate = false;
      });
      final url = Uri.parse('https://github.com/North-Abyss/abyss_chat/releases');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.forum, size: 48, color: cs.onPrimaryContainer),
            ),
            const SizedBox(height: 16),
            Text(
              'Abyss Chat',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _packageInfo != null 
                  ? 'Version ${_packageInfo!.version} (${_packageInfo!.buildNumber})'
                  : 'Loading version...',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text(
              'By North Abyss',
              style: TextStyle(fontWeight: FontWeight.w500, color: cs.primary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isCheckingUpdate ? null : _checkForUpdates,
                icon: _isCheckingUpdate 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Icon(Icons.system_update),
                label: Text(_isCheckingUpdate ? 'Checking...' : 'Check for Updates'),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
