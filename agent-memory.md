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

Abyss Chat uses a clean, **Feature-First Architecture** pattern centered around Riverpod for state management and WebRTC/Sockets for network operations. The `lib/` directory is organized into distinct feature modules to separate domain logic and presentation, backed by core network utilities:

```text
abyss_chat/
├── lib/
│   ├── main.dart             ← Application entry point
│   ├── app/                  ← Root responsive layouts & global providers
│   ├── core/                 ← App-wide constants, themes, & shared widgets
│   ├── features/             ← Feature modules (auth, calling, chat, contacts, groups, qr, settings)
│   └── network/              ← Infrastructure services (WebRTC, LAN, Storage, Crypto)
├── agent-memory.md           ← Persistent AI context tracking
├── CHANGELOG.md              ← Log of releases and development sessions
├── EXPLANATION.md            ← Detailed technical explanation of the codebase
├── PRIVACY.md                ← Privacy policy and data handling details
├── README.md                 ← Project setup and overview
├── RELEASE_NOTES.md          ← Notes for specific releases
└── Ref.md                    ← Miscellaneous references
```

### 1. `features/` (Feature Modules)
The application is split into independent feature directories. Each feature contains its own logical layers:
- **`domain/`**: Contains pure Dart data models (e.g. `User`, `ChatThread`, `Message`) and Controllers (Riverpod Notifiers that manage the state for this feature).
- **`data/`**: Contains Repositories that interface with the `network/` services for reading/writing persistent data.
- **`presentation/`**: Contains the UI layers, broken down into `screens/` (top-level routes) and `widgets/` (components specific to this feature).

**Key Features:**
- `chat`: Thread management, real-time message exchange, media handling.
- `calling`: WebRTC audio/video call session management and history logs.
- `contacts`: Identity management, profile syncing, connection requests.
- `groups`: Group creation, QR invites, and roster management.
- `settings`: Notifications toggles, permissions, privacy policy.
- `auth`: Initial splash screen and profile creation.
- `qr`: QR code scanning and generation utilities.

### 2. `network/` (Infrastructure Layer)
Handles all external I/O, networking, and platform-specific operations. Services are stateless utilities that perform heavy lifting without knowing about the UI or Feature logic.
- **`crypto_service.dart`**: AES-GCM encryption utilities for securely wrapping message payloads.
- **`lan_messenger.dart`**: TCP socket communication for offline local network chats.
- **`mdns_service.dart`**: Multicast DNS discovery to find active Abyss peers on the LAN.
- **`peerdart_service.dart`**: WebRTC broker utilizing PeerJS signaling for Internet calls.
- **`storage_service.dart`**: Manages persisting encrypted data locally using SharedPreferences/path_provider.

### 3. `core/` & `app/` (Shared Layer)
Houses reusable utilities, UI elements, and constants that are shared across multiple features to enforce DRY principles and maintain visual consistency.
- **`app/responsive_layout.dart`**: Controls the desktop split-pane vs mobile navigation.
- **`core/theme/theme_provider.dart`**: Controls Material 3 dynamic color generation and dark mode state.
- **`core/widgets/`**: Reusable generic components (e.g. `abyss_snackbar.dart`, `user_avatar.dart`).

### Key Architecture Rules
- **State Management**: Use `flutter_riverpod` for all reactive state. Controllers in `domain/` wrap Services in `network/` and expose state to the UI.
- **Feature Independence**: Features should minimize cross-dependencies. If a widget or model is used by many features, it belongs in `core/`.
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

