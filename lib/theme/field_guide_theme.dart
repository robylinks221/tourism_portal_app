import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class FieldGuidePalette {
  // ============================================================
  // TOURISM PORTAL GLOBAL BRAND COLORS
  // ============================================================

  // Primary brand color
  static const primary = Color(0xFF165B5D);

  // Kept for compatibility with existing pages
  static const canopy = Color(0xFF165B5D);

  // Darker version of primary
  static const forest = Color(0xFF10494B);

  // Secondary brand color
  static const secondary = Color(0xFFF46627);

  // Kept for compatibility with existing pages
  static const clay = Color(0xFFF46627);

  // Main application background
  static const background = Color(0xFFF4EEE1);

  // Kept for compatibility with existing pages
  static const ivory = Color(0xFFF4EEE1);

  // Cards / form surfaces
  static const surface = Color(0xFFFFFCF8);

  // Supporting colors
  static const lake = Color(0xFF4C8396);
  static const mist = Color(0xFFDDE8E7);

  // Text colors
  static const ink = Color(0xFF172323);
  static const mutedText = Color(0xFF747D7C);

  // Borders
  static const border = Color(0xFFE1DAD0);

  // Dark-mode colors
  static const night = Color(0xFF0D1818);
  static const nightSurface = Color(0xFF142323);
  static const sage = Color(0xFF8CC9C9);
  static const moon = Color(0xFFF7F4EC);
}

abstract class FieldGuideType {
  static TextTheme textTheme(
      TextTheme base, {
        required Color color,
      }) {
    final inter = GoogleFonts.interTextTheme(base).apply(
      bodyColor: color,
      displayColor: color,
    );

    TextStyle? normalized(
        TextStyle? style, {
          required double size,
          FontWeight? weight,
          double height = 1.35,
          double letterSpacing = 0,
        }) {
      return style?.copyWith(
        fontSize: size,
        fontWeight: weight ?? style.fontWeight,
        height: height,
        letterSpacing: letterSpacing,
      );
    }

    return inter.copyWith(
      displayLarge: normalized(
        inter.displayLarge,
        size: 32,
        weight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.5,
      ),
      displayMedium: normalized(
        inter.displayMedium,
        size: 28,
        weight: FontWeight.w700,
        height: 1.18,
        letterSpacing: -0.35,
      ),
      displaySmall: normalized(
        inter.displaySmall,
        size: 26,
        weight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.25,
      ),
      headlineLarge: normalized(
        inter.headlineLarge,
        size: 26,
        weight: FontWeight.w700,
        height: 1.2,
      ),
      headlineMedium: normalized(
        inter.headlineMedium,
        size: 24,
        weight: FontWeight.w700,
        height: 1.22,
      ),
      headlineSmall: normalized(
        inter.headlineSmall,
        size: 22,
        weight: FontWeight.w700,
        height: 1.25,
      ),
      titleLarge: normalized(
        inter.titleLarge,
        size: 20,
        weight: FontWeight.w700,
        height: 1.3,
      ),
      titleMedium: normalized(
        inter.titleMedium,
        size: 18,
        weight: FontWeight.w700,
        height: 1.32,
      ),
      titleSmall: normalized(
        inter.titleSmall,
        size: 17,
        weight: FontWeight.w700,
        height: 1.35,
      ),
      bodyLarge: normalized(
        inter.bodyLarge,
        size: 14,
        height: 1.55,
        letterSpacing: 0.1,
      ),
      bodyMedium: normalized(
        inter.bodyMedium,
        size: 14,
        height: 1.5,
        letterSpacing: 0.1,
      ),
      bodySmall: normalized(
        inter.bodySmall,
        size: 14,
        height: 1.45,
        letterSpacing: 0.1,
      ),
      labelLarge: normalized(
        inter.labelLarge,
        size: 14,
        weight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.1,
      ),
      labelMedium: normalized(
        inter.labelMedium,
        size: 14,
        height: 1.4,
        letterSpacing: 0.1,
      ),
      labelSmall: normalized(
        inter.labelSmall,
        size: 12,
        height: 1.4,
        letterSpacing: 0.1,
      ),
    );
  }
}