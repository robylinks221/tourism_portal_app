import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/session_navigation.dart';
import '../widgets/current_user_avatar.dart';
import 'admin_catalog_page.dart';
import 'admin_onboarding_slides_page.dart';
import 'admin_provider_verification_page.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be added soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const darkGreen = Color(0xFF12372A);
    const primaryGreen = Color(0xFF2E7D32);
    const backgroundColor = Color(0xFFF6F8F5);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Icon(Icons.landscape_rounded),
            SizedBox(width: 10),
            Text(
              'Tourism Portal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showComingSoon(context, 'Notifications');
            },
            icon: const Badge(
              smallSize: 8,
              child: Icon(Icons.notifications_outlined),
            ),
          ),
          IconButton(
            onPressed: () {
              _showComingSoon(context, 'Admin profile');
            },
            icon: const CurrentUserAvatar(
              radius: 17,
              backgroundColor: Colors.white,
              foregroundColor: primaryGreen,
            ),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => signOutAndShowLogin(context),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      darkGreen,
                      primaryGreen,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x332E7D32),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const CurrentUserAvatar(
                      radius: 31,
                      backgroundColor: Colors.white,
                      foregroundColor: primaryGreen,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome back',
                            style: TextStyle(
                              color: Color(0xFFC8E6C9),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AuthService.instance.currentUser?.name ??
                                'Administrator',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Manage the Tourism Portal.',
                            style: TextStyle(
                              color: Color(0xFFE8F5E9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'System Overview',
                style: TextStyle(
                  color: darkGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Expanded(
                    child: _AdminStatCard(
                      icon: Icons.people_outline_rounded,
                      value: '0',
                      label: 'Users',
                      color: primaryGreen,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _AdminStatCard(
                      icon: Icons.calendar_month_outlined,
                      value: '0',
                      label: 'Bookings',
                      color: Color(0xFF0277BD),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(
                    child: _AdminStatCard(
                      icon: Icons.tour_outlined,
                      value: '0',
                      label: 'Tour Packages',
                      color: Color(0xFF7B1FA2),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _AdminStatCard(
                      icon: Icons.pending_actions_outlined,
                      value: '0',
                      label: 'Pending',
                      color: Color(0xFFF57F17),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'User Roles',
                style: TextStyle(
                  color: darkGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE1E8E2),
                  ),
                ),
                child: const Column(
                  children: [
                    _UserRoleRow(
                      icon: Icons.travel_explore_rounded,
                      title: 'Tourists',
                      value: '0',
                      color: primaryGreen,
                    ),
                    Divider(height: 26),
                    _UserRoleRow(
                      icon: Icons.hiking_rounded,
                      title: 'Tourist Guides',
                      value: '0',
                      color: Color(0xFF7B1FA2),
                    ),
                    Divider(height: 26),
                    _UserRoleRow(
                      icon: Icons.business_rounded,
                      title: 'Tour Operators',
                      value: '0',
                      color: Color(0xFF0277BD),
                    ),
                    Divider(height: 26),
                    _UserRoleRow(
                      icon: Icons.admin_panel_settings_rounded,
                      title: 'Administrators',
                      value: '1',
                      color: Color(0xFFC62828),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  color: darkGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: [
                  _AdminActionCard(
                    icon: Icons.manage_accounts_outlined,
                    title: 'Manage Users',
                    subtitle: 'View all accounts',
                    color: primaryGreen,
                    onTap: () {
                      _showComingSoon(context, 'Manage Users');
                    },
                  ),
                  _AdminActionCard(
                    icon: Icons.verified_user_outlined,
                    title: 'Approvals',
                    subtitle: 'Review accounts',
                    color: const Color(0xFFF57F17),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminProviderVerificationPage(),
                        ),
                      );
                    },
                  ),
                  _AdminActionCard(
                    icon: Icons.landscape_outlined,
                    title: 'Tourism Catalog',
                    subtitle: 'Activities & destinations',
                    color: const Color(0xFF7B1FA2),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminCatalogPage(),
                        ),
                      );
                    },
                  ),
                  _AdminActionCard(
                    icon: Icons.view_carousel_outlined,
                    title: 'First Page Slides',
                    subtitle: 'Manage onboarding',
                    color: const Color(0xFF0277BD),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminOnboardingSlidesPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'Provider verification',
                style: TextStyle(
                  color: darkGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 28,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE1E8E2),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.fact_check_outlined,
                      size: 46,
                      color: Color(0xFF9EAAA1),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Review guide and operator profiles',
                      style: TextStyle(
                        color: darkGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Verification badges only appear after a recorded administrative review.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF778078),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminProviderVerificationPage(),
                        ),
                      ),
                      icon: const Icon(Icons.verified_user_outlined),
                      label: const Text('Open verification queue'),
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminProviderVerificationPage(),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryGreen,
                        side: const BorderSide(
                          color: primaryGreen,
                        ),
                      ),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('View Applications'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        indicatorColor: const Color(0xFFC8E6C9),
        onDestinationSelected: (index) {
          if (index != 0) {
            const features = [
              'Dashboard',
              'Users',
              'Approvals',
              'Settings',
            ];

            _showComingSoon(context, features[index]);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_user_outlined),
            selectedIcon: Icon(Icons.verified_user_rounded),
            label: 'Approvals',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  const _AdminStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5EBE6),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF12372A),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF778078),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserRoleRow extends StatelessWidget {
  const _UserRoleRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 23,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF12372A),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE5EBE6),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 30,
              ),
              const SizedBox(height: 9),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF12372A),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF778078),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
