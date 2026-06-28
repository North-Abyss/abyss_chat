# Abyss Chat

A modern, cross-platform Flutter application serving as a P2P WhatsApp-style clone. It uses WebRTC and local network discovery (mDNS) to connect peers without a central server. Built for all platforms simultaneously.

**Download Now:** [Check Releases](https://github.com/North-Abyss/abyss_chat/releases)

<div align=center>
    <!-- Replace this with a preview screenshot when available -->
    <img src="assets/abyss-chat.png" alt="Logo" width="128" style="border-radius: 18px;">
</div>

## 📱 Features

- **P2P Communication** - Uses WebRTC for peer-to-peer data channels and audio/video calling.
- **Local Network Discovery** - Uses mDNS (Multicast DNS) and LAN TCP sockets to find and connect to peers on the same local network, working completely offline.
- **Material 3 Design** - Fully customized dynamic theming support with beautiful UI following Material 3 guidelines.
- **Persistent Storage** - Saves chats, settings, profiles, and call logs persistently using `shared_preferences`.
- **Group Chats** - Create and manage group chats.
- **Profile Customization** - Users can customize their names, avatar icons, and colors (including pure black/white).
- **Theming Engine** - Includes 12 curated themes plus the ability to pick any custom hex color.
- **In-App Notifications** - Get floating toasts when you receive messages while navigating the app.
- **Floating Mini-Call Window** - Picture-in-picture style floating pill when you navigate away from an active call.
- **Cloud CI/CD Pipeline** - Automated GitHub Actions release builds for Android, Windows, and Linux on every `v*` tag.

## 🏗️ Architecture

Abyss Chat follows a clean architecture pattern with a clear separation of concerns, built for all platforms.

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
