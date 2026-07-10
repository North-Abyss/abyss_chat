# 🧠 Agent Memory — Abyss Chat

> **Purpose**: This file is the persistent memory store for AI agents working on this project.
> It tracks project context, architectural decisions, known issues, naming conventions, and working state.
> **Always read this before making changes. Always update this after making changes.**

---

## 📋 Project Identity

# Abyss Chat - Agent Memory & Workspace Overview

**Version:** 1.0.0
**Project Goal:** A cross-platform, decentralized P2P messaging and video calling application (WhatsApp-style) running on Flutter and Riverpod.

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

Abyss Chat uses a clean, feature-driven architecture pattern centered around Riverpod for state management and WebRTC/Sockets for network operations. The `lib/` directory is organized into distinct layers to separate UI, state, domain logic, and infrastructure:

```text
abyss_chat/
├── lib/
│   ├── main.dart             ← Application entry point & theme initialization
│   ├── models/               ← Domain models & data structures
│   ├── providers/            ← Riverpod Notifiers & state controllers
│   ├── screens/              ← Top-level UI pages & routing destinations
│   ├── services/             ← Network, storage, & infrastructure logic
│   └── widgets/              ← Reusable UI components & dialogs
├── agent-memory.md           ← Persistent AI context tracking
├── CHANGELOG.md              ← Log of releases and development sessions
├── EXPLANATION.md            ← Detailed technical explanation of the codebase
├── PRIVACY.md                ← Privacy policy and data handling details
├── README.md                 ← Project setup and overview
├── RELEASE_NOTES.md          ← Notes for specific releases
└── Ref.md                    ← Miscellaneous references
```

### 1. `models/` (Domain Layer)
Contains pure Dart data structures representing the core entities of the app. These models encapsulate data and often include `fromJson`/`toJson` methods for local storage serialization, but do not contain business logic or UI dependencies.
- **`call_log.dart`**: Represents history records of past calls.
- **`chat_thread.dart`**: Represents an active conversation (1-on-1 or group).
- **`message.dart`**: Defines the ChatMessage schema, payload parsing, and timestamping.
- **`user.dart`**: Schema for saved contacts and the user's own profile.

### 2. `services/` (Infrastructure Layer)
Handles all external I/O, networking, and platform-specific operations. Services are stateless utilities that perform heavy lifting without knowing about the UI.
- **`crypto_service.dart`**: AES-GCM encryption utilities for securely wrapping message payloads.
- **`lan_messenger.dart`**: TCP socket communication for offline local network chats.
- **`mdns_service.dart`**: Multicast DNS discovery to find active Abyss peers on the LAN.
- **`notification_service.dart`**: Controls native floating toasts and background notifications.
- **`peerdart_service.dart`**: WebRTC broker utilizing PeerJS signaling for Internet calls.
- **`storage_service.dart`**: Manages persisting encrypted data locally using SharedPreferences/path_provider.

### 3. `providers/` (State Management Layer)
Acts as the bridge between the Services and the UI using `flutter_riverpod`. Providers observe services, hold the reactive state, and expose methods for the UI to trigger actions.
- **`call_provider.dart`**: Listens for WebRTC connection states, handles ringing logic, manages the active `CallSession`, and controls video/audio track states.
- **`chat_provider.dart`**: Manages the list of active threads, loaded messages, and sending logic.
- **`layout_provider.dart`**: Tracks the dynamic responsive window layout constraints (desktop split vs mobile).
- **`settings_provider.dart`**: Manages persistent app-wide settings (e.g. notifications toggles).
- **`theme_provider.dart`**: Controls Material 3 dynamic color generation and dark mode state.

### 4. `screens/` (Presentation Layer)
Contains the top-level route destinations. Screens are primarily `ConsumerWidget`s that watch Riverpod providers to reactively rebuild the UI based on state changes. They handle layout compositions and navigation but delegate core logic to providers.
- `lib/screens/group_info_screen.dart`: UI for viewing group participants, generating a Group Join QR code, renaming the group, and uploading custom group profile images.
- `lib/screens/chat_screen.dart`: Primary UI for sending/receiving messages (supports multimedia).
- **`call_log_screen.dart`**: UI for viewing past audio/video calls.
- **`call_screen.dart`**: The main WebRTC audio/video call UI with dynamic video grids and controls.
- **`chat_screen.dart`**: Active conversation view with message bubbles, media previews, and text input.
- **`contact_profile_screen.dart`**: Detailed view of a specific user.
- **`create_group_screen.dart`**: Flow to initialize a new group.
- **`group_info_screen.dart`**: Flow to add/remove members from an existing group.
- **`home_screen.dart`**: The primary dashboard listing recent chats, contacts, and floating action buttons.
- **`login_screen.dart`**: Initial splash screen for new users to set their name and connect to the network.
- **`my_qr_screen.dart`**: Displays the user's ID as a QR code.
- **`qr_scan_screen.dart`**: Camera scanner to instantly add a peer by scanning their QR code.
- **`responsive_layout.dart`**: The root responsive shell that controls the desktop split-pane vs mobile navigation.
- **`settings_screen.dart`**: Configuration page for themes, notifications, and wiping account data.

### 5. `widgets/` (UI Component Layer)
Houses reusable, stateless, or localized-state UI elements that are shared across multiple screens to enforce DRY principles and maintain visual consistency.
- **`abyss_snackbar.dart`**: Reusable elegant floating slide-in snackbar.
- **`floating_dock.dart`**: The Google Meet style UI component for floating call actions/emojis.
- **`message_text_content.dart`**: Rich text widget that parses links and renders previews/videos inline.
- **`user_avatar.dart`**: Consistent circular avatar rendering names/colors or icons.
- **`user_search_delegate.dart`**: The global search bar logic for finding contacts and groups.
- **`wps_button.dart`**: UI component for quick connect/scan triggers.

### Key Architecture Rules
- **State Management**: Use `flutter_riverpod` for all reactive state. Avoid complex `StatefulWidget`s unless the state is purely ephemeral (like text field focus or simple animations).
- **Service Injection**: Services should not access Providers. Providers wrap Services and expose them to the UI.
- **UI Design**: Strictly follow Material 3 design guidelines. Use dynamic `Theme.of(context)` colors instead of hardcoded hex values.
- **Platform Agnostic**: Do not use platform-specific plugins (like `dart:io` exclusively) without providing a Web fallback, ensuring the app runs across Android, iOS, Windows, Linux, and Web simultaneously.

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
- [x] In-App Notification System (with toggles and deduplication)
- [x] QR Code Generator & Scanner (`mobile_scanner` / `qr_flutter` with Web support and overlay animations)
- [x] Global Search (`SearchDelegate` for contacts & LAN peers)
- [x] Contact Blocking & Deletion (Persistent ignored list)
- [x] Resilient Hot Restart Handling (PeerJS zombie connection handling & Stream disposal)
- [x] Cross-Platform Voice Messages (Opus encoder on Web, aacLc on Mobile/Desktop)
- [x] Floating Emoji Keyboard & GIF Dialog Picker
- [x] Profile Sync Broadcasting across active WebRTC connections

---

## 📌 Conventions & Guidelines

1. **State Management** — Always use Riverpod providers instead of `StatefulWidget` where possible.
2. **Platform Agnostic** — Do not use platform-specific plugins unless absolutely necessary, to maintain "all platform" support.

---

## 🔗 Reference Repositories

- [Trackify-Flutter](https://github.com/North-Abyss/Trackify-Flutter) — Reference for GitHub actions and git sync files.

