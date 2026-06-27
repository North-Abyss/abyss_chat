import 'package:flutter/material.dart';
import 'package:abyss_chat/models/user.dart';

class UserAvatar extends StatelessWidget {
  final User user;
  final double radius;

  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 20,
  });

  IconData _getIconData(int codePoint) {
    const icons = [
      Icons.person, Icons.face, Icons.pets, Icons.rocket_launch, 
      Icons.star, Icons.local_florist, Icons.sports_esports, Icons.music_note
    ];
    return icons.firstWhere((icon) => icon.codePoint == codePoint, orElse: () => Icons.person);
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Color(user.avatarColor),
      child: Icon(
        _getIconData(user.avatarIcon),
        color: Colors.white,
        size: radius * 1.2,
      ),
    );
  }
}
