# 🧠 Agent Memory — Abyss Chat

> **Purpose**: This file is the persistent memory store for AI agents working on this project.
> It tracks project context, architectural decisions, known issues, naming conventions, and working state.
> **Always read this before making changes. Always update this after making changes.**

---

## 📋 Project Identity

| Field               | Value                                             |
|---------------------|---------------------------------------------------|
| **App Name**        | Abyss Chat                                        |
| **Type**            | Cross-platform Flutter App (Teams/WhatsApp clone) |
| **Hosting/Deploy**  | All Platforms (Android, iOS, Web, Desktop)        |
| **Core Tech**       | Flutter, Dart, Riverpod, P2P Mesh, Local JSON     |
| **Repo Path**       | `/mnt/sda5/Projects/Flutter Projects/Com/abyss_chat`|
| **Live Web App**    | [north-abyss.github.io/abyss_chat/](https://north-abyss.github.io/abyss_chat/) |
| **GitHub Repo**     | [North-Abyss/abyss_chat](https://github.com/North-Abyss/abyss_chat) |

---

## 🏗️ Architecture Overview

```text
abyss_chat/
├── lib/
│   ├── main.dart
│   ├── models/          ← Data structures (e.g. ChatMessage)
│   ├── providers/       ← Riverpod state management
│   ├── screens/         ← UI Pages
│   ├── widgets/         ← Reusable UI components
│   └── services/        ← Network / JSON parsing logic
└── agent-memory.md      ← THIS FILE
```

### Key Architecture Rules
- Use `flutter_riverpod` for all state management.
- Hardcode initial data using JSON structures for UI testing.
- UI must follow Material 3 design strictly.
- Build for all platforms simultaneously.

---

## 🎨 Design System & UI

| Token/Element      | Value/Description                    |
|--------------------|--------------------------------------|
| **Theme Mode**     | Dynamic (Dark/Light)                 |
| **Color Scheme**   | Material 3 Dynamic Color             |

---

## 📦 Dependencies & Third-Party Services

| Component           | Source/Version                    | Purpose                        |
|---------------------|-----------------------------------|--------------------------------|
| `flutter_riverpod`  | pub.dev                           | State Management               |
| `google_fonts`      | pub.dev                           | Typography                     |

---

## 🖥️ Screen / Page Inventory

| # | Screen/Page       | Route / Path           | Description                                     |
|---|-------------------|------------------------|-------------------------------------------------|
| 1 | `HomeScreen`      | `/`                    | Chat lists, recent messages                     |
| 2 | `ChatScreen`      | `/chat`                | Active conversation UI                          |

---

## ✅ Working Features

- [x] Project initialized
- [x] Agent Memory created
- [x] JSON Mocks implemented (Persistent Local Storage added)
- [x] Material 3 Shell built
- [x] Dynamic Theming (Curated + Custom Colors)
- [x] P2P WebRTC & LAN Socket foundations
- [x] Chat Screen with floating Emoji Picker
- [x] Calling UI (Audio/Video stubs + Floating Mini-Call Window)
- [x] Group Chats
- [x] Profile Management & Settings (with Hex Colors)
- [x] In-App Notification System
- [x] QR Code Generator & Scanner (`mobile_scanner` / `qr_flutter`)
- [x] Global Search (`SearchDelegate` for contacts & LAN peers)
- [x] Contact Blocking & Deletion (Persistent ignored list)

---

## 📌 Conventions & Guidelines

1. **State Management** — Always use Riverpod providers instead of `StatefulWidget` where possible.
2. **Platform Agnostic** — Do not use platform-specific plugins unless absolutely necessary, to maintain "all platform" support.

---

## 🔗 Reference Repositories

- [Trackify-Flutter](https://github.com/North-Abyss/Trackify-Flutter) — Reference for GitHub actions and git sync files.

---

## 🔄 Session Log

### 2026-06-27 — Session 1
- Initial project bootstrapping.
- Named the project "Abyss Chat".
- Decided on P2P Mesh and PocketBase for backend, but starting with JSON dummy data to build the UI first.
- Finished full Phase 7 Implementation:
  - Added SharedPreferences for local storage
  - Built full Material 3 dynamic theme system with custom color support
  - Created Home, Chat, Settings, Groups, Profile, and Call screens
  - Replaced all hardcoded WhatsApp colors with dynamic colorScheme tokens
- Finished Phase 8 Polish:
  - Replaced bottom sheet emoji picker with a floating overlay menu
  - Added hex color input to Custom Color picker
  - Added black/white options to Profile avatars
  - Built `InAppNotificationService` for floating toast alerts
  - Built `MiniCallOverlay` to show a floating draggable pill when minimizing calls
  - Integrated `flutter_webrtc` media streams into `PeerDartService`

### 2026-06-28 — Session 2 (Phase 9 Polish & WebRTC)
- Implemented True P2P Audio/Video streaming using `RTCVideoRenderer` and `getUserMedia`.
- Added Desktop/Web specific UI polishes:
  - Floating left-pane layout without harsh divider lines.
  - Interactive "Copy ID" chip on the Home screen App Bar.
  - Added WhatsApp-style keyboard shortcuts (Enter to send, Shift+Enter to newline).
- Polished Notifications:
  - Smart Notification Silencer (mutes toast if the user is in the active chat or active call).
  - Swapped bottom snackbars for slide-in notifications globally.
  - Fixed Web Platform bugs:
    - Bypassed `path_provider` `MissingPluginException` by using `SharedPreferences` for Web encrypted file storage.
    - Removed duplicate `Hero` tags in the desktop split-pane layout to prevent exceptions.
    - Fixed `pubspec.yaml` to correctly serve web assets.

### 2026-06-28 — Session 3 (Phase 11 QR & Search)
- Reset project versioning to `v0.0.0` baseline across `pubspec.yaml`, GitHub CI/CD, and CHANGELOG.
- Implemented **QR Code Generator & Scanner**:
  - `MyQRScreen` generates a QR code from the user's Peer ID.
  - `QRScanScreen` uses `mobile_scanner` to scan and connect instantly.
- Implemented **Global Search** via `SearchDelegate` to find saved contacts and nearby LAN peers.
- Added full **Contact Management**:
  - Implemented true blocking in `ChatProvider` & `StorageService` using `blocked.abyss` (silently drops incoming messages).
  - Deleting a contact now automatically wipes their entire chat history.
  - Added safety confirmation dialogs for both blocking and deleting.
