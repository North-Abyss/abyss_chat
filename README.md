# Abyss Chat

A modern, cross-platform Flutter application serving as a P2P WhatsApp-style clone.

## Features

- **P2P Communication**: Uses WebRTC for peer-to-peer data channels and audio/video calling.
- **Local Network Discovery**: Uses mDNS (Multicast DNS) and LAN TCP sockets to find and connect to peers on the same local network, working completely offline.
- **Material 3 Design**: Fully customized dynamic theming support with beautiful UI following Material 3 guidelines.
- **Persistent Storage**: Saves chats, settings, profiles, and call logs persistently using `shared_preferences`.
- **Group Chats**: Create and manage group chats.
- **Profile Customization**: Users can customize their names, avatar icons, and colors (including pure black/white).
- **Theming Engine**: Includes 12 curated themes plus the ability to pick any custom hex color.
- **In-App Notifications**: Get floating toasts when you receive messages while navigating the app.
- **Floating Mini-Call Window**: Picture-in-picture style floating pill when you navigate away from an active call.

## Getting Started

To run this project locally, ensure you have Flutter installed.

1. Clone the repository.
2. Run `flutter pub get` to install dependencies.
3. Use `flutter run` to launch on your connected device or emulator.
4. For Linux specifically, ensure the necessary dependencies for `flutter_webrtc` are present on your system.

## Project Structure

- `lib/main.dart` - Entry point and Theme setup.
- `lib/providers/` - Riverpod state management (Themes, Chats, Profiles, Calls).
- `lib/models/` - Data structures (Messages, ChatThreads, Users).
- `lib/screens/` - UI pages (Home, Chat, Settings, Profiles).
- `lib/services/` - Background services (WebRTC, mDNS, LAN Messenger, Storage).
