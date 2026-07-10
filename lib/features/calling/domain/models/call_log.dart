import 'package:abyss_chat/features/contacts/domain/models/user.dart';

class CallLog {
  final String id;
  final User peer;
  final bool isVideo;
  final DateTime timestamp;
  final Duration? duration;
  final bool isOutgoing;
  final bool isMissed;

  CallLog({
    required this.id,
    required this.peer,
    required this.isVideo,
    required this.timestamp,
    this.duration,
    required this.isOutgoing,
    required this.isMissed,
  });

  factory CallLog.fromJson(Map<String, dynamic> json) {
    return CallLog(
      id: json['id'],
      peer: User.fromJson(json['peer']),
      isVideo: json['isVideo'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      duration: json['durationMs'] != null ? Duration(milliseconds: json['durationMs']) : null,
      isOutgoing: json['isOutgoing'] ?? false,
      isMissed: json['isMissed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'peer': peer.toJson(),
      'isVideo': isVideo,
      'timestamp': timestamp.toIso8601String(),
      'durationMs': duration?.inMilliseconds,
      'isOutgoing': isOutgoing,
      'isMissed': isMissed,
    };
  }
}
