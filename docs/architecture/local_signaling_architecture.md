# The Impossible Dream: 100% Offline WebRTC

Here is exactly how we are going to build a completely offline, ultra-stable WebRTC pipeline that connects a Flutter Web Browser to a Native Android device without a single cloud server.

## The Problem with Cloud Signaling
Normally, WebRTC requires a middleman (Signaling Server) to introduce two peers. `peerdart` uses PeerJS, which hosts its signaling server in the cloud. 
- If your internet drops, local WebRTC fails.
- If you hot-restart, the cloud server holds onto your old socket (Zombie state) and rejects your new connection ("ID is taken").
- If your router is strict, the cloud STUN server fails to negotiate a path back into your local network.

## The Solution: Native Local Signaling

We are going to make the Android device act as its own Signaling Server.

```mermaid
sequenceDiagram
    participant W as Web Browser (Client)
    participant A as Android (WebSocket Server)
    
    Note over W,A: 1. TCP/WebSocket Handshake
    W->>A: Connects to ws://192.168.1.5:43427
    A-->>W: WebSocket Connection Established!
    
    Note over W,A: 2. WebRTC SDP Negotiation (Over Local WS)
    W->>W: Creates RTCPeerConnection & DataChannel
    W->>W: Creates SDP Offer
    W->>A: Sends JSON: { "type": "offer", "sdp": "..." }
    
    A->>A: Creates RTCPeerConnection
    A->>A: Sets Remote Description
    A->>A: Creates SDP Answer
    A->>W: Sends JSON: { "type": "answer", "sdp": "..." }
    
    Note over W,A: 3. ICE Candidate Exchange
    W->>A: Sends Local ICE Candidates
    A->>W: Sends Local ICE Candidates
    
    Note over W,A: 4. Direct P2P Established
    W->>A: High-Speed WebRTC Data Channel Open!
    Note over W,A: WebSocket can now be closed safely.
```

### How it Works Step-by-Step
1. **The Native Server:** The Android app runs a background `HttpServer` bound to `0.0.0.0` (all interfaces) on port `43427`. It upgrades incoming HTTP requests into raw WebSockets.
2. **Discovery:** The Android app embeds its Local IP and Port into its QR Code. 
3. **The Web Client:** The Web Browser scans (or the user types) the IP. The browser instantly opens a `WebSocket` connection to the Android device over the LAN. 
4. **The Handshake:** Because they are directly connected via WebSockets, they instantly exchange their WebRTC cryptographic keys and SDP profiles. No cloud server involved.
5. **The WebRTC Upgrade:** Once WebRTC connects, the app switches to the high-performance WebRTC DataChannel for text, files, and video calling.

This completely bypasses PeerJS, eliminates Zombie ID issues, and guarantees a 0-latency connection as long as both devices are on the same Wi-Fi.
