import 'package:flutter/material.dart';

import '../services/admin_customization_service.dart';
import '../services/auth_service.dart';

/// The existing avatar used by the admin welcome card and other screens.
/// Administrators use /admin/profile, rather than the provider /profile API.
class CurrentUserAvatar extends StatefulWidget {
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
  State<CurrentUserAvatar> createState() => _CurrentUserAvatarState();
}

class _CurrentUserAvatarState extends State<CurrentUserAvatar> {
  Future<String>? _photoFuture;
  bool? _wasCurrentRoute;
  int _photoRevision = 0;

  @override
  void initState() {
    super.initState();
    _reloadPhoto();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ModalRoute.of subscribes this widget to changes in the route's
    // isCurrent state. Refresh when returning from an edit-profile screen.
    final current = ModalRoute.of(context)?.isCurrent ?? true;
    if (current && _wasCurrentRoute == false) {
      _reloadPhoto();
    }
    _wasCurrentRoute = current;
  }

  void _reloadPhoto() {
    _photoRevision++;
    _photoFuture = _resolvePhotoUrl(_photoRevision);
  }

  Future<String> _resolvePhotoUrl(int revision) async {
    final auth = AuthService.instance;
    final user = auth.currentUser;
    if (user == null) return '';

    String photoUrl = '';
    if (user.role == 'admin') {
      try {
        final response = await AdminCustomizationService.instance.profile();
        final rawProfile = response['profile'];
        if (rawProfile is Map) {
          final photo = rawProfile['photo_url']?.toString().trim() ?? '';
          if (photo.isNotEmpty && photo.toLowerCase() != 'null') {
            photoUrl = AuthService.storageUrl(photo);
          }
        }
      } catch (_) {
        // Keep the initial visible when the administrator profile is offline.
      }
    } else {
      try {
        photoUrl = await auth.currentUserProfilePhotoUrl();
      } catch (_) {
        // Use the existing initial fallback.
      }
    }

    if (photoUrl.isEmpty) return '';
    // Avoid displaying a cached image after a new administrator photo upload.
    if (user.role == 'admin') {
      final uri = Uri.tryParse(photoUrl);
      if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
        return uri.replace(queryParameters: {
          ...uri.queryParameters,
          'admin_avatar_revision': '$revision',
        }).toString();
      }
    }
    return photoUrl;
  }

  @override
  Widget build(BuildContext context) {
    final userName = AuthService.instance.currentUser?.name.trim() ?? '';
    final initial = userName.isEmpty
        ? 'U'
        : String.fromCharCode(userName.runes.first).toUpperCase();
    final diameter = widget.radius * 2;

    Widget fallback() {
      return ColoredBox(
        color: widget.backgroundColor,
        child: Center(
          child: Text(
            initial,
            style: TextStyle(
              color: widget.foregroundColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Semantics(
      image: true,
      label: userName.isEmpty
          ? 'User profile picture'
          : '$userName profile picture',
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          shape: BoxShape.circle,
          border: widget.borderColor == null || widget.borderWidth <= 0
              ? null
              : Border.all(
                  color: widget.borderColor!,
                  width: widget.borderWidth,
                ),
        ),
        clipBehavior: Clip.antiAlias,
        child: FutureBuilder<String>(
          future: _photoFuture,
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
