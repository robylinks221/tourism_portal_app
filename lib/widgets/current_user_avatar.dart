import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class CurrentUserAvatar extends StatelessWidget {
  const CurrentUserAvatar({
    super.key,
    required this.radius,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
    this.borderWidth = 0,
  });

  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final userName = AuthService.instance.currentUser?.name.trim() ?? '';
    final initial =
        userName.isEmpty
            ? 'U'
            : String.fromCharCode(userName.runes.first).toUpperCase();
    final diameter = radius * 2;

    Widget fallback() {
      return ColoredBox(
        color: backgroundColor,
        child: Center(
          child: Text(
            initial,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Semantics(
      image: true,
      label:
          userName.isEmpty
              ? 'User profile picture'
              : '$userName profile picture',
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border:
              borderColor == null || borderWidth <= 0
                  ? null
                  : Border.all(color: borderColor!, width: borderWidth),
        ),
        clipBehavior: Clip.antiAlias,
        child: FutureBuilder<String>(
          future: AuthService.instance.currentUserProfilePhotoUrl(),
          builder: (context, snapshot) {
            final imageUrl = snapshot.data?.trim() ?? '';
            if (imageUrl.isEmpty) return fallback();

            return Image.network(
              imageUrl,
              width: diameter,
              height: diameter,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              loadingBuilder: (context, child, progress) {
                return progress == null ? child : fallback();
              },
              errorBuilder: (context, error, stackTrace) => fallback(),
            );
          },
        ),
      ),
    );
  }
}
