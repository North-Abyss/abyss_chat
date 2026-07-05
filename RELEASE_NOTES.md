# Abyss Chat - v1.1.0 🚀

Welcome to **Abyss Chat v1.1.0**! This release brings massive improvements to media handling, voice messages, and connection stability.

## 🎁 What's New

*   **GIF Auto-Pause & Picker**: A brand new floating GIF picker with Giphy integration. Native GIFs now elegantly auto-pause after 10 seconds with a sleek WhatsApp-style play overlay to save battery and computing power!
*   **Zoom Like A Pro**: The interactive media viewer has been rebuilt. Images and GIFs now span to fill your screen's maximum bounds with flawless 5x pinch-to-zoom capabilities.
*   **In-App Notification Toggles**: You now have granular control in Settings to independently disable floating in-app toasts if you prefer only OS-level push notifications.
*   **Opus Voice Encoder on Web**: Voice messages now dynamically encode in Opus format on Web browsers for maximum cross-platform compatibility!
*   **Web QR Scanner Target**: Added a sleek animated targeting box overlay to the Web QR scanner fallback to guide your camera.

## 🛠️ Critical Bug Fixes

*   **Zombie Connection Loop Annihilated**: Fixed a severe hot-restart loop where PeerJS failed to drop stale WebRTC connections, completely eliminating the endless "ID is taken" errors and stream memory leaks.
*   **Unexpected Null Crash Fixed**: Built a robust internal queueing system that guarantees the PeerJS signaling WebSocket achieves full 'open' state before dispatching connection requests, banishing the `Unexpected null value` crash forever.
*   **GIF Animation Freezes**: Fixed a bug where `CachedNetworkImage` froze GIFs into static pictures.

---

## 📥 Download Instructions

Choose the installer for your platform below:
*   **Windows**: Download `AbyssChat-Windows-Setup.exe`
*   **Linux**: Download `abyss-chat-linux-x64.deb`
*   **Android (Universal)**: Download `abyss-chat-universal.apk`

*Tip: For older or specialized Android devices, use the specific architecture APKs (e.g., `armeabi-v7a` or `arm64-v8a`).*
