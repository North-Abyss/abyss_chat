# Changelog

All notable changes to this project will be documented in this file.

## [1.4.0] - 2026-07-19
### Added
- **100% Offline Local WebRTC**: Built a completely native Android TCP/WebSocket signaling server that bypasses PeerJS entirely. Flutter Web clients now connect directly to the Android device's local IP address via WebSockets, instantly bootstrapping a local WebRTC Data Channel without requiring internet, cloud servers, or strict router NAT hairpinning!

## [1.2.0] - 2026-07-10
### Changed
- **Feature-First Architecture**: Completely restructured the codebase from a "Type-First" (`models/`, `screens/`, `providers/`) layout to an industry-standard "Feature-First" architecture. All code is now modularized under `lib/features/` (e.g., `chat`, `calling`, `contacts`), `lib/core/`, and `lib/network/`, drastically improving scalability and maintainability.
- **Provider Decomposition**: Split the monolithic `chat_provider.dart` into domain-specific controllers (`chat_controller.dart`, `contacts_controller.dart`, `settings_controller.dart`) to strictly enforce separation of concerns and prevent massive dependency chains.

## [1.1.1] - 2026-07-07
### Added
- **Cloud Relay Fallback**: Built a foolproof, zero-config text messaging fallback using `ntfy.sh`. If WebRTC local routing is blocked by a strict NAT Hairpinning router, text messages instantly and silently route through an encrypted cloud relay!
- **TURN Server Integrations**: Injected reliable public TURN servers into `peerdart_service.dart` to maximize WebRTC connection success rates across restrictive enterprise firewalls.

## [1.1.0] - 2026-07-05
### Added
- **GIF Picker & Auto-Pause**: Added a floating GIF picker sheet with a direct search link to Giphy. Native GIFs auto-pause after 10 seconds with a clean overlay to save battery and computing power!
- **In-App Notification Toggles**: Added granular controls in the settings screen to independently disable floating in-app notifications if you only want OS system push notifications.
- **Web QR Scanner Overlay**: Enhanced the Web fallback on the QR scan screen with a sleek animated targeting box to guide users.
- **Opus Voice Encoder**: Voice messages now dynamically encode in Opus format on Web browsers for maximum compatibility, falling back to aacLc on native apps!
- **Global App Constants**: Extracted magic numbers into a central `app_constants.dart` file and added structural segment headers across the codebase for improved readability.
- **Cloud Web Deploy Automation**: Web PWA releases are now fully automated via a manual-trigger GitHub Actions workflow (`web-deploy.yml`), eliminating slow local compilations.

### Fixed
- **Android Plugin Compilation Resilience**: Resolved a catastrophic compilation crash in `GeneratedPluginRegistrant.java` caused by `file_picker`'s Kotlin Gradle Plugin incompatibility by injecting a dynamic Java Reflection patch during the Gradle build phase.
- **Android Network Discovery**: Added missing `INTERNET`, `ACCESS_NETWORK_STATE`, and `CHANGE_WIFI_MULTICAST_STATE` permissions to the Android Manifest to unblock `nsd` mDNS discovery and WebRTC connections on physical Android devices.
- **NTFS Asset Compression Bug**: Implemented a `noCompress` workaround in `build.gradle.kts` to prevent the notorious Android Gradle `CompressAssetsWorkAction` failure on NTFS partitions mounted in Linux.
- **Zombie Connection Loop**: Fixed a critical hot restart loop where PeerJS failed to drop stale WebRTC connections, causing endless "ID is taken" errors and stream memory leaks.
- **Unexpected Null WebRTC Crash**: Built an internal queuing system to guarantee PeerJS waits for the signaling WebSocket to achieve full 'open' state before dispatching connection requests, completely eliminating "Unexpected null value" crashes.
- **GIF Animation Support**: Fixed an issue where CachedNetworkImage froze GIFs into static pictures; the app now falls back to native Image.network automatically for .gif extensions!
- **Fullscreen Image Zooming**: Fully fixed the interactive media viewer for images/GIFs. Images now span to fill maximum available bounds with 5x pinch-to-zoom capabilities, mirroring WhatsApp's behavior.
- **Call State Synchronization**: Fixed a bug where the initiator's device would get stuck on the "Calling..." screen by injecting a rapid `call_accepted` data channel packet when the receiver clicks Answer, bypassing WebRTC video stream handshake delays.
- **Activity Bubble Animations**: Fixed a bug where Dice and Coin Toss animations would get stuck and duplicate previous values due to ListView widget recycling.
- **Hot Restart Crash**: Fixed a Zone mismatch crash on native apps by properly scoping `WidgetsFlutterBinding.ensureInitialized()` within the asynchronous `runZonedGuarded` block.
- **Asset Filename Bug**: Renamed image assets containing colons to prevent Windows build runner crashes in CI/CD pipelines.


## [1.0.0] - 2026-06-30
### Added
- **Group QR Joining**: Instantly join group chats by scanning a Group QR code directly from the Home Screen.
- **Group Customization**: You can now rename groups and upload custom group profile photos!
- **Call End Syncing**: Voice calls now accurately sync their end states across devices perfectly using a 300ms packet transmit guarantee.

### Fixed
- Fixed an issue causing camera streams to crash with a `Concurrent modification during iteration` error when toggling video on and off.
- Fixed an intense bug causing the call overlay UI to duplicate itself multiple times if devices sent simultaneous handshakes.
- Handled edge case where corrupted local storage JSON files (`Invalid padding character`) caused unrecoverable errors on reboot by seamlessly self-healing/deleting.
- Fixed a bug where a generic blank icon was shown when you turned your local video off instead of your beautiful customized profile avatar!

## [0.9.3] - 2026-06-29

## [0.0.0] - In Development
- **Call Screen Layouts**: Refactored the rigid `GridView` in the Call Screen to a dynamic Flex/Wrap layout that perfectly fits single remote streams and seamlessly wraps for multiple participants.
- **Floating Emoji Dock**: Emojis in the call screen are now housed in a Google Meet-style floating popup dock above the control bar, toggled by a smiley button.
- **Video Aspect Ratio**: Remote video streams now use `Contain` instead of `Cover` to prevent face cropping and overlapping. Scroll-to-zoom is disabled on the video viewer; zooming is restricted to dedicated UI buttons.
- **Web SEO**: Added comprehensive SEO metadata to `web/index.html` including Open Graph and Twitter Card tags.
- **Bug Fixes**: Fixed a `RenderFlex` overflow on the `LoginScreen` by wrapping it in a `SingleChildScrollView`. Fixed lazy initialization of `CallProvider` that prevented the incoming call screen from appearing on the receiver's end.
- **WebRTC Calling**: Implemented true P2P video and audio streams using `getUserMedia` and `flutter_webrtc`.
- **Call Screen Polishes**: Added auto-minimizing floating PiP mode when navigating away from calls, plus Answer/Decline buttons.
- **Smart Notifications**: Toast notifications are now automatically silenced if the user is actively viewing that chat or in an active call.
- **UI & UX Enhancements**: 
  - Added desktop-friendly left-pane floating layouts.
  - Interactive "Copy ID" chip added to the home screen.
  - Replaced bottom snackbars with clean right-side slide-in notifications globally.
  - `Enter` to send, `Shift+Enter` for multiline input in the chat box on desktop/web.
- **Web Support**: Fixed `path_provider` limitations by seamlessly backing up encrypted storage to `SharedPreferences` when compiled for Web.
- **Bug Fixes**: Resolved missing asset bundle errors and duplicate `Hero` tag exceptions in split-screen mode.
- **Initial Features**: Released initial version featuring Material 3 theming, offline LAN mDNS discovery, basic chat UI, and encrypted local storage.
- **Connection Resilience**: Fixed "Bad state" crashes in PeerDart by properly tracking and canceling `StreamSubscription`s on disconnect, ensuring stable reconnections.
- **Enhanced Call Signaling**: Implemented a `call_request` protocol over the data channel to show incoming caller name and avatar before the video stream connects. Added failure UI for dropped calls.
- **Account Management**: Added a "Delete Account & Data" option that fully wipes encrypted storage and `SharedPreferences` to prevent account merging, alongside a safe "Log Out" option.
- **Rich Media & Link Previews**: Added automatic URL parsing in chat. Links now show rich preview cards, and direct image/video links render inline with playback support.
- **Web QR Fallback**: Enhanced the Web fallback on the QR scan screen with a convenient manual entry text field and added camera loading indicators for mobile.
- **P2P Group Chat**: Fixed group message routing by injecting a `groupId` into the message payload. Group messages are now correctly threaded into shared group chats rather than appearing as 1-on-1 messages.
- **Group Creation UX**: Users can now instantly create a group by providing just a name, and dynamically add members later using the new "Add Participants" sheet inside Group Info.
- **Connection Stability**: Fixed the internal `peerId` routing loop that caused background connection attempts to fail on Group IDs. Calls to `ref.invalidate()` on core providers now completely reset Bad State errors on logout.
- **Group Audio/Video Calls**: Fully implemented Group Calls using a P2P mesh topology. The Call Screen now features a dynamic GridView to render multiple participants simultaneously. Added performance warnings for large groups.
- **Mutual Contacts Enforcement**: Strict privacy implementation instantly rejects and destroys incoming LAN or WebRTC connections if the peer ID is not in your saved contacts list.
- **Call Connection Robustness**: Fixed an issue where the app's call buttons would freeze after a long call or unexpected drop. `CallNotifier` now correctly listens for stream errors and cleans up UI state automatically.

## Development Session Logs

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

### 2026-07-06 — Session 10 (Android Plugin Compilation & Web Deploy)
- **Plugin Registrant Fix via Reflection**: Resolved a critical issue where the app would install but freeze on a loading screen because Android native plugins (`shared_preferences`, `nsd`) were completely broken due to a hack deleting `GeneratedPluginRegistrant.java`.
  - **Root Cause**: Flutter was forcefully generating a Java registrant which crashed trying to compile the Kotlin-based `file_picker` plugin (KGP incompatibility).
  - **The Real Fix**: Instead of deleting the registrant or forcing Kotlin generation (which failed due to cache persistence), I injected a `doFirst` task inside `build.gradle.kts` `JavaCompile` step. This task reads `GeneratedPluginRegistrant.java` and uses **Java Reflection** to dynamically instantiate `FilePickerPlugin`. This cleanly bypasses the Java compiler error without breaking native plugin registration!
- **NTFS Asset Compression Fix**: Added `noCompress.add("")` to `build.gradle.kts` to prevent the `CompressAssetsWorkAction` from failing on Linux NTFS drives.
- **Android Network Permissions**: Added `INTERNET`, `ACCESS_NETWORK_STATE`, and `CHANGE_WIFI_MULTICAST_STATE` to `AndroidManifest.xml`, completely unblocking the `nsd` plugin and WebRTC from functioning on physical Android devices.
- **Cloud Web Deploy Automation**: Web PWA releases are now automated via a manual-trigger GitHub Actions workflow (`web-deploy.yml`). Users simply push a `web-deploy-*` tag to trigger the cloud compilation.
- **WebRTC Seamless Local Testing (TURN Server)**: Fixed a major limitation where Web-to-Mobile P2P connections failed on the exact same Wi-Fi network due to Firefox/Chrome mDNS IP obfuscation and strict router NAT Hairpinning. Injected a highly reliable, free public TURN server (`openrelay.metered.ca`) directly into `peerdart_service.dart`.
- **Cloud Relay Fallback (`CloudRelayService`)**: Built an indestructible, zero-config text messaging fallback using `ntfy.sh`. When a user's strict router aggressively blocks WebRTC local routing despite the TURN servers, text messages instantly and silently route through the encrypted cloud relay. Because Abyss Chat AES-encrypts payloads before sending, the public broker only receives opaque blobs, guaranteeing flawless delivery without compromising privacy or requiring user network configuration.
