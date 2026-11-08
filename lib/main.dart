import 'package:flutter/material.dart';

import 'models/auth_user.dart';

import 'pages/admin_home_page.dart';
import 'pages/all_tour_operators_page.dart';
import 'pages/all_tourist_guides_page.dart';
import 'pages/complete_profile_page.dart';
import 'pages/login_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/register_page.dart';
import 'pages/tour_operator_home_page.dart';
import 'pages/operator_car_hire_bookings_page.dart';
import 'pages/tourist_car_hire_bookings_page.dart';
import 'pages/tourist_guide_home_page.dart';
import 'pages/tourist_home_page.dart';

import 'services/auth_service.dart';

import 'theme/app_design_system.dart';
import 'theme/field_guide_theme.dart';
import 'theme/app_appearance_controller.dart';

void main() {
  runApp(const TourismPortalApp());
}

class TourismPortalApp extends StatefulWidget {
  const TourismPortalApp({super.key});

  @override
  State<TourismPortalApp> createState() => _TourismPortalAppState();
}

class _TourismPortalAppState extends State<TourismPortalApp> {
  final AppAppearanceController appearance = AppAppearanceController.instance;

  @override
  void initState() {
    super.initState();
    // Public endpoint: guests receive the same published appearance.
    appearance.refresh();
  }

  // ============================================================
  // LIGHT THEME
  // ============================================================

  ThemeData _lightTheme() {
    final primary = appearance.primary;

    final secondary = appearance.secondary;

    final background = appearance.background;

    const darkText = FieldGuidePalette.ink;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,

      secondary: secondary,
      onSecondary: Colors.white,

      surface: FieldGuidePalette.surface,

      onSurface: darkText,

      outline: FieldGuidePalette.border,
    );

    final baseTheme = ThemeData(
      useMaterial3: true,

      brightness: Brightness.light,

      colorScheme: colorScheme,

      scaffoldBackgroundColor: background,

      // ========================================================
      // APP BAR
      // ========================================================
      appBarTheme: AppBarTheme(
        backgroundColor: background,

        foregroundColor: darkText,

        elevation: 0,

        centerTitle: false,

        surfaceTintColor: Colors.transparent,
      ),

      // ========================================================
      // INPUTS
      // ========================================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,

        fillColor: FieldGuidePalette.surface,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),

          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),

          borderSide: const BorderSide(color: FieldGuidePalette.border),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),

          borderSide: BorderSide(color: primary, width: 1.6),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),

          borderSide: const BorderSide(color: Color(0xFFE05252)),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),

          borderSide: const BorderSide(color: Color(0xFFE05252), width: 1.6),
        ),
      ),

      // ========================================================
      // FILLED BUTTONS
      // ========================================================
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,

          foregroundColor: Colors.white,

          minimumSize: const Size(0, 54),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.medium),
          ),
        ),
      ),

      // ========================================================
      // OUTLINED BUTTONS
      // ========================================================
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,

          minimumSize: const Size(0, 52),

          side: BorderSide(color: primary),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.medium),
          ),
        ),
      ),

      // ========================================================
      // TEXT BUTTONS
      // ========================================================
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),

      // ========================================================
      // NAVIGATION BAR
      // ========================================================
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: FieldGuidePalette.surface,

        indicatorColor: primary.withValues(alpha: .12),

        elevation: 0,

        height: 72,
      ),

      // ========================================================
      // SNACKBAR
      // ========================================================
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkText,

        contentTextStyle: const TextStyle(color: Colors.white),

        behavior: SnackBarBehavior.floating,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.small),
        ),
      ),

      dividerColor: FieldGuidePalette.border,
    );

    return baseTheme.copyWith(
      textTheme: FieldGuideType.textTheme(baseTheme.textTheme, color: darkText),

      primaryTextTheme: FieldGuideType.textTheme(
        baseTheme.primaryTextTheme,

        color: Colors.white,
      ),
    );
  }

  // ============================================================
  // DARK THEME
  // ============================================================

  ThemeData _darkTheme() {
    final primary = appearance.primary;

    final secondary = appearance.secondary;

    final background = appearance.mode == ThemeMode.dark ? FieldGuidePalette.night : FieldGuidePalette.night;

    const surface = FieldGuidePalette.nightSurface;

    const lightText = FieldGuidePalette.moon;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,

      brightness: Brightness.dark,
    ).copyWith(
      primary: primary,

      onPrimary: const Color(0xFF082D29),

      secondary: secondary,

      surface: surface,

      onSurface: lightText,

      outline: const Color(0xFF3A4655),
    );

    final baseTheme = ThemeData(
      useMaterial3: true,

      brightness: Brightness.dark,

      colorScheme: colorScheme,

      scaffoldBackgroundColor: background,

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF171D28),

        foregroundColor: lightText,

        elevation: 0,

        centerTitle: false,

        surfaceTintColor: Colors.transparent,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,

        fillColor: surface,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),

        hintStyle: const TextStyle(color: Color(0xFF8793A2)),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),

          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),

          borderSide: const BorderSide(color: Color(0xFF354150)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),

          borderSide: BorderSide(color: primary, width: 1.6),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),

          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),

          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.6),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,

          foregroundColor: const Color(0xFF082D29),

          minimumSize: const Size(0, 54),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.medium),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,

          minimumSize: const Size(0, 52),

          side: BorderSide(color: primary),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.medium),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF171D28),

        indicatorColor: Color(0xFF294D4C),

        elevation: 0,

        height: 72,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF283240),

        contentTextStyle: const TextStyle(color: lightText),

        behavior: SnackBarBehavior.floating,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.small),
        ),
      ),

      dividerColor: const Color(0xFF303B49),
    );

    return baseTheme.copyWith(
      textTheme: FieldGuideType.textTheme(
        baseTheme.textTheme,
        color: lightText,
      ),

      primaryTextTheme: FieldGuideType.textTheme(
        baseTheme.primaryTextTheme,

        color: const Color(0xFF082D29),
      ),
    );
  }

  ThemeData _applyFont(ThemeData theme) {
    final family = appearance.fontFamily;
    if (family == null || family.isEmpty) return theme;
    return theme.copyWith(
      textTheme: theme.textTheme.apply(fontFamily: family),
      primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: family),
    );
  }

  // ============================================================
  // APPLICATION
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appearance,
      builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Tourism Portal',

      theme: _applyFont(_lightTheme()),

      darkTheme: _applyFont(_darkTheme()),

      // Keep light theme for now.
      // Keep forms and dashboard readable until every dark-mode page is styled.
      themeMode: ThemeMode.light,

      // First page is handled through the session gate.
      home: const _LaunchGate(),

      // ========================================================
      // ROUTES
      // ========================================================
      routes: {
        // ------------------------------------------------------
        // AUTHENTICATION
        // ------------------------------------------------------
        '/login': (context) => const LoginPage(),

        '/register': (context) => const RegisterPage(),

        '/complete-profile': (context) => const CompleteProfilePage(),

        // ------------------------------------------------------
        // USER DASHBOARDS
        // ------------------------------------------------------
        '/admin-home': (context) => const AdminHomePage(),

        '/tourist-home': (context) => const TouristHomePage(),

        '/guide-home': (context) => const GuideHomePage(),

        '/operator-home': (context) => const TourOperatorHomePage(),

        '/operator-car-hire-bookings': (context) =>
            const OperatorCarHireBookingsPage(),

        '/tourist-car-hire-bookings': (context) =>
            const TouristCarHireBookingsPage(),

        // ------------------------------------------------------
        // ALL TOURIST GUIDES
        // ------------------------------------------------------
        '/guides': (context) => const AllTouristGuidesPage(),

        // ------------------------------------------------------
        // ALL TOUR OPERATORS
        // ------------------------------------------------------
        '/operators': (context) => const AllTourOperatorsPage(),
      },
      ),
    );
  }
}

// =================================================================
// LAUNCH / SESSION GATE
// =================================================================

class _LaunchGate extends StatefulWidget {
  const _LaunchGate();

  @override
  State<_LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<_LaunchGate> {
  late Future<AuthUser?> _session;

  @override
  void initState() {
    super.initState();

    _session = AuthService.instance.restoreSession();
  }

  void _refreshSession() {
    setState(() {
      _session = AuthService.instance.restoreSession();
    });
  }

  // ===============================================================
  // RESOLVE LOGGED-IN USER HOME
  // ===============================================================

  Widget _homeFor(AuthUser user) {
    if (user.role != 'admin' && !user.profileCompleted) {
      return const CompleteProfilePage();
    }

    switch (user.role) {
      case 'admin':
        return const AdminHomePage();

      case 'tourist':
        return const TouristHomePage();

      case 'tourist_guide':
        return const GuideHomePage();

      case 'tour_operator':
        return const TourOperatorHomePage();

      default:
        return const TouristHomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthUser?>(
      future: _session,

      builder: (context, snapshot) {
        // =========================================================
        // LOADING SESSION
        // =========================================================

        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
          );
        }

        final user = snapshot.data;

        // =========================================================
        // USER ALREADY LOGGED IN
        // =========================================================

        if (user != null) {
          return _homeFor(user);
        }

        // =========================================================
        // LOGGED OUT USER
        // =========================================================
        //
        // Onboarding is the FIRST public page.
        //

        return OnboardingPage(
          onFinished: () {
            _refreshSession();
          },
        );
      },
    );
  }
}
