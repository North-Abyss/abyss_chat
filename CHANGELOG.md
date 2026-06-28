# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - P2P Calling & Web Polish
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

## [1.0.0] - Initial Release
- Released initial version featuring Material 3 theming, offline LAN mDNS discovery, basic chat UI, and encrypted local storage.
