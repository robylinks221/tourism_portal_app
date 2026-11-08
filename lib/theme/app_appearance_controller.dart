import 'package:flutter/material.dart';
import '../services/admin_customization_service.dart';

/// Public appearance settings. Works for guests and authenticated users.
class AppAppearanceController extends ChangeNotifier {
  AppAppearanceController._();
  static final instance = AppAppearanceController._();

  Color primary = const Color(0xFF165B5D);
  Color secondary = const Color(0xFFF46627);
  Color background = const Color(0xFFF4EEE1);
  String font = 'Nexa';
  ThemeMode mode = ThemeMode.system;

  String? get fontFamily => font == 'Nexa' ? null : font;

  Color _color(dynamic raw, Color fallback) {
    final text = raw?.toString().replaceFirst('#', '');
    if (text == null || !RegExp(r'^[a-fA-F0-9]{6}$').hasMatch(text)) return fallback;
    return Color(int.parse('FF$text', radix: 16));
  }

  /// Immediately publish the successful server response to every listening widget.
  void apply(Map<String, dynamic> response) {
    final data = response['appearance'] is Map
        ? Map<String, dynamic>.from(response['appearance'] as Map)
        : response['data'] is Map
            ? Map<String, dynamic>.from(response['data'] as Map)
            : response;
    primary = _color(data['primary_color'], const Color(0xFF165B5D));
    secondary = _color(data['secondary_color'], const Color(0xFFF46627));
    background = _color(data['background_color'], const Color(0xFFF4EEE1));
    font = data['font_family']?.toString() ?? 'Nexa';
    switch (data['display_mode']?.toString().toLowerCase()) {
      case 'dark': mode = ThemeMode.dark; break;
      case 'light': mode = ThemeMode.light; break;
      default: mode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      final response = await AdminCustomizationService.instance.appearance();
      apply(response);
    } catch (_) {
      // Retain last known appearance (or app defaults) when offline.
    }
  }
}
