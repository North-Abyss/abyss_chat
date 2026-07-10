/// Central hub for all "magic numbers" and constants across Abyss Chat.
class AppConstants {
  // --- NETWORK CONSTANTS ---
  static const int lanServerPort = 45885;
  static const String mDnsServiceType = '_abysschat._tcp';
  
  // --- WEBRTC CONSTANTS ---
  static const Duration webrtcReconnectDelay = Duration(seconds: 4);
  static const Duration webrtcSignalingTimeout = Duration(milliseconds: 1000);
  static const Duration callTimeout = Duration(seconds: 30);

  // --- UI & THEME CONSTANTS ---
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 16.0;
  static const double defaultIconSize = 24.0;
  
  // --- ANIMATION & TIMEOUT CONSTANTS ---
  static const Duration toastDuration = Duration(seconds: 4);
  static const Duration toastAnimationDuration = Duration(milliseconds: 400);
  static const Duration reactionDuration = Duration(seconds: 3);
  static const Duration gifPauseDelay = Duration(seconds: 10);
  
  // --- SYSTEM LIMITS ---
  static const int groupCallWarningThreshold = 10;
}
