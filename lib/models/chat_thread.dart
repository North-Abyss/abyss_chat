import 'package:abyss_chat/models/message.dart';
import 'package:abyss_chat/models/user.dart';

class ChatThread {
  final String id;
  final User peer;
  final List<Message> messages;

  final bool isGroup;
  final String? groupName;
  final List<User> members; // For groups, this contains all members. For 1:1, this might just be the peer.
  final int unreadCount;

  ChatThread({
    required this.id,
    required this.peer,
    required this.messages,
    this.isGroup = false,
    this.groupName,
    this.members = const [],
    this.unreadCount = 0,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: json['id'],
      peer: User.fromJson(json['peer']),
      messages: (json['messages'] as List)
          .map((msgJson) => Message.fromJson(msgJson))
          .toList(),
      isGroup: json['isGroup'] ?? false,
      groupName: json['groupName'],
      members: json['members'] != null
          ? (json['members'] as List).map((u) => User.fromJson(u)).toList()
          : [],
      unreadCount: json['unreadCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'peer': peer.toJson(),
      'messages': messages.map((m) => m.toJson()).toList(),
      'isGroup': isGroup,
      'groupName': groupName,
      'members': members.map((m) => m.toJson()).toList(),
      'unreadCount': unreadCount,
    };
  }
}
