import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/session_navigation.dart';
import '../widgets/current_user_avatar.dart';
import 'admin_advertisements_page.dart';
import 'admin_platform_settings_page.dart';
import 'admin_awards_hub_page.dart';
import 'admin_catalog_page.dart';
import 'admin_countries_page.dart';
import 'admin_onboarding_slides_page.dart';
import 'admin_provider_verification_page.dart';

const _primary = Color(0xFF165B5D);
const _dark = Color(0xFF103F42);
const _accent = Color(0xFFF46627);
const _background = Color(0xFFF4EEE1);
const _secondary = Color(0xFF718082);

/// Admin settings hub. It deliberately exposes only working destinations and
/// account actions. Editable platform settings require a persistent API.
class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final name = AuthService.instance.currentUser?.name ?? 'Administrator';
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Admin Settings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 36),
              children: [
                Container(
                  padding: const EdgeInsets.all(21),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_dark, _primary]),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(children: [
                    const CurrentUserAvatar(radius: 27, backgroundColor: Colors.white, foregroundColor: _primary),
                    const SizedBox(width: 15),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('ADMINISTRATOR ACCOUNT', style: TextStyle(color: Color(0xFFC5DFDC), fontSize: 10, letterSpacing: 1.3, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      const Text('Tourism Portal administration', style: TextStyle(color: Color(0xFFD5E5E3), fontSize: 12)),
                    ])),
                    const Icon(Icons.verified_user_outlined, color: Colors.white70),
                  ]),
                ),
                const SizedBox(height: 28),
                const _Heading('Platform configuration', 'Branding, access and provider policies'),
                const SizedBox(height: 11),
                _Group(children: [
                  _Entry(Icons.tune_rounded, 'Platform settings', 'General, appearance, users and providers', () => _open(context, const AdminPlatformSettingsPage())),
                ]),
                const SizedBox(height: 26),
                const _Heading('Content & discovery', 'Manage the content shown to travellers'),
                const SizedBox(height: 11),
                _Group(children: [
                  _Entry(Icons.public_rounded, 'Countries', 'Country information and images', () => _open(context, const AdminCountriesPage())),
                  _Entry(Icons.landscape_outlined, 'Tourism catalog', 'Destinations and activities', () => _open(context, const AdminCatalogPage())),
                  _Entry(Icons.view_carousel_outlined, 'First page slides', 'Onboarding content', () => _open(context, const AdminOnboardingSlidesPage())),
                ]),
                const SizedBox(height: 26),
                const _Heading('Operations', 'Moderation, campaigns and recognition'),
                const SizedBox(height: 11),
                _Group(children: [
                  _Entry(Icons.verified_user_outlined, 'Provider approvals', 'Review provider verification', () => _open(context, const AdminProviderVerificationPage())),
                  _Entry(Icons.campaign_outlined, 'Advertisements', 'Manage promotional placements', () => _open(context, const AdminAdvertisementsPage()), accent: true),
                  _Entry(Icons.workspace_premium_outlined, 'Guide awards', 'Awards and judging', () => _open(context, const AdminAwardsHubPage())),
                ]),
                const SizedBox(height: 26),
                const _Heading('Account & security', 'Access to your administrator session'),
                const SizedBox(height: 11),
                _Group(children: [
                  _Entry(Icons.logout_rounded, 'Sign out', 'End your current admin session', () => _confirmSignOut(context), accent: true),
                ]),
                const SizedBox(height: 23),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .72),
                    border: Border.all(color: _primary.withValues(alpha: .09)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.info_outline_rounded, color: _primary, size: 21),
                    SizedBox(width: 11),
                    Expanded(child: Text(
                      'Platform-wide preferences such as branding, user permissions, notifications and security policies will be added once their backend saving and permissions are available. No inactive switches are shown here.',
                      style: TextStyle(fontSize: 12, height: 1.5, color: _secondary),
                    )),
                  ]),
                ),
                const SizedBox(height: 24),
                const Center(child: Text('TOURISM PORTAL  •  ADMIN SETTINGS', style: TextStyle(color: _secondary, fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w700))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to access administration.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (shouldSignOut == true && context.mounted) {
      signOutAndShowLogin(context);
    }
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.title, this.subtitle);
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(color: _dark, fontSize: 19, fontWeight: FontWeight.w800)),
    const SizedBox(height: 4),
    Text(subtitle, style: const TextStyle(color: _secondary, fontSize: 12)),
  ]);
}

class _Entry {
  const _Entry(this.icon, this.title, this.subtitle, this.onTap, {this.accent = false});
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  final bool accent;
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<_Entry> children;
  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _primary.withValues(alpha: .09)),
    ),
    child: Column(children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const Divider(height: 1, indent: 68, endIndent: 16, color: Color(0xFFECEFEA)),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          leading: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: (children[i].accent ? _accent : _primary).withValues(alpha: .09), borderRadius: BorderRadius.circular(12)),
            child: Icon(children[i].icon, color: children[i].accent ? _accent : _primary, size: 21),
          ),
          title: Text(children[i].title, style: const TextStyle(color: _dark, fontSize: 14, fontWeight: FontWeight.w700)),
          subtitle: Text(children[i].subtitle, style: const TextStyle(color: _secondary, fontSize: 11)),
          trailing: const Icon(Icons.chevron_right_rounded, color: _secondary),
          onTap: children[i].onTap,
        ),
      ],
    ]),
  );
}
