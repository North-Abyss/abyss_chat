import 'dart:io';
import 'package:flutter/material.dart';
import 'package:abyss_chat/features/contacts/domain/models/user.dart';

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
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            color: Color(user.avatarColor),
            borderRadius: BorderRadius.circular(radius * 0.5),
            image: imageProvider != null
                ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                : null,
          ),
          child: imageProvider == null
              ? Icon(
                  _getIconData(user.avatarIcon),
                  color: Colors.white,
                  size: radius * 1.2,
                )
              : null,
        ),
        if (user.isOnline)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: radius * 0.7,
              height: radius * 0.7,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(radius * 0.25),
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

