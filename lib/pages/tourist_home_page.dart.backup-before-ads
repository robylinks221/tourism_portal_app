import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/account_management.dart';
import '../services/discovery_store.dart';
import '../services/session_navigation.dart';
import '../utils/text_case.dart';
import '../widgets/app_ui.dart';
import '../widgets/catalog_home_sections.dart';
import '../widgets/current_user_avatar.dart';
import '../widgets/country_discovery_section.dart';
import '../widgets/multi_country_safaris_section.dart';
import '../widgets/operator_offerings_sections.dart';
import '../widgets/provider_discovery_sections.dart';
import '../widgets/recommended_for_you_section.dart';

import 'awards_pages.dart';
import 'community_page.dart';
import 'discovery_page.dart';
import 'my_safari_requests_page.dart';
import 'safari_builder_page.dart';
import 'tourist_bookings_page.dart';
import 'tourist_bookings_hub_page.dart';

class TouristHomePage extends StatefulWidget {
  const TouristHomePage({super.key, this.isGuest = false});

  final bool isGuest;

  @override
  State<TouristHomePage> createState() => _TouristHomePageState();
}

class _TouristHomePageState extends State<TouristHomePage> {
  int _selectedNavigationIndex = 0;
  String _exploreQuery = '';

  @override
  void initState() {
    super.initState();

    DiscoveryStore.instance.ensureLoaded();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openSafariBuilder() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const SafariBuilderPage()),
    );
  }

  void _openMySafariRequests() {
    if (widget.isGuest) {
      _showGuestAccountSheet(
        context,
        title: 'Save and manage your safari',
        message:
            'Login or create an account to save safari plans, request quotes and compare operator proposals.',
      );

      return;
    }

    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const MySafariRequestsPage()),
    );
  }

  void _openAwards() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AwardsHomePage(isGuest: widget.isGuest),
      ),
    );
  }

  void _openMyBookings() {
    if (widget.isGuest) {
      _showGuestAccountSheet(
        context,
        title: 'View your safari bookings',
        message:
            'Login or create an account to view and manage your safari bookings.',
      );
      return;
    }

    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const TouristBookingsHubPage()),
    );
  }

  Widget _selectedPage() {
    if (_selectedNavigationIndex == 1) {
      return DiscoveryPage(
        key: ValueKey(_exploreQuery),
        isGuest: widget.isGuest,
        initialQuery: _exploreQuery,
      );
    }

    if (_selectedNavigationIndex == 2) {
      return const SavedDiscoveryPage();
    }

    if (_selectedNavigationIndex == 3) {
      return widget.isGuest ? const _GuestConnectPage() : const CommunityPage();
    }

    if (_selectedNavigationIndex == 4) {
      return _ProfilePage(
        isGuest: widget.isGuest,
        onCreateAccount: () {
          Navigator.pushNamed(context, '/register');
        },
        onLogin: () {
          Navigator.pushNamed(context, '/login');
        },
        onLogout: () {
          signOutAndShowLogin(context);
        },
        onEditAccount: () => openEditAccount(context),
        onDeleteAccount: () => confirmDeleteAccount(context),
        onMySafariRequests: _openMySafariRequests,
        onMyBookings: _openMyBookings,
      );
    }

    return _HomePage(
      isGuest: widget.isGuest,
      onSearch: (query) {
        setState(() {
          _exploreQuery = query.trim();

          _selectedNavigationIndex = 1;
        });
      },
      onNotificationPressed: () {
        _showMessage('You have no new notifications.');
      },
      onBuildSafari: _openSafariBuilder,
      onMySafariRequests: _openMySafariRequests,
      onAwardsPressed: _openAwards,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedPage(),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNavigationIndex,

        onDestinationSelected: (index) {
          setState(() {
            _selectedNavigationIndex = index;
          });
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum_rounded),
            label: 'Connect',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// GUEST CONNECT PAGE
// ==================================================================

class _GuestConnectPage extends StatelessWidget {
  const _GuestConnectPage();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.forum_outlined, size: 64),

              const SizedBox(height: 16),

              Text(
                'Sign In to Chat and Leave Ratings',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 10),

              const Text(
                'Create a tourist account or sign in to connect privately with tour guides and tour operators.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              FilledButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// HOME PAGE
// ==================================================================

class _HomePage extends StatelessWidget {
  const _HomePage({
    required this.isGuest,
    required this.onSearch,
    required this.onNotificationPressed,
    required this.onBuildSafari,
    required this.onMySafariRequests,
    required this.onAwardsPressed,
  });

  final bool isGuest;

  final ValueChanged<String> onSearch;

  final VoidCallback onNotificationPressed;

  final VoidCallback onBuildSafari;

  final VoidCallback onMySafariRequests;

  final VoidCallback onAwardsPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final isDark = theme.brightness == Brightness.dark;

    final mutedText = colors.onSurface.withOpacity(0.62);

    final borderColor = colors.outline.withOpacity(isDark ? 0.62 : 0.72);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======================================================
            // HEADER
            // ======================================================
            Row(
              children: [
                CurrentUserAvatar(
                  radius: 24,
                  backgroundColor: colors.primary.withOpacity(
                    isDark ? 0.18 : 0.13,
                  ),
                  foregroundColor: colors.primary,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${AuthService.instance.currentUser?.name ?? 'Traveller'}!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color: colors.secondary,
                            size: 15,
                          ),

                          const SizedBox(width: 3),

                          Text(
                            'Kampala, Uganda',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: mutedText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed: onNotificationPressed,
                  style: IconButton.styleFrom(
                    backgroundColor: colors.surface,
                    foregroundColor: colors.onSurface,
                    side: BorderSide(color: borderColor),
                  ),
                  icon: const Badge(
                    smallSize: 8,
                    child: Icon(Icons.notifications_outlined),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            Text(
              'Where do you want\nto explore?',
              style: theme.textTheme.headlineMedium?.copyWith(
                height: 1.16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
              ),
            ),

            const SizedBox(height: 20),

            // ======================================================
            // SEARCH
            // ======================================================
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.16 : 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: TextField(
                textInputAction: TextInputAction.search,
                onSubmitted: onSearch,
                decoration: InputDecoration(
                  hintText: 'Search destinations',
                  prefixIcon: Icon(Icons.search_rounded, color: colors.primary),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(6),
                    child: IconButton(
                      onPressed: () => onSearch(''),
                      style: IconButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ======================================================
            // CUSTOM SAFARI BUILDER
            // ======================================================
            const SafariBuilderBanner(),

            const SizedBox(height: 24),

            _AwardsAccessCard(onPressed: onAwardsPressed),

            const SizedBox(height: 30),

            CountryDiscoverySection(isGuest: isGuest),
            const SizedBox(height: 30),

            MultiCountrySafarisSection(isGuest: isGuest),
            const SizedBox(height: 30),

            const CatalogHomeSections(),
            const SizedBox(height: 30),

            RecommendedForYouSection(isGuest: isGuest),

            const SizedBox(height: 30),

            ProviderDiscoverySections(enabled: true, isGuest: isGuest),

            const SizedBox(height: 30),

            const OperatorOfferingsSections(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _AwardsAccessCard extends StatelessWidget {
  const _AwardsAccessCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.primary.withValues(alpha: .18)),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: colors.secondary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tourist Guide Awards',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Discover finalists, categories and award winners.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: .62),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// PROFILE PAGE
// ==================================================================

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({
    required this.isGuest,
    required this.onCreateAccount,
    required this.onLogin,
    required this.onLogout,
    required this.onEditAccount,
    required this.onDeleteAccount,
    required this.onMySafariRequests,
    required this.onMyBookings,
  });

  final bool isGuest;
  final VoidCallback onCreateAccount;
  final VoidCallback onLogin;
  final VoidCallback onLogout;
  final VoidCallback onEditAccount;
  final VoidCallback onDeleteAccount;
  final VoidCallback onMySafariRequests;
  final VoidCallback onMyBookings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final isDark = theme.brightness == Brightness.dark;

    final mutedText = colors.onSurface.withOpacity(0.62);

    final borderColor = colors.outline.withOpacity(isDark ? 0.62 : 0.72);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        child: Column(
          children: [
            if (isGuest)
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(isDark ? 0.18 : 0.13),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: colors.primary,
                  size: 48,
                ),
              )
            else
              CurrentUserAvatar(
                radius: 46,
                backgroundColor: colors.primary.withOpacity(
                  isDark ? 0.18 : 0.13,
                ),
                foregroundColor: colors.primary,
              ),

            const SizedBox(height: 14),

            Text(
              isGuest
                  ? 'Guest Traveller'
                  : AuthService.instance.currentUser?.name ?? 'Tourist Account',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              isGuest
                  ? 'Sign in to save places and manage bookings.'
                  : AuthService.instance.currentUser?.email ??
                      'Explore more. Experience more.',
              style: theme.textTheme.bodySmall?.copyWith(color: mutedText),
            ),

            const SizedBox(height: 28),

            if (!isGuest)
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _ProfileTile(
                      icon: Icons.edit_outlined,
                      title: 'Edit Account',
                      onTap: onEditAccount,
                    ),

                    Divider(height: 1, color: theme.dividerColor),

                    _ProfileTile(
                      icon: Icons.travel_explore_outlined,
                      title: 'My Safari Requests',
                      onTap: onMySafariRequests,
                    ),

                    Divider(height: 1, color: theme.dividerColor),

                    _ProfileTile(
                      icon: Icons.receipt_long_outlined,
                      title: 'My Bookings',
                      onTap: onMyBookings,
                    ),

                    Divider(height: 1, color: theme.dividerColor),
                    Divider(height: 1, color: theme.dividerColor),

                    _ProfileTile(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      onTap: () {},
                    ),

                    Divider(height: 1, color: theme.dividerColor),

                    _ProfileTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Help and support',
                      onTap: () {},
                    ),

                    Divider(height: 1, color: theme.dividerColor),

                    _ProfileTile(
                      icon: Icons.delete_forever_outlined,
                      title: 'Delete Account',
                      onTap: onDeleteAccount,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 22),

            if (isGuest) ...[
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: onCreateAccount,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text(
                    'Create Account',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: onLogin,
                  icon: const Icon(Icons.login_rounded),
                  label: const Text(
                    'Sign In',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// PROFILE TILE
// ==================================================================

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: colors.primary, size: 21),
      ),
      title: Text(
        title.toTitleCase(),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: colors.onSurface.withOpacity(0.42),
        size: 16,
      ),
    );
  }
}

// ==================================================================
// SIMPLE ACCOUNT-GATE SHEET
// ==================================================================

Future<void> _showGuestAccountSheet(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(.50),
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);

      final colors = theme.colorScheme;

      return SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outline.withOpacity(.30),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),

              const SizedBox(height: 22),

              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_open_rounded,
                  color: colors.primary,
                  size: 27,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withOpacity(.62),
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(sheetContext);

                    Navigator.pushNamed(context, '/login');
                  },
                  child: const Text(
                    'Login',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(sheetContext);

                    Navigator.pushNamed(context, '/register');
                  },
                  child: const Text(
                    'Create Account',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
