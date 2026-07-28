import 'package:flutter/material.dart';

class WelcomeGuideScreen extends StatelessWidget {
  const WelcomeGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Abyss Chat'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(
                Icons.cyclone,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'How Abyss Chat Works',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Abyss Chat is a completely free, open-source, decentralized chat application. '
              'Instead of storing your messages and files on a central corporate server, '
              'Abyss Chat uses WebRTC and STUN technology to punch a hole through your router and '
              'transfer data directly from your device to your friend\'s device (Peer-to-Peer).',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            Text(
              'The Dock',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildDockCard(
              context,
              Icons.chat_bubble,
              'Chats',
              'Your decentralized conversations. No central server stores your messages.',
              Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            _buildDockCard(
              context,
              Icons.local_activity,
              'Activity',
              'Play games, manage your personal scratchpad, and see status updates.',
              Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 12),
            _buildDockCard(
              context,
              Icons.settings,
              'Settings',
              'Customize your theme, edit your profile, and manage connections.',
              Theme.of(context).colorScheme.tertiary,
            ),
            const SizedBox(height: 24),
            Text(
              'UI Icons Explained',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildIconRow(
              context,
              Icons.refresh,
              'Refresh Connection',
              'If your connection drops, tap this to instantly reconnect to the signaling server.',
            ),
            _buildIconRow(
              context,
              Icons.qr_code_scanner,
              'QR Scanner',
              'Scan a friend\'s QR code or a Group QR code to quickly add them or join their group.',
            ),
            _buildIconRow(
              context,
              Icons.cyclone,
              'Activity Launcher',
              'The floating vortex button at the bottom of the chat lets you send files, start video calls, or play games.',
            ),
            const SizedBox(height: 24),
            Text(
              'Relay Limits & Networking',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sometimes, highly restrictive corporate firewalls prevent direct P2P connections. '
              'When this happens, Abyss Chat automatically falls back to a 3rd-party Open Relay (TURN) server '
              'which provides 50GB of free data per month.\n\n'
              'If you are a power user transferring massive files, you can configure your own private Custom TURN server '
              'in the Settings menu > Advanced Networking!',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Get Started', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildIconRow(
      BuildContext context, IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDockCard(BuildContext context, IconData icon, String title, String description, Color color) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
