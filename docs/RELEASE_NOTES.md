# Abyss Chat v1.1.4 Release Notes

We are thrilled to announce the release of **Abyss Chat v1.1.4**, bringing significant quality-of-life UI improvements, enhanced WebRTC stability, and smarter chat management.

## 🌟 What's New & Improved

### UI & UX Enhancements
- **WhatsApp-Style Message Grouping:** Consecutive messages sent by the same user within 2 minutes are now visually grouped together! The chat bubbles dynamically adjust their border radiuses and margins, giving your conversations a much cleaner, cohesive look.
- **Floating Menus:** Say goodbye to awkward bottom sheets on desktop and tablet screens! The Attachment Menu, Games Menu, and Activity Launcher are now beautiful, centered floating dialogs that adapt perfectly to large screens.
- **Theme-Aware Mini-Games:** The Tic-Tac-Toe grid and other in-chat mini-games now automatically adapt to your device's light and dark mode, using `surfaceContainerHighest` colors for optimal visibility instead of hardcoded grays.
- **Game History:** When you finish a game of Tic-Tac-Toe or Guess the Word, the winner (or draw) is now automatically announced in the chat thread and saved to the message history permanently!

### Logic & Bug Fixes
- **Smart Thread Deduplication:** Fixed an issue where duplicate chat threads could appear in your list. Threads are now strictly merged based on the peer's unique ID/PIN, keeping your conversations organized.
- **WebRTC "Bad State" Crash Fix:** Resolved a critical crash (`Bad state: Cannot add new events after calling close`) that occurred when attempting to sync data to a closed connection. This vastly improves stability when users minimize the app or lose connection abruptly.
- **Optimized Web Discovery:** Reduced the number of default STUN/TURN servers to 3. This resolves the browser warning `Using five or more STUN/TURN servers slows down discovery` and speeds up the initial WebRTC connection phase. 

*Note for Web Users: Make sure to hard refresh (Ctrl+Shift+R) your browser if you are still experiencing old WebRTC cache warnings.*

---
**Thank you for using Abyss Chat!** As always, your conversations remain completely decentralized, encrypted, and serverless.
