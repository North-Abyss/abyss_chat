# How Abyss Chat Works

Abyss Chat is a completely free, open-source, decentralized chat application. Instead of storing your messages and files on a central corporate server, Abyss Chat uses WebRTC and STUN technology to punch a hole through your router and transfer data directly from your device to your friend's device (Peer-to-Peer).

## The Dock & Main Pages
The app is structured into three main sections accessible via the bottom navigation dock:

### 1. Chats
- **Purpose**: Your decentralized conversations.
- **Functionality**: Manage your direct messages and group chats. Because the app is P2P, no central server stores your messages. Messages are transmitted directly between peers and stored locally on your device.

### 2. Activity
- **Purpose**: A hub for interactive and personal features.
- **Functionality**: Play games (like Tic-Tac-Toe) with your peers, manage your personal scratchpad (with Markdown support), and see status updates.

### 3. Settings
- **Purpose**: App configuration and customization.
- **Functionality**: Customize your theme (supporting Material You dynamic colors), edit your profile, manage blocked contacts, and access advanced networking configurations.

## Infrastructure & Networking

### Open Source
The code is completely transparent. You have full control over your privacy, and the community can audit the code to ensure there are no hidden trackers or backdoors.

### Free TURN Relay (50GB/mo)
Sometimes, highly restrictive corporate firewalls prevent direct P2P connections (Symmetric NATs). When this happens, Abyss Chat automatically falls back to a 3rd-party Open Relay (TURN) server which provides 50GB of free data per month.
> [!NOTE]
> If you are a power user transferring massive files, you can configure your own private Custom TURN server in the Settings menu > Advanced Networking!
