import 'package:flutter_test/flutter_test.dart';
import 'package:tourism_portal_app/models/auth_user.dart';

void main() {
  test('API roles map to the correct dashboard routes', () {
    const routes = {
      'admin': '/admin-home',
      'tourist': '/tourist-home',
      'tourist_guide': '/guide-home',
      'tour_operator': '/operator-home',
    };

    for (final entry in routes.entries) {
      final user = AuthUser(
        id: 1,
        name: 'Test User',
        email: 'user@tourism.test',
        role: entry.key,
        profileCompleted: true,
      );

      expect(user.homeRoute, entry.value);
    }
  });

  test('incomplete public accounts are routed to profile completion', () {
    const user = AuthUser(
      id: 2,
      name: 'New Guide',
      email: 'guide@example.com',
      role: 'tourist_guide',
      profileCompleted: false,
    );

    expect(user.nextRoute, '/complete-profile');
  });
}
