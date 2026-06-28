import 'dart:io';
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
    ImageProvider? imageProvider;
    if (user.profileImagePath != null) {
      final file = File(user.profileImagePath!);
      if (file.existsSync()) {
        imageProvider = FileImage(file);
      }
    }

    return Stack(
      children: [
        Hero(
          tag: 'avatar_${user.id}',
          child: CircleAvatar(
            radius: radius,
            backgroundColor: Color(user.avatarColor),
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Icon(
                    _getIconData(user.avatarIcon),
                    color: Colors.white,
                    size: radius * 1.2,
                  )
                : null,
          ),
        ),
        if (user.isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.6,
              height: radius * 0.6,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

