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
