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
- [x] P2P Audio/Video Calling (1-on-1 and Group Mesh)
- [x] Group Chats
- [x] Strict Mutual Contacts Enforcement (Privacy)
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

### 2026-06-28 — Session 4 (Connection Resilience & Rich Previews)
- **PeerDart Stability**: Fixed a critical "Bad state" crash that occurred upon reconnections by explicitly tracking and canceling `StreamSubscription`s in `PeerDartService`.
- **Account Data Isolation**: Separated "Log Out" (disconnect only) and "Delete Account" (full local wipe). The full wipe cleans SharedPreferences, deletes encrypted `.abyss` files, and resets the AES key in `CryptoService` to prevent data merging between accounts.
- **Enhanced Call Signaling**: Added a `call_request` packet via the WebRTC data channel prior to opening the media stream, allowing the UI to show the caller's true name and avatar instantly. Added 'Connection failed' UI state for dropped calls.
- **Rich Media & Link Previews**: 
  - Integrated `url_launcher`, `any_link_preview`, and `video_player`.
  - Automatically parses URLs in chat. Web URLs render rich preview cards.
  - Image URLs render inline.
  - Video URLs (`.mp4`, `.webm`) render a playable inline video widget.
- **Web Fallback Improvements**: Added a manual entry text field to the Web QR screen, and a `CircularProgressIndicator` for the mobile camera initialization phase.

### 2026-06-28 — Session 5 (Group UI & Call Fixes)
- **P2P Group Chat**: Fixed group message routing by injecting a `groupId` into the message payload. Fixed background queue connecting loop that erroneously attempted WebRTC peer connections against the Group UUID rather than iterating through its members.
- **Group Creation UX**: Users can now instantly create a group by providing just a name, and dynamically add members later using the new "Add Participants" sheet inside Group Info.
- **Call Screen Fixes**: Fixed a bug where incoming calls incorrectly loaded outgoing UI controls, preventing users from answering the call.
- **Connection Stability**: Fixed the internal `peerId` routing loop. Calling `ref.invalidate()` on core providers now completely resets Bad State errors on logout or account deletion.

### 2026-06-29 — Session 6 (Group Calls & Mutual Contacts)
- **Mutual Contacts Enforcement**: Added strict validation in `lan_messenger.dart` and `peerdart_service.dart`. Incoming connections from unknown peers (not in the contacts list) are now instantly rejected and their sockets destroyed.
- **Robust Call States**: Refactored `CallSession` and `CallNotifier` to listen to `MediaConnection` close/error events. Calls now clean up properly on timeout or unexpected drops, fixing UI freeze issues.
- **Group Calls (P2P Mesh)**: Enabled Audio and Video group calls. 
  - The app establishes a P2P mesh (connecting to every member).
  - Added a warning dialog when calling groups larger than 10 members.
  - Implemented a dynamic `GridView` in `CallScreen` to render multiple remote participants.
