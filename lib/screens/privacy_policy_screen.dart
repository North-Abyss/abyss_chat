import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

const String _privacyPolicyContent = '''
# Abyss Chat Privacy Policy & Terms of Use

**Effective Date:** July 5, 2026

Welcome to Abyss Chat. This application is an open-source, decentralized, peer-to-peer (P2P) messaging and communication platform.

## 1. Free and Open Source
Abyss Chat is provided 100% free of charge and is open-source software. You are free to inspect, modify, and distribute the code under the terms of its open-source license.

## 2. No Central Servers & Privacy
Your messages, voice calls, video calls, and files are transmitted directly between you and your peers using WebRTC and local network discovery (mDNS). 
- **We do not store your data.** 
- **We do not track your activity.**
- All communication is end-to-end encrypted when possible.

## 3. Limitations of Liability (Not at Blame)
Because Abyss Chat operates on a decentralized P2P network, the developers and contributors of Abyss Chat have absolutely no control over:
- The content transmitted through the application.
- The availability or reliability of the network connections.
- Any data loss or security breaches that occur on your local device.

**By using Abyss Chat, you agree that the creators and contributors are NOT liable for any damages, losses, or illicit activity conducted over the application.** 

## 4. Usage Rules & Guide
- **Stay Safe:** Only connect and share your 6-digit Peer ID with people you trust.
- **Local Network:** You can use the app seamlessly on a local Wi-Fi network without internet access.
- **Global Network:** Connecting over the internet requires both peers to be online and able to negotiate a WebRTC connection.
- **Group Mechanics & Limitations:** Because Abyss Chat is entirely Peer-to-Peer without central servers, group chats require your device to maintain direct connections to every other participant. This means group calls (especially with video) are extremely resource-intensive. **Group calls with many participants are not recommended** as they may cause high battery drain, network lag, or device overheating. Messages in groups are also sent individually to each connected peer.
- **Respect Others:** Do not use this application to harass, abuse, or distribute illegal content.

Thank you for using Abyss Chat!
''';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy & Terms'),
      ),
      body: Markdown(
        data: _privacyPolicyContent,
        onTapLink: (text, href, title) {
          if (href != null) {
            launchUrl(Uri.parse(href));
          }
        },
      ),
    );
  }
}
