import 'package:flutter/material.dart';

import 'auth_service.dart';

Future<void> signOutAndShowLogin(BuildContext context) async {
  await AuthService.instance.logout();

  if (!context.mounted) {
    return;
  }

  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
}
