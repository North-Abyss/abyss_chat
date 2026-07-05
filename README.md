# Abyss Chat

A modern, cross-platform Flutter application serving as a P2P WhatsApp-style clone. It uses WebRTC and local network discovery (mDNS) to connect peers without a central server. Built for all platforms simultaneously.

**Live Web App:** [https://north-abyss.github.io/abyss_chat/](https://north-abyss.github.io/abyss_chat/)  
**GitHub Repository:** [North-Abyss/abyss_chat](https://github.com/North-Abyss/abyss_chat)  
**Download Latest Release (Native Apps):** [Download v1.1.0](https://github.com/North-Abyss/abyss_chat/releases/latest)
<div align="center">
    <img src="assets/abyss-chat.png" alt="Logo" width="128" style="border-radius: 18px; margin-bottom: 24px;">
    
  <br>
  
  <img src="assets/Screenshot-01.png" alt="Screenshot 1" width="250" style="border-radius: 12px; margin: 8px; box-shadow: 0 8px 24px rgba(0,0,0,0.15);">
  <img src="assets/Screenshot-02.png" alt="Screenshot 2" width="250" style="border-radius: 12px; margin: 8px; box-shadow: 0 8px 24px rgba(0,0,0,0.15);">
  <img src="assets/Screenshot-03.png" alt="Screenshot 3" width="250" style="border-radius: 12px; margin: 8px; box-shadow: 0 8px 24px rgba(0,0,0,0.15);">
</div>

## 📱 Features

- **P2P Communication** - Uses WebRTC for true peer-to-peer data channels and audio/video calling (supports both 1-on-1 and Group Mesh calls).
- **Mutual Contacts Only** - Strict privacy enforcement instantly rejects incoming connections from unknown peers not in your local contacts list.
- **Local Network Discovery** - Uses mDNS (Multicast DNS) and LAN TCP sockets to find and connect to peers on the same local network, working completely offline.
- **Material 3 Design** - Fully customized dynamic theming support with beautiful UI following Material 3 guidelines, including desktop/web responsive split-pane layouts.
- **Persistent Storage** - Saves chats, settings, profiles, and call logs securely (using `path_provider` on native and `shared_preferences` gracefully falling back on Web).
- **Group Chats & Calls** - Create and manage local group chats, and initiate P2P Group Video Calls with dynamic grid layouts.
- **Profile Customization** - Users can customize their names, avatar icons, and colors (including pure black/white).
- **Theming Engine** - Includes 12 curated themes plus the ability to pick any custom hex color.
- **Smart Notifications** - Slide-in floating toasts for incoming messages that automatically silence themselves if you're actively speaking to the sender.
- **Rich Media & Link Previews** - Automatic URL parsing in chats. Web links show rich preview cards, and direct video/image links render inline with playback support.
- **Floating Mini-Call Window** - Picture-in-picture style floating pill when you navigate away from an active call, plus full Answer/Decline call screens.
- **Desktop Keyboard Support** - Use `Enter` to seamlessly send messages and `Shift+Enter` for multiline text, just like WhatsApp Web.
- **End-to-End Encrypted**: All communications are encrypted over WebRTC data channels.
- **Group Calling**: Full Mesh group video/audio calling (up to 10 participants!).
- **Group Customization & QR Join**: Easily customize group names/photos and invite friends instantly by letting them scan your Group QR Code!
- **Cross-Platform**: Runs on Android, iOS, Windows, macOS, Linux, and the Web.
- **Cloud CI/CD Pipeline** - Automated GitHub Actions release builds for Android, Windows, and Linux on every `v*` tag.
- **Maintainable Codebase** - Centralized `AppConstants` hub and deeply documented structural layout for easy onboarding.

## 🏗️ Architecture

Abyss Chat follows a clean architecture pattern with a clear separation of concerns, built for all platforms.

> **📚 Deep Dives:**
> - Check out [EXPLANATION.md](EXPLANATION.md) for a comprehensive Q&A and a visual Mermaid diagram of the architecture (great for interviews!).
> - Check out [agent-memory.md](agent-memory.md) for a full breakdown of the directory structure and project session logs.

### State Management
- **Riverpod** (`flutter_riverpod: ^3.3.2`) - Used for reactive state management.
  - Handles themes, chat states, profiles, active calls, and data synchronization.

### Data & UI Integrations
- **WebRTC** (`flutter_webrtc: ^1.5.2` & `peerdart: ^0.5.6`) - Real-time P2P data channels and media streams.
- **Network Discovery** (`nsd: ^5.0.1`) - Multicast DNS for finding local peers offline.
- **SharedPreferences** (`shared_preferences: ^2.5.5`) - Local device storage for chats and metadata.
- **UUID** (`uuid: ^4.5.3`) - Generates unique identifiers.
- **Animations** (`flutter_animate: ^4.5.2`) - Beautiful UI transitions and micro-animations.
- **Emoji Picker** (`emoji_picker_flutter: ^4.4.0`) - Floating emoji overlay for chat messages.
- **Local Notifications** (`flutter_local_notifications: ^22.0.1`) - Native background and local notifications.

### Key Components

#### Models (`lib/models/`)
- Data structures representing Messages, ChatThreads, Users, and Call states.

#### Screens (`lib/screens/`)
- `HomeScreen` - Chat lists, recent messages, and active peer discovery.
- `ChatScreen` - Active conversation UI with real-time updates and floating emoji picker.
- `SettingsScreen` - Theme controls, custom hex colors, and app configurations.
- `ProfileScreen` - Profile management with black/white avatar options.

#### Widgets (`lib/widgets/`)
- Reusable UI components including the `MiniCallOverlay` for floating calls and `InAppNotificationService` for floating toasts.

#### Services (`lib/services/`)
- Background network & JSON logic, handling WebRTC handshakes, mDNS discovery, and local persistent data loading.

## 🚀 Getting Started

To run this project locally, ensure you have Flutter installed.

1. Clone the repository.
2. Run `flutter pub get` to install dependencies.
3. Use `flutter run` to launch on your connected device or emulator.
4. For Linux specifically, ensure the necessary dependencies for `flutter_webrtc` are present on your system.
