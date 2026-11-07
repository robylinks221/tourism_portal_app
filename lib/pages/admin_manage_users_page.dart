import 'package:flutter/material.dart';

import '../models/auth_user.dart';
import '../services/auth_service.dart';

const _primary = Color(0xFF165B5D);
const _background = Color(0xFFF4EEE1);
const _orange = Color(0xFFF46627);

/// Step 1: uses only the documented /user and /profile endpoints.
/// The API specification does not expose an admin-wide user listing.
class AdminManageUsersPage extends StatefulWidget {
  const AdminManageUsersPage({super.key});

  @override
  State<AdminManageUsersPage> createState() => _AdminManageUsersPageState();
}

class _AdminManageUsersPageState extends State<AdminManageUsersPage> {
  AuthUser? _user;
  Map<String, dynamic>? _profile;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await AuthService.instance.restoreSession();
      if (user == null) {
        throw StateError('Your session has expired. Please sign in again.');
      }
      if (user.role != 'admin') {
        throw StateError('This page is available to administrators only.');
      }
      Map<String, dynamic>? profile;
      try {
        profile = await AuthService.instance.fetchProfile();
      } catch (_) {
        // An administrator may not have a separate provider profile.
      }
      if (!mounted) return;
      setState(() {
        _user = user;
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Bad state: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: _orange, size: 40),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      const Text(
                        'Account administration',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: _primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Connected to the existing Tourism Portal API.',
                        style: TextStyle(color: Color(0xFF718082)),
                      ),
                      const SizedBox(height: 18),
                      Card(
                        color: Colors.white,
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Signed-in administrator',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: _primary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _field('Name', _user?.name ?? ''),
                              _field('Email', _user?.email ?? ''),
                              _field('Role', _user?.role ?? ''),
                              _field('User ID', '${_user?.id ?? ''}'),
                              if (_profile != null) ...[
                                const Divider(height: 24),
                                const Text(
                                  'Available profile details',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                for (final key in ['full_name', 'phone', 'country'])
                                  if ((_profile![key]?.toString() ?? '').isNotEmpty)
                                    _field(key.replaceAll('_', ' '), '${_profile![key]}'),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _primary.withValues(alpha: .12)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: _orange),
                                SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    'All-user management',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: _primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 9),
                            Text(
                              'The current API documentation provides authenticated user '
                              'and profile endpoints, but no administrator endpoint for '
                              'listing, searching, editing or suspending all registered '
                              'accounts. Those actions are intentionally unavailable '
                              'until a supported endpoint exists.',
                              style: TextStyle(height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _field(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(color: Color(0xFF718082))),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
