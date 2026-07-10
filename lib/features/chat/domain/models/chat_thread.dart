import 'package:abyss_chat/features/chat/domain/models/message.dart';
import 'package:abyss_chat/features/contacts/domain/models/user.dart';

class ChatThread {
  final String id;
  final User peer;
  final List<Message> messages;

  final bool isGroup;
  final String? groupName;
  final String? groupImagePath;
  final List<User> members; // For groups, this contains all members. For 1:1, this might just be the peer.
  final int unreadCount;

  ChatThread({
    required this.id,
    required this.peer,
    required this.messages,
    this.isGroup = false,
    this.groupName,
    this.groupImagePath,
    this.members = const [],
    this.unreadCount = 0,
  });

  ChatThread copyWith({
    String? id,
    User? peer,
    List<Message>? messages,
    bool? isGroup,
    String? groupName,
    String? groupImagePath,
    List<User>? members,
    int? unreadCount,
  }) {
    return ChatThread(
      id: id ?? this.id,
      peer: peer ?? this.peer,
      messages: messages ?? this.messages,
      isGroup: isGroup ?? this.isGroup,
      groupName: groupName ?? this.groupName,
      groupImagePath: groupImagePath ?? this.groupImagePath,
      members: members ?? this.members,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: json['id'],
      peer: User.fromJson(json['peer']),
      messages: (json['messages'] as List)
          .map((msgJson) => Message.fromJson(msgJson))
          .toList(),
      isGroup: json['isGroup'] ?? false,
      groupName: json['groupName'],
      groupImagePath: json['groupImagePath'],
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
      'groupImagePath': groupImagePath,
      'members': members.map((m) => m.toJson()).toList(),
      'unreadCount': unreadCount,
    };
  }
}
