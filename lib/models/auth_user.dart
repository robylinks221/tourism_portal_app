class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.profileCompleted,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final bool profileCompleted;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      profileCompleted: json['profile_completed'] == true ||
          json['profile_completed'] == 1,
    );
  }

  String get homeRoute {
    switch (role) {
      case 'admin':
        return '/admin-home';
      case 'tourist':
        return '/tourist-home';
      case 'tourist_guide':
        return '/guide-home';
      case 'tour_operator':
        return '/operator-home';
      default:
        throw StateError('Unsupported account role: $role');
    }
  }

  String get nextRoute {
    if (role != 'admin' && !profileCompleted) {
      return '/complete-profile';
    }

    return homeRoute;
  }
}
