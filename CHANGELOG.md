# Changelog

All notable changes to this project will be documented in this file.

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
