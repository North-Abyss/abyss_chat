# Abyss Chat - v1.1.4+ 🚀

Welcome to **Abyss Chat v1.1.4+**! This release introduces a massive underlying infrastructure upgrade for connections, robust network recovery, and resolves several critical bugs that were causing duplicate contacts and call collisions.

## 🎁 What's New

*   **Multi-Tier TURN/STUN Infrastructure**: Implemented a robust, free fallback connection system utilizing Google STUN, Cloudflare STUN, and Metered Open Relay TURN. This provides ultra-fast direct P2P connections and a reliable fallback for restrictive corporate NATs without requiring self-hosting.
*   **Smart Peer Reconnection**: Implemented automatic network recovery. The app now tracks known active peers and intelligently re-establishes dropped data channels and signaling connections if the network goes down.
*   **Abyss Chat**: The Android app name has finally been fixed to read "Abyss Chat" on your home screen instead of the internal `abyss_chat` identifier.

## 🛠️ Critical Bug Fixes

*   **Contact Duplication Fixes**: Resolved a major issue causing duplicate contacts (e.g., "Peer ID..." or "Scanned Peer") during hot-reloads and "Connect via ID" flows. The system now perfectly merges placeholders with real names and stops aggressively mutating Web IDs.
*   **Call Glare Collision**: Fixed the bug where two people calling each other simultaneously would get stuck ringing forever. Added deterministic tie-breaking logic.
*   **Hardware Permission Leaks**: Reordered call teardown logic to guarantee the camera and mic hardware are immediately released when a call ends, turning off the green OS indicator dot. Fixed a similar memory leak in the QR scanner.
*   **QR Contact Naming**: The QR scanner now correctly parses the contact's real display name from the JSON payload instead of hardcoding "Scanned Peer".
*   **Notification Toggle Desync**: Fixed mismatched default values between UI toggles and the notification service, ensuring system and in-app notifications obey user preferences perfectly.

---
