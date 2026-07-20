# Changelog

All notable changes to this project will be documented in this file.

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
