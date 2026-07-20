# Abyss Chat - v1.1.3 🚀

Welcome to **Abyss Chat v1.1.3**! This release introduces a beautiful new WhatsApp-style Media Viewer, a Storage Manager, and a massive Web-Persistent Storage overhaul under the hood to ensure buttery smooth performance when handling large media across the web!

## 🎁 What's New

*   **Media Viewer Screen**: Replaced the basic inline image viewer with a full WhatsApp-style Media Viewer. Features include a bottom thumbnail carousel, swiping navigation, and a slick top app bar.
*   **Multi-Selection & Bulk Actions**: Long-press any thumbnail in the Media Viewer to enter selection mode, allowing you to bulk share or download multiple media items at once!
*   **Auto-Organized Downloading**: Downloading media automatically provisions an `Abyss Chat` folder and smartly routes files into `Images`, `Videos`, `Audio`, or `Documents` subfolders.
*   **Storage Management Screen**: Head over to Settings to find the new Storage Manager! It provides a visual stacked bar chart breakdown of your app's footprint and allows you to view which chats are hoarding all your space.
*   **Granular Media Deletion**: Free up space without losing your precious texts. You can now tap the trash can next to any specific chat in the Storage Manager to delete only its downloaded media, or use the "Clear All Media Cache" button to wipe the slate clean.
*   **Web Persistent Storage (IndexedDB)**: We've completely rewritten how the Web app handles media storage. Instead of keeping heavy files suspended in RAM (which caused browser crashes), it now seamlessly chunks and saves your media natively into your browser's persistent IndexedDB cache using `idb_shim`.
*   **Dynamic Media Resolution**: The chat screen dynamically resolves Web media into Object URLs on-the-fly, keeping the UI lightning fast and drastically lowering memory consumption.

## 🛠️ Critical Bug Fixes

*   **Peer Reload Deduplication**: Fixed an issue in WebRTC connections where a peer hot-restarting or reloading would create cloned duplicate chat threads due to ephemeral ID changes. The system now intelligently merges reconnected threads based on peer names.
*   **Web Image Flashing & Memory Leaks**: Implemented an advanced in-memory Object URL cache for the Web storage engine. This completely prevents images from flashing upon scrolling and fixes a major memory leak by explicitly revoking URLs when media is cleared.
*   **Material UI Padding**: Fixed layout constraints on the Media Viewer's top app bar using `SafeArea` to perfectly respect device notches.
*   **IDE Cleanups**: Addressed all Dart analyzer warnings including `dart:html` and `share_plus` deprecations, making the codebase squeaky clean!

---

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


