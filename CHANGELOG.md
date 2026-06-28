# Changelog

All notable changes to this project will be documented in this file.

## [0.0.0] - In Development
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
