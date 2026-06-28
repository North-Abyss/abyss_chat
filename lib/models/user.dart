class User {
  final String id;
  final String name;
  final int avatarIcon;
  final int avatarColor;
  final bool isOnline;
  final bool isWpsActive;
  final String? ipAddress;
  final int? port;
  final String? profileImagePath;

  User({
    required this.id,
    required this.name,
    required this.avatarIcon,
    required this.avatarColor,
    this.isOnline = false,
    this.isWpsActive = false,
    this.ipAddress,
    this.port,
    this.profileImagePath,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      avatarIcon: json['avatarIcon'] ?? 0xe491, // default icon
      avatarColor: json['avatarColor'] ?? 0xFF6750A4, // default color
      isOnline: json['isOnline'] ?? false,
      isWpsActive: json['isWpsActive'] ?? false,
      ipAddress: json['ipAddress'],
      port: json['port'],
      profileImagePath: json['profileImagePath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarIcon': avatarIcon,
      'avatarColor': avatarColor,
      'isOnline': isOnline,
      'isWpsActive': isWpsActive,
      'ipAddress': ipAddress,
      'port': port,
      'profileImagePath': profileImagePath,
    };
  }
}
