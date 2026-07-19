# Abyss Chat - v1.1.2 🚀

Welcome to **Abyss Chat v1.1.2**! This release brings a massive Voice Recorder overhaul, a sleek About Dialog, and major chat screen performance optimizations.

## 🎁 What's New

*   **Voice Recorder Overhaul**: The voice messaging experience has been completely rewritten. Enjoy a modern WhatsApp-style tap-to-record interface, smooth sliding playback animations, and a shiny new preview mode before you send!
*   **System Emoji Fonts**: Reconfigured the Emoji Picker to natively use zero-latency system fonts, completely eliminating the sluggish web-font loading delay.
*   **About Abyss Dialog**: Added a beautiful new App Info mini-window in Settings. It dynamically reads the version and includes a direct link to check for new GitHub releases.
*   **Massive Code Optimization**: Extracted heavy widgets like `AudioMessageBubble` and `GifPlayer` out of the main chat screen file, drastically reducing code bloat and improving app maintainability.

## 🛠️ Critical Bug Fixes

*   **Call Ending Spam**: Fixed an annoying bug where rapidly tapping the "End Call" button would spam the chat log with multiple duplicate "Call Ended" messages.
*   **About Dialog Layout Constraint**: Prevented the new About Dialog from stretching awkwardly across the entire screen on Web/Desktop by enforcing a clean, phone-like aspect ratio constraint.


