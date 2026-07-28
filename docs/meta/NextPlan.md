# Next Plan (Roadmap)

This document outlines the upcoming improvements, features, and optimizations planned for Abyss Chat.

## 1. More Connectivity & Stability
The core of Abyss Chat is its decentralized P2P nature. To make it more reliable:
- **Background WebRTC Connections**: Ensure WebRTC connections stay alive when the app goes into the background on iOS and Android by utilizing platform-specific background execution services.
- **Improved Reconnection Logic**: If a peer drops offline, implement a persistent queue that automatically retries the connection exponentially without user intervention.
- **Relay Fallbacks**: Expand the TURN server list for restricted NATs (symmetric NATs) to ensure 100% connection success rate across strict corporate firewalls.
- **Seamless LAN to WAN Handoff**: If users disconnect from the same Wi-Fi, seamlessly migrate their TCP socket session to a WebRTC session without dropping active calls or messages.

## 2. Fast to Use App (Speed Optimizations)
- **Lazy Loading Chat Threads**: Currently, large chat histories might lag the UI on initialization. Implement `ListView.builder` with pagination for SQLite queries.
- **Image Compression**: Automatically compress large images before sending them over the DataChannel to prevent memory spikes and reduce upload time.
- **Tree-Shaking Icons & Fonts**: Enforce `--no-tree-shake-icons` dynamically in debug modes, but ensure release builds heavily tree-shake unused Material icons for smaller APKs and Web bundles.
- **Isolate Parsing**: Move heavy JSON serialization/deserialization for large message payloads off the main UI thread into a Dart Isolate.

## 3. MD Format Notes (Documentation Guidelines)
To maintain a clean and professional repository, all future documentation must adhere to the following Markdown format notes:
- **Use GitHub Alerts**: Emphasize critical information using GitHub-style alerts (e.g., `> [!NOTE]`, `> [!WARNING]`).
- **Consistent Code Blocks**: All code blocks must explicitly define the language (e.g., ````dart`, ````yaml`) for proper syntax highlighting.
- **Mermaid Diagrams**: Use Mermaid graphs for complex architecture flowcharts (like the signaling architecture).
- **Absolute Paths**: When linking to local project files, ensure the paths are relative to the repository root for clickable links in modern IDEs.

## 4. Data Backup & Recovery (.abysschat files)
To ensure user data is never lost due to encryption key changes (e.g., reinstalling the app or switching to the web version), we will implement a portable and secure data backup system.
- **Fail-safe `.bak` Files**: The `StorageService` will stop ruthlessly deleting encrypted storage files upon decryption failure. Instead, it will append `.bak` to the corrupted/unreadable files to preserve the raw data just in case.
- **E2EE Portable Backups**: Users will be able to export their chat history, contacts, and logs to a single `.abysschat` file. The user will be required to provide a password, and the exported file will be end-to-end encrypted (E2EE) utilizing PBKDF2/AES.
- **Text-Only By Default**: For speed and portability, the initial version of `.abysschat` backups will exclusively contain text data. Heavy media files (images, videos, audio) will be omitted, and this will be explicitly communicated to the user in the export/import dialogue menus.
