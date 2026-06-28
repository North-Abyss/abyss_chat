enum MessageType { text, system, image, file, audio }
enum MessageStatus { pending, sending, sent, delivered, read, failed }

class Message {
  final String id;
  final String senderId;
  final String? senderName;
  final String text;
  final DateTime timestamp;
  final MessageStatus status;
  final MessageType type;
  final String? localFilePath;
  final String? fileName;
  final String? fileData;

  Message({
    required this.id,
    required this.senderId,
    this.senderName,
    required this.text,
    required this.timestamp,
    this.status = MessageStatus.sending,
    this.type = MessageType.text,
    this.localFilePath,
    this.fileName,
    this.fileData,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      text: json['text'],
      timestamp: DateTime.parse(json['timestamp']),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'sent'), // default to sent for old messages
        orElse: () => json['isRead'] == true ? MessageStatus.read : MessageStatus.sent,
      ),
      type: MessageType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      localFilePath: json['localFilePath'],
      fileName: json['fileName'],
      fileData: json['fileData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'type': type.name,
      'localFilePath': localFilePath,
      'fileName': fileName,
      'fileData': fileData,
    };
  }

  Message copyWith({
    MessageStatus? status,
    String? localFilePath,
  }) {
    return Message(
      id: id,
      senderId: senderId,
      senderName: senderName,
      text: text,
      timestamp: timestamp,
      status: status ?? this.status,
      type: type,
      localFilePath: localFilePath ?? this.localFilePath,
      fileName: fileName,
    );
  }
}
