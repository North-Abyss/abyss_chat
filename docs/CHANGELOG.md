# Changelog

All notable changes to this project will be documented in this file.

## [1.1.2] - 2026-07-19
### Added
- **Voice Recorder Overhaul**: The voice messaging experience has been completely rewritten. Enjoy a modern WhatsApp-style tap-to-record interface, smooth sliding playback animations, and a shiny new preview mode before you send!
- **System Emoji Fonts**: Reconfigured the Emoji Picker to natively use zero-latency system fonts, completely eliminating the sluggish web-font loading delay.
- **About Abyss Dialog**: Added a beautiful new App Info mini-window in Settings. It dynamically reads the version and includes a direct link to check for new GitHub releases.
- **Massive Code Optimization**: Extracted heavy widgets like `AudioMessageBubble` and `GifPlayer` out of the main chat screen file, drastically reducing code bloat and improving app maintainability.

### Fixed
- **Call Ending Spam**: Fixed an annoying bug where rapidly tapping the "End Call" button would spam the chat log with multiple duplicate "Call Ended" messages.
- **About Dialog Layout Constraint**: Prevented the new About Dialog from stretching awkwardly across the entire screen on Web/Desktop by enforcing a clean, phone-like aspect ratio constraint.
