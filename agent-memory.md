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
└── agent-memory.md           ← Persistent AI context tracking
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

### 2026-06-30 — Session 7 (Call UI Polish & SEO)
- **Call Screen Layout Refactor**: 
  - Replaced rigid `GridView` with a dynamic `Flex`/`Wrap` layout to prevent clipping on single-stream videos and to adapt better on widescreen monitors.
  - Video tracks now use `RTCVideoViewObjectFitContain` to prevent awkward zooming and face-cropping on the remote stream.
  - Disabled scroll-wheel zooming on the `InteractiveViewer`, explicitly restricting zooming to the dedicated UI buttons.
- **Floating Emoji Dock**: Extracted the emoji buttons into a Google Meet-style floating popup dock overlaid above the video, controlled by a toggle button in the main dock.
- **Web SEO**: Heavily injected proper metadata into `web/index.html` (Open Graph, Twitter Cards, Keywords, rich meta descriptions).
- **Bug Fixes**: 
  - Fixed a `RenderFlex` overflow on the `LoginScreen`.
  - Fixed a critical "Lazy Initialization" bug where `CallProvider` was not instantiating globally, resulting in the incoming call screen silently failing to appear for receivers.

### 2026-07-02 — Session 8 (Social Preview)
- **Web SEO**: 
  - Updated `web/index.html` Open Graph and Twitter Card images to use the dedicated social preview asset.
  - Copied the asset to `web/social-preview.png` for root path access (`https://north-abyss.github.io/abyss_chat/social-preview.png`) to avoid pathing issues on GitHub Pages.
  - Optimized the social preview image to a 1.91:1 ratio (1200x630) using ImageMagick to satisfy standard Open Graph requirements.

### 2026-07-05 — Session 9 (v1.1.0 Enhancements)
- **GIF Integrations**: Added Giphy floating picker, native `.gif` fallback rendering, and an auto-pause overlay after 10 seconds.
- **UI Enhancements**: Added a sleek animated targeting box for the Web QR scanner. Rebuilt the interactive media viewer for 5x pinch-to-zoom fullscreen support.
- **Settings**: Granular in-app notification toggles to silence floating toasts independently of OS push notifications. Defaulted in-app notifications to OFF on native platforms.
- **Voice Encoding**: Opus voice encoding on Web, falling back to aacLc on native apps.
- **Connection Stability**: Fixed the PeerJS zombie connection hot-restart loop, and built an internal queueing system to prevent `Unexpected null value` crashes during signaling.
- **Call State Bypass**: Fixed the "Calling..." UI freeze on the initiator's device by firing a `call_accepted` data payload the exact millisecond the receiver presses answer, entirely bypassing the sluggish WebRTC video handshake delays.
- **App Constants & Structure**: Extracted all magic numbers (LAN ports, mDNS identifiers, timeouts) into `app_constants.dart`. Deeply sectioned large files with `// --- SECTION ---` comments for unparalleled readability.
- **Widget Fixes**: Implemented `didUpdateWidget` across `DiceRollBubble`, `CoinTossBubble`, and other activity components to prevent animations from getting stuck during ListView recycling.
- **App Resilience**: Wrapped `WidgetsFlutterBinding.ensureInitialized()` securely inside `runZonedGuarded` to prevent Zone mismatch crashes during hot restarts. Fixed CI/CD crashing on Windows due to colon characters in asset filenames.
