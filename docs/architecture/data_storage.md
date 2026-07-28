# Abyss Chat Data Storage Architecture

Abyss Chat prioritizes privacy, security, and offline-first capabilities. As a result, all data is stored locally on your device rather than on a centralized cloud database.

## Where is Data Stored?

Depending on the platform you are using, Abyss Chat stores data in different locations:

### 1. Desktop & Mobile (Windows, Linux, macOS, Android, iOS)
On native platforms, the app creates a dedicated folder inside your system's standard Documents or AppData directory.
- **Path**: Typically `Documents/AbyssChat/` or the equivalent application support directory for your OS.
- This is why you found an "Abyss" folder in your Documents!

### 2. Web Browser
If you are running the app in a web browser (Chrome, Firefox, Safari), the app cannot access your local file system directly. Instead, it uses the browser's **Local Storage** (SharedPreferences), with keys prefixed by `web_`.

### 3. User Profile (SharedPreferences)
Lightweight settings like your ID, name, avatar, etc. are stored in SharedPreferences (key-value pairs), not in files:

| Key | Type | Description |
|-----|------|-------------|
| `my_id` | `String` | Your unique peer ID (e.g. `EGTRT8`) |
| `my_name` | `String` | Your display name |
| `my_username` | `String` | Your username |
| `my_avatar_icon` | `int` | Material icon code point (e.g. `0xe491`) |
| `my_avatar_color` | `int` | ARGB color integer (e.g. `0xFF6750A4`) |
| `my_profile_image` | `String?` | File path or data URI for profile image |
| `my_profile_updated_at` | `String?` | ISO 8601 timestamp of last profile update |

---

## How is Data Stored? (The `.abyss` Files)

Inside the `AbyssChat/` folder, you will notice files with the `.abyss` extension. While they look like custom database files, they are actually **Encrypted JSON**. 

Abyss Chat does **NOT** use a traditional SQL database (like SQLite). Instead, it serializes its data models into JSON arrays, encrypts the entire string, and writes it directly to these files.

### The Core Storage Files

| File | Description |
|------|-------------|
| `conversations.abyss` | All chat threads, messages, and game snapshots |
| `contacts.abyss` | Profiles of peers you have connected with |
| `call_logs.abyss` | Voice and video call history |
| `blocked.abyss` | IDs of users you have blocked |

---

## JSON Schemas (Decrypted Format)

Below is the exact JSON format that each `.abyss` file contains after decryption.

### `conversations.abyss` → `List<ChatThread>`

```json
[
  {
    "id": "HSZVBR",
    "peer": { /* User object (see below) */ },
    "messages": [
      {
        "id": "a1b2c3-uuid",
        "senderId": "EGTRT8",
        "senderName": "web1",
        "text": "Hello!",
        "timestamp": "2026-07-27T21:07:00.000Z",
        "status": "sent",
        "type": "text",
        "localFilePath": null,
        "fileName": null,
        "fileData": null,
        "groupId": null,
        "groupName": null
      }
    ],
    "isGroup": false,
    "groupName": null,
    "groupImagePath": null,
    "members": [],
    "unreadCount": 0
  }
]
```

#### Message `type` values:
| Type | Description |
|------|-------------|
| `text` | Plain text message |
| `image` | Image with base64 data in `fileData` |
| `audio` | Voice message with base64 data in `fileData` |
| `file` | Generic file attachment |
| `system` | System notification (e.g. "user joined") |
| `activity` | Interactive activity snapshot (polls, events) stored in `fileData` as JSON |
| `game` | Game snapshot (Tic-Tac-Toe, Guessing Game result) stored in `fileData` as JSON |

#### Message `status` values:
| Status | Description |
|--------|-------------|
| `pending` | Not yet sent (queued locally) |
| `sending` | Currently being transmitted |
| `sent` | Delivered to signaling server |
| `delivered` | Received by the peer |
| `read` | Peer opened and viewed it |
| `failed` | Transmission failed |

---

### `contacts.abyss` → `List<User>`

```json
[
  {
    "id": "HSZVBR",
    "name": "LOL",
    "avatarIcon": 57857,
    "avatarColor": 4285423012,
    "isOnline": false,
    "isWpsActive": false,
    "username": "lol",
    "ipAddress": "192.168.1.5",
    "port": 46591,
    "profileImagePath": "/path/to/AbyssChat/profiles/HSZVBR.png",
    "profileUpdatedAt": "2026-07-27T20:00:00.000Z"
  }
]
```

---

### `call_logs.abyss` → `List<CallLog>`

```json
[
  {
    "id": "call-uuid-123",
    "peer": { /* User object (same schema as above) */ },
    "isVideo": true,
    "timestamp": "2026-07-27T21:00:00.000Z",
    "durationMs": 15000,
    "isOutgoing": true,
    "isMissed": false
  }
]
```

---

### `blocked.abyss` → `List<String>`

```json
["BLOCKED_PEER_ID_1", "BLOCKED_PEER_ID_2"]
```

---

## Encryption & Security

You cannot simply open a `.abyss` file in a text editor to read your messages.

When you log in, Abyss Chat generates a unique cryptographic key based on your local device identity via the `CryptoService`:

- **Write operation**: Data → JSON string → `CryptoService.encryptData()` → ciphertext written to `.abyss` file
- **Read operation**: Ciphertext from `.abyss` file → `CryptoService.decryptData()` → JSON string → parsed into Dart objects

This ensures that even if someone gains access to your computer's file system (or your browser's local storage), your chat history and contacts remain secure and unreadable without the app's cryptographic context.

If the decryption key changes (e.g. you change your peer ID), the old encrypted files become unreadable and are automatically deleted to prevent data corruption.
