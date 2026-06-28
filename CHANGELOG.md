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
- **P2P Group Chat**: Fixed group message routing by injecting a `groupId` into the message payload. Group messages are now correctly threaded into shared group chats rather than appearing as 1-on-1 messages.
- **Group Creation UX**: Users can now instantly create a group by providing just a name, and dynamically add members later using the new "Add Participants" sheet inside Group Info.
- **Connection Stability**: Fixed the internal `peerId` routing loop that caused background connection attempts to fail on Group IDs. Calls to `ref.invalidate()` on core providers now completely reset Bad State errors on logout.
- **Call Screen Fixes**: Fixed a bug where incoming calls incorrectly loaded outgoing UI controls, preventing users from answering the call. Group video calls are temporarily disabled in the UI to ensure 1-on-1 P2P call stability.
