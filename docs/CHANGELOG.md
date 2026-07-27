# Changelog

All notable changes to this project will be documented in this file.
## [1.1.5] - 2026-07-27
### Added
- **Full-Screen Media Experience**: Complete overhaul of the Media Viewer. Videos now play directly in full screen with a new comprehensive control bar (volume slider, play/pause, progress scrubber). Audio files display as a stunning 5:4 ratio aesthetic player card with built-in controls.
- **Smart Search Traversal**: Chat search has been completely reimagined using a scrollable positioned list. Instead of destructively filtering your chat, search now highlights matching messages and provides smooth up/down arrow traversal directly within the chat's context.
- **Dynamic Media Icons**: The media carousel now intelligently recognizes non-image files and displays clean, modern Video, Audio, and Document icons instead of broken image placeholders.
- **Draw Match History**: Mini-game ties (like in Tic-Tac-Toe) are now officially logged to the permanent chat history, so both players can keep track of their attempts!

### Fixed
- **Group Call Banner Misfire**: Fixed a major bug where Active Group Call banners would mistakenly appear in direct P2P chats instead of the designated Group Chat UI.
- **Call Disconnect Button**: Added a dedicated "End" button directly to the Active Call banner, allowing users to cleanly hang up an active call without needing to maximize the call screen.
- **Media Layout Overflows**: Fixed multiple `RenderFlex` overflow errors in the chat UI associated with extremely long audio file names and video rendering constraints.

## [1.1.4+] - 2026-07-26
### Added
- **Multi-Tier TURN/STUN Infrastructure**: Implemented a robust, free fallback connection system utilizing Google STUN and Metered Open Relay TURN. This provides ultra-fast direct P2P connections.
- **Automated CI/CD Workflows**: Added `web-deploy.yml` and `release.yml` GitHub Actions to automatically compile Native apps (APK, Linux, Windows) and Web apps via Cloud Compiler on tags.
- **Smart Peer Reconnection**: Implemented automatic network recovery. The app now tracks known active peers and intelligently re-establishes dropped data channels and signaling connections if the network goes down.

### Fixed
- **WebRTC Native-to-Web Timeout**: Reduced STUN/TURN `iceServers` array to avoid the WebRTC "Using five or more STUN/TURN servers slows down discovery" exception, perfectly resolving the Native-to-Web signaling timeouts.
- **Gradle `afterEvaluate` Order**: Fixed a build-breaking bug on CI/CD caused by an incorrect Gradle evaluation order in `android/build.gradle`.
- **Contact Duplication Bugs**: Resolved a major issue causing duplicate contacts (e.g., "Peer ID..." or "Scanned Peer") during hot-reloads and "Connect via ID" flows. The system now perfectly merges placeholders with real names and stops aggressively mutating Web IDs.
- **Call Glare Collision**: Fixed the bug where two people calling each other simultaneously would get stuck ringing forever. Added deterministic tie-breaking logic.
- **Dangling Camera Permissions**: Reordered call teardown logic to guarantee the camera and mic hardware are immediately released when a call ends, turning off the green dot. Fixed a similar memory leak in the QR scanner.
- **QR Contact Naming**: The QR scanner now correctly parses the contact's real display name from the JSON payload instead of hardcoding "Scanned Peer".
- **Notification Toggle Desync**: Fixed mismatched default values between UI toggles and the notification service, ensuring system and in-app notifications obey user preferences perfectly.
- **App Name Presentation**: Fixed the launcher label to read "Abyss Chat" instead of the raw `abyss_chat` identifier.
- **Self-Connection Spam**: Resolved a critical issue in WebRTC history synchronization where sending the wrong `threadId` caused receivers to create endless self-chat loops and flood the network with reconnect attempts.
- **Profile Cosmetic Wipe**: Fixed a bug where refreshing the page would reset the user's custom avatar icon and color to default values during auto-login.
- **Duplicate Threads**: Removed dangerous name-matching thread duplication logic. All threads are now strictly and reliably keyed by Peer ID.
- **Zombie Stream Exceptions**: Wrapped all WebRTC stream dispatchers in `Future.microtask()` to completely eliminate `Bad state: Cannot fire new event` crashes during heavy data payloads.

## [1.1.3] - 2026-07-20
### Added
- **Media Viewer Screen**: Replaced the basic inline image viewer with a full WhatsApp-style Media Viewer. Features include a bottom thumbnail carousel, swiping navigation, and a slick top app bar.
- **Multi-Selection & Bulk Actions**: Long-press any thumbnail in the Media Viewer to enter selection mode, allowing you to bulk share or download multiple media items at once!
- **Auto-Organized Downloading**: Downloading media automatically provisions an `Abyss Chat` folder and smartly routes files into `Images`, `Videos`, `Audio`, or `Documents` subfolders.
- **Storage Management Screen**: Added a new WhatsApp-style storage manager in Settings. It calculates exact footprints for your chats and media and provides a visual stacked bar chart.
- **Granular Media Deletion**: You can now view all active chats sorted by their media size and clear the media cache for specific chats, or clear everything at once while keeping your text messages safe.
- **Web Persistent Storage**: Completely overhauled Web Storage using `idb_shim` (IndexedDB). Media files on the web are now stored seamlessly in your browser's persistent cache instead of flooding memory with raw base64 URI data, preventing crashes during heavy media sharing.
- **Dynamic Media Resolution**: The chat screen dynamically resolves Web media into Object URLs on-the-fly, keeping the UI lightning fast.

### Fixed
- **Peer Reload Deduplication**: Fixed an issue in WebRTC connections where a peer hot-restarting or reloading would create cloned duplicate chat threads due to ephemeral ID changes. The system now intelligently merges reconnected threads based on peer names.
- **Web Image Flashing & Memory Leaks**: Implemented an advanced in-memory Object URL cache for the Web storage engine. This completely prevents images from flashing upon scrolling and fixes a major memory leak by explicitly revoking URLs when media is cleared.
- **Material UI Padding**: Fixed layout constraints on the Media Viewer's top app bar using `SafeArea` to perfectly respect device notches.
- **IDE Cleanups**: Addressed all Dart analyzer warnings including `dart:html` and `share_plus` deprecations, and unused imports across the UI layer.

## [1.1.2] - 2026-07-19
### Added
- **Voice Recorder Overhaul**: The voice messaging experience has been completely rewritten. Enjoy a modern WhatsApp-style tap-to-record interface, smooth sliding playback animations, and a shiny new preview mode before you send!
- **System Emoji Fonts**: Reconfigured the Emoji Picker to natively use zero-latency system fonts, completely eliminating the sluggish web-font loading delay.
- **About Abyss Dialog**: Added a beautiful new App Info mini-window in Settings. It dynamically reads the version and includes a direct link to check for new GitHub releases.
- **Massive Code Optimization**: Extracted heavy widgets like `AudioMessageBubble` and `GifPlayer` out of the main chat screen file, drastically reducing code bloat and improving app maintainability.

### Fixed
- **Call Ending Spam**: Fixed an annoying bug where rapidly tapping the "End Call" button would spam the chat log with multiple duplicate "Call Ended" messages.
- **About Dialog Layout Constraint**: Prevented the new About Dialog from stretching awkwardly across the entire screen on Web/Desktop by enforcing a clean, phone-like aspect ratio constraint.
