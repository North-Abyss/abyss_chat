# Abyss Chat

A modern, cross-platform Flutter application serving as a P2P WhatsApp-style clone. It uses WebRTC and local network discovery (mDNS) to connect peers without a central server. Built for all platforms simultaneously.

**Live Web App:** [https://north-abyss.github.io/abyss_chat/](https://north-abyss.github.io/abyss_chat/)  
**GitHub Repository:** [North-Abyss/abyss_chat](https://github.com/North-Abyss/abyss_chat)  
**Download Latest Release (Native Apps):** [Download v1.1.2](https://github.com/North-Abyss/abyss_chat/releases/latest)
<div align="center">
    <img src="assets/abyss-chat.png" alt="Logo" width="128" style="border-radius: 18px; margin-bottom: 24px;">
    
  <br>
  
  <img src="assets/Screenshot-01.png" alt="Screenshot 1" width="250" style="border-radius: 12px; margin: 8px; box-shadow: 0 8px 24px rgba(0,0,0,0.15);">
  <img src="assets/Screenshot-02.png" alt="Screenshot 2" width="250" style="border-radius: 12px; margin: 8px; box-shadow: 0 8px 24px rgba(0,0,0,0.15);">
  <img src="assets/Screenshot-03.png" alt="Screenshot 3" width="250" style="border-radius: 12px; margin: 8px; box-shadow: 0 8px 24px rgba(0,0,0,0.15);">
</div>

## 📱 Features

- **P2P Communication** - Uses WebRTC for true peer-to-peer data channels and audio/video calling (supports both 1-on-1 and Group Mesh calls).
- **Offline Sync** - Securely synchronizes missed messages and call logs automatically upon reconnection.
- **Call Logging** - Full integration of voice and video calls into standard chat threads.
- **System Notifications** - Cross-platform notification support (Web APIs, Android/iOS Local Notifications) when the app is in the background.
- **Mutual Contacts Only** - Strict privacy enforcement instantly rejects incoming connections from unknown peers not in your local contacts list.
- **Local Network Discovery** - Uses mDNS (Multicast DNS) and LAN TCP sockets to find and connect to peers on the same local network, working completely offline.
- **Material 3 Design** - Fully customized dynamic theming support with beautiful UI following Material 3 guidelines, including desktop/web responsive split-pane layouts.
- **Persistent Storage** - Saves chats, settings, profiles, and call logs securely (using `path_provider` on native and `shared_preferences` gracefully falling back on Web).
- **Storage Management** - Granular control over your device storage. View visual breakdowns of media vs chat usage, and clear specific chat caches just like WhatsApp.
- **Web Persistent Storage** - Web users get true persistent offline media caching via IndexedDB (`idb_shim`), allowing endless sharing without crashing the browser.
- **Group Chats & Calls** - Create and manage local group chats, and initiate P2P Group Video Calls with dynamic grid layouts.
- **Profile Customization** - Users can customize their names, avatar icons, and colors (including pure black/white).
- **Theming Engine** - Includes 12 curated themes plus the ability to pick any custom hex color.
- **Smart Notifications** - Slide-in floating toasts for incoming messages that automatically silence themselves if you're actively speaking to the sender.
- **Rich Media & Link Previews** - Automatic URL parsing in chats. Web links show rich preview cards, and direct video/image links render inline with playback support.
- **Floating Mini-Call Window** - Picture-in-picture style floating pill when you navigate away from an active call, plus full Answer/Decline call screens.
- **Desktop Keyboard Support** - Use `Enter` to seamlessly send messages and `Shift+Enter` for multiline text, just like WhatsApp Web.
- **End-to-End Encrypted**: All communications are encrypted over WebRTC data channels.
- **Group Calling**: Full Mesh group video/audio calling (up to 10 participants!).
- **Group Customization & QR Join**: Easily customize group names/photos and invite friends instantly by letting them scan your Group QR Code!
- **Cross-Platform**: Runs on Android, iOS, Windows, macOS, Linux, and the Web.
- **Cloud CI/CD Pipeline** - Automated GitHub Actions release builds for Android, Windows, and Linux on every `v*` tag.
- **Cloud Web Deploy Automation** - Web PWA releases are now fully automated and deployed to GitHub Pages via a manual-trigger Cloud Actions workflow (`web-deploy.yml`), eliminating slow local compilations.
- **Maintainable Codebase** - Centralized `AppConstants` hub and deeply documented structural layout for easy onboarding.

## 🏗️ Architecture

Abyss Chat follows a clean architecture pattern with a clear separation of concerns, built for all platforms.

> **📚 Deep Dives:**
> - Check out [EXPLANATION.md](EXPLANATION.md) for a comprehensive Q&A and a visual Mermaid diagram of the architecture (great for interviews!).
> - Check out [agent-memory.md](agent-memory.md) for a full breakdown of the directory structure and project session logs.

### State Management
- **Riverpod** (`flutter_riverpod: ^3.3.2`) - Used for reactive state management.
  - Handles themes, chat states, profiles, active calls, and data synchronization.

### Data & UI Integrations
- **WebRTC** (`flutter_webrtc: ^1.5.2` & `peerdart: ^0.5.6`) - Real-time P2P data channels and media streams.
- **Network Discovery** (`nsd: ^5.0.1`) - Multicast DNS for finding local peers offline.
- **SharedPreferences** (`shared_preferences: ^2.5.5`) - Local device storage for chats and metadata.
- **UUID** (`uuid: ^4.5.3`) - Generates unique identifiers.
- **Animations** (`flutter_animate: ^4.5.2`) - Beautiful UI transitions and micro-animations.
- **Emoji Picker** (`emoji_picker_flutter: ^4.4.0`) - Floating emoji overlay for chat messages.
- **Local Notifications** (`flutter_local_notifications: ^22.0.1`) - Native background and local notifications.

### Key Components

The app follows a **Feature-First Architecture** divided into:

- **`lib/core/`**: App-wide constants, theming, and shared widgets.
- **`lib/features/`**: The main business logic grouped by domain (e.g., `chat`, `calling`, `contacts`, `auth`). Each feature contains its own `data`, `domain`, and `presentation` layers.
- **`lib/network/`**: Cross-cutting infrastructure services including WebRTC handshakes, mDNS discovery, and encrypted local storage.
- **`lib/app/`**: High-level app initialization and responsive layout wrappers.

## 🚀 Getting Started

To run this project locally, ensure you have Flutter installed.

1. Clone the repository.
2. Run `flutter pub get` to install dependencies.
3. Use `flutter run` to launch on your connected device or emulator.
4. For Linux specifically, ensure the necessary dependencies for `flutter_webrtc` are present on your system.

## 📖 Usage Guide

Abyss Chat is a 100% decentralized P2P application. This means there are no servers storing your messages or routing your data!

1. **Setting up your Profile:** When you first launch the app, enter a display name and choose a unique Avatar color/icon.
2. **Connecting to Peers Locally:** If you and your friends are on the same Wi-Fi network, the app will automatically discover them (using mDNS). They will appear instantly on your screen!
3. **Connecting Globally (Internet):** If you are not on the same Wi-Fi, you can still connect anywhere in the world! Simply tap **"Connect via ID"** and enter your friend's 6-digit Peer ID (found on their profile or QR Code). Both of you must have the app open and connected to the internet.
4. **Group Chats:** You can create Group Chats and invite your peers. Note: Group chats and calls are Full Mesh P2P, meaning your device connects directly to every other person. Large groups (10+ people) require strong internet connections and devices.
5. **WPS Pairing:** If you are physically next to someone, you can use the WPS (Wi-Fi Protected Setup) style button to instantly pair without typing IDs.

## ⚖️ Legal & Privacy

- **Privacy Policy:** Abyss Chat is heavily focused on privacy. We collect zero data. Read the full [Privacy Policy](PRIVACY.md).
- **License:** This project is open-source and licensed under the [MIT License](LICENSE).

---

## 📐 Architecture Diagrams

### 5.1 System Architecture (Flutter & WebRTC Overview)

A holistic view of all layers in the Abyss Chat application — from the Flutter UI down to the peer-to-peer network layer.

```mermaid
graph TD
    subgraph Client ["📱 Flutter Client (All Platforms)"]
        direction TB
        subgraph Presentation ["🎨 Presentation Layer — lib/features/*/presentation/"]
            UI_Home["HomeScreen\n(Chat List)"]
            UI_Chat["ChatScreen\n(Messages)"]
            UI_Call["CallScreen\n(Video / Audio)"]
            UI_Contacts["ContactsScreen"]
            UI_Settings["SettingsScreen"]
            UI_Auth["AuthScreen\n(Profile Setup)"]
        end

        subgraph Domain ["🧠 Domain Layer — lib/features/*/domain/"]
            ChatCtrl["ChatController\n(Riverpod Notifier)"]
            CallCtrl["CallController\n(Riverpod Notifier)"]
            ContactCtrl["ContactController\n(Riverpod Notifier)"]
            ThemeCtrl["ThemeController\n(Riverpod Notifier)"]
        end

        subgraph Data ["🗄️ Data Layer — lib/features/*/data/"]
            ChatRepo["ChatRepository"]
            ContactRepo["ContactRepository"]
            CallRepo["CallLogRepository"]
        end

        subgraph Network ["🌐 Network Layer — lib/network/"]
            PeerDart["PeerDartService\n(WebRTC / PeerJS)"]
            LanMsg["LanMessenger\n(TCP Sockets)"]
            mDNS["mDNSService\n(Local Discovery)"]
            Crypto["CryptoService\n(AES-GCM)"]
            Storage["StorageService\n(SharedPrefs / File)"]
        end

        subgraph Core ["⚙️ Core — lib/core/"]
            Constants["AppConstants\n(Ports, IDs, UI tokens)"]
            Theme["ThemeProvider\n(Material 3 Dynamic Color)"]
            Widgets["Shared Widgets\n(Avatar, Snackbar, etc.)"]
        end
    end

    subgraph External ["☁️ External Services"]
        PeerServer["PeerJS Signaling Server\n(WebRTC Handshake Only)"]
        STUN["STUN / TURN Servers\n(ICE Candidate Discovery)"]
    end

    subgraph Peers ["👥 Remote Peers"]
        InternetPeer["Internet Peer\n(WebRTC P2P)"]
        LANPeer["LAN Peer\n(TCP Socket)"]
    end

    %% Presentation → Domain
    UI_Home & UI_Chat & UI_Call & UI_Contacts & UI_Settings --> ChatCtrl
    UI_Call --> CallCtrl
    UI_Contacts --> ContactCtrl
    UI_Settings --> ThemeCtrl

    %% Domain → Data
    ChatCtrl --> ChatRepo
    CallCtrl --> CallRepo
    ContactCtrl --> ContactRepo

    %% Data → Network
    ChatRepo --> Storage
    ContactRepo --> Storage
    CallRepo --> Storage

    %% Domain → Network Services
    ChatCtrl --> Crypto
    ChatCtrl --> PeerDart
    ChatCtrl --> LanMsg
    CallCtrl --> PeerDart
    ContactCtrl --> mDNS

    %% Network → External
    PeerDart -->|SDP Offer/Answer + ICE| PeerServer
    PeerDart -->|ICE Candidate Lookup| STUN

    %% Network → Peers
    PeerDart <-->|"Encrypted WebRTC\nData Channel / Media Stream"| InternetPeer
    LanMsg <-->|"Encrypted TCP\nSocket Packets"| LANPeer
    mDNS -->|"_abysschat._tcp\nmDNS Broadcast"| LANPeer

    %% Core wiring
    Theme --> UI_Home & UI_Chat & UI_Call
    Constants --> PeerDart & LanMsg & mDNS
```

---

### 5.2 Use Case Diagrams

**Primary Actors:** `User` (local device) · `Remote Peer` (another Abyss Chat user) · `Signaling Server` (PeerJS, used only for WebRTC handshake)

```mermaid
graph LR
    User(["👤 User"])
    Peer(["👥 Remote Peer"])
    Server(["☁️ Signaling Server"])

    subgraph Profile ["👤 Profile & Identity"]
        UC1["Set Display Name"]
        UC2["Choose Avatar & Color"]
        UC3["View My Peer ID / QR"]
    end

    subgraph Discovery ["🔍 Peer Discovery"]
        UC4["Auto-Discover via mDNS\n(Same LAN)"]
        UC5["Connect via Peer ID\n(Internet)"]
        UC6["Scan QR Code"]
        UC7["WPS-Style Pairing\n(Physical Proximity)"]
    end

    subgraph Contacts ["📒 Contacts"]
        UC8["Accept / Reject\nConnection Request"]
        UC9["Block a Contact"]
        UC10["Delete a Contact"]
        UC11["Sync Profile\nfrom Peer"]
    end

    subgraph Messaging ["💬 Messaging"]
        UC12["Send Text Message"]
        UC13["Send Voice Message"]
        UC14["Share Image / Video"]
        UC15["Send Emoji / GIF"]
        UC16["View Link Preview"]
        UC17["Create Group Chat"]
        UC18["Invite Peer to Group\nvia QR"]
    end

    subgraph Calling ["📞 Calling"]
        UC19["Start 1-on-1 Voice Call"]
        UC20["Start 1-on-1 Video Call"]
        UC21["Start Group Video Call"]
        UC22["Answer / Decline Call"]
        UC23["View Floating\nMini-Call Pill"]
    end

    subgraph Settings ["⚙️ Settings"]
        UC24["Toggle Dark/Light Theme"]
        UC25["Pick Custom Color Theme"]
        UC26["Toggle Notifications"]
        UC27["View Privacy Policy"]
    end

    User --> UC1 & UC2 & UC3
    User --> UC4 & UC5 & UC6 & UC7
    User --> UC8 & UC9 & UC10 & UC11
    User --> UC12 & UC13 & UC14 & UC15 & UC16 & UC17 & UC18
    User --> UC19 & UC20 & UC21 & UC22 & UC23
    User --> UC24 & UC25 & UC26 & UC27

    UC5 -->|"Exchange SDP\n& ICE via"| Server
    UC8 & UC11 & UC12 & UC13 & UC14 & UC15 --> Peer
    UC19 & UC20 & UC21 & UC22 --> Peer
```

---

### 5.3 Data Flow Diagrams (DFD)

#### Level 0 — Context Diagram

```mermaid
graph LR
    User(["👤 User"])
    App(["🔷 Abyss Chat\nApplication"])
    Peer(["👥 Remote Peer"])
    Signal(["☁️ PeerJS\nSignaling Server"])

    User -- "Input / Actions" --> App
    App -- "UI Updates / Notifications" --> User
    App <-- "WebRTC Handshake\n(SDP + ICE)" --> Signal
    App <-- "Encrypted P2P\nMessages & Media" --> Peer
```

#### Level 1 — Internal Data Flow

```mermaid
flowchart TD
    User(["👤 User"])

    subgraph Input ["📥 Input Processing"]
        P1["1.0\nCapture User Input\n(Text / Media / Call Action)"]
    end

    subgraph Crypto ["🔐 Encryption"]
        P2["2.0\nEncrypt Payload\n(AES-GCM via CryptoService)"]
    end

    subgraph Routing ["🔀 Message Routing"]
        P3["3.0\nRoute Decision\n(LAN or Internet?)"]
    end

    subgraph Transport ["🚀 Transport"]
        P4["4.0\nSend via WebRTC\nData Channel\n(PeerDartService)"]
        P5["5.0\nSend via TCP\nSocket\n(LanMessenger)"]
    end

    subgraph Receipt ["📨 Receive & Dispatch"]
        P6["6.0\nReceive Incoming\nPacket"]
        P7["7.0\nDecrypt & Validate\nSender ID"]
        P8["8.0\nDispatch to\nChatController"]
    end

    subgraph Persist ["💾 Persistence"]
        P9["9.0\nPersist Message\n(StorageService)"]
    end

    subgraph Notify ["🔔 Notify"]
        P10["10.0\nTrigger UI Rebuild\n& Toast Notification"]
    end

    DS1[("📁 Local Storage\n(SharedPrefs / File)")]
    DS2(["👥 Remote Peer"])

    User -->|"Raw message\nor call trigger"| P1
    P1 --> P2
    P2 -->|"Encrypted blob"| P3
    P3 -->|"Internet path"| P4
    P3 -->|"LAN path"| P5
    P4 & P5 -->|"Packet"| DS2

    DS2 -->|"Incoming encrypted\npacket"| P6
    P6 --> P7
    P7 -->|"Validated message"| P8
    P8 --> P9
    P9 --> DS1
    P8 --> P10
    P10 -->|"State update"| User
    DS1 -->|"Loaded on startup"| P8
```

---

### 5.4 Network Topology Diagram

Abyss Chat supports two distinct network topologies that can run simultaneously.

```mermaid
graph TD
    subgraph Internet ["🌍 Internet — WebRTC Full Mesh"]
        direction TB
        PS["☁️ PeerJS Signaling Server\n(Handshake only — no data stored)"]
        STUN["🔄 STUN/TURN Server\n(ICE Candidate Resolution)"]

        subgraph Devices_Internet ["Connected Devices (Internet)"]
            A["📱 Peer A"]
            B["💻 Peer B"]
            C["📱 Peer C"]
            D["🖥️ Peer D"]
        end

        A & B & C & D -->|"1️⃣ Register &\nExchange SDP"| PS
        A & B & C & D -->|"2️⃣ Resolve\nPublic IP"| STUN

        A <-->|"3️⃣ Direct P2P\nWebRTC Channel\n(Encrypted)"| B
        A <-->|"3️⃣ Direct P2P\nWebRTC Channel\n(Encrypted)"| C
        A <-->|"3️⃣ Direct P2P\nWebRTC Channel\n(Encrypted)"| D
        B <-->|"3️⃣ Direct P2P\nWebRTC Channel\n(Encrypted)"| C
        B <-->|"3️⃣ Direct P2P\nWebRTC Channel\n(Encrypted)"| D
        C <-->|"3️⃣ Direct P2P\nWebRTC Channel\n(Encrypted)"| D
    end

    subgraph LAN ["🏠 Local Network — mDNS + TCP"]
        direction TB
        Router["📡 Wi-Fi Router\n(No Internet Required)"]

        subgraph Devices_LAN ["LAN Devices (Same Wi-Fi)"]
            L1["📱 Device 1\n(mDNS Host)"]
            L2["💻 Device 2\n(mDNS Host)"]
            L3["📱 Device 3\n(mDNS Host)"]
        end

        L1 & L2 & L3 -->|"_abysschat._tcp\nmDNS Broadcast"| Router
        Router -->|"Peer Discovery\nResponse"| L1 & L2 & L3

        L1 <-->|"Direct TCP\nSocket\n(AES-GCM Encrypted)"| L2
        L1 <-->|"Direct TCP\nSocket\n(AES-GCM Encrypted)"| L3
        L2 <-->|"Direct TCP\nSocket\n(AES-GCM Encrypted)"| L3
    end

    subgraph Legend ["📖 Legend"]
        direction LR
        LG1["☁️ = Cloud / External Service (Transient)"]
        LG2["📱💻🖥️ = Abyss Chat Client Device"]
        LG3["↔️ = Persistent Encrypted P2P Link"]
        LG4["→ = One-time Handshake / Discovery Signal"]
    end
```

> **Key insight:** The signaling server and STUN/TURN servers are only used during the initial WebRTC handshake (seconds). Once peers are connected, **all data flows directly between devices** with no server involvement. On a local network, the app works **100% offline** with zero cloud dependency.
