import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class AppRadii {
  static const small = 12.0;
  static const medium = 18.0;
  static const large = 24.0;
  static const hero = 30.0;
  static const pill = 999.0;
}

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 360);
}

abstract final class AppElevation {
  static List<BoxShadow> soft(BuildContext context, {double strength = 1}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withOpacity((dark ? .18 : .06) * strength),
        blurRadius: 20 * strength,
        offset: Offset(0, 8 * strength),
      ),
    ];
  }

  static List<BoxShadow> raised(BuildContext context) => [
    BoxShadow(
      color: Colors.black.withOpacity(
        Theme.of(context).brightness == Brightness.dark ? .26 : .10,
      ),
      blurRadius: 26,
      offset: const Offset(0, 10),
    ),
  ];
}

abstract final class AppBreakpoints {
  static const compact = 360.0;
  static const expanded = 720.0;
}
