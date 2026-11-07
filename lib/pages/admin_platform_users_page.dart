import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/auth_service.dart';

const _primary = Color(0xFF165B5D);
const _accent = Color(0xFFF46627);
const _background = Color(0xFFF4EEE1);

class AdminPlatformUsersPage extends StatefulWidget {
  const AdminPlatformUsersPage({super.key});

  @override
  State<AdminPlatformUsersPage> createState() => _AdminPlatformUsersPageState();
}

class _AdminPlatformUsersPageState extends State<AdminPlatformUsersPage> {
  List<Map<String, dynamic>> _users = [];
  int _page = 1;
  int _lastPage = 1;
  int _total = 0;
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load(1);
  }

  Future<void> _load(int page) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = AuthService.instance;
      if (auth.currentUser?.role != 'admin') {
        throw Exception('Administrator access is required.');
      }
      final base = await auth.resolveBaseUrl();
      final token = await auth.requireToken();
      final uri = Uri.parse('$base/admin/platform-users').replace(
        queryParameters: {'page': '$page'},
      );
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 25));

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw Exception('The API returned an unreadable response.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded is Map
            ? (decoded['message'] ?? 'Unable to load users').toString()
            : 'Unable to load users';
        throw Exception('$message (HTTP ${response.statusCode})');
      }
      if (decoded is! Map || decoded['data'] is! List) {
        throw Exception('The API returned an unexpected users format.');
      }
      final rows = (decoded['data'] as List)
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      if (!mounted) return;
      setState(() {
        _users = rows;
        _page = (decoded['current_page'] as num?)?.toInt() ?? page;
        _lastPage = (decoded['last_page'] as num?)?.toInt() ?? 1;
        _total = (decoded['total'] as num?)?.toInt() ?? rows.length;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _users.where((user) {
      final text = [
        user['name'],
        user['email'],
        user['role'],
      ].join(' ').toLowerCase();
      return text.contains(_search.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh users',
            onPressed: _loading ? null : () => _load(_page),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _primary))
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, color: _accent, size: 42),
                            const SizedBox(height: 12),
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 14),
                            FilledButton(
                              onPressed: () => _load(_page),
                              child: const Text('Try again'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _load(_page),
                      child: ListView(
                        padding: const EdgeInsets.all(18),
                        children: [
                          Text(
                            'Registered users ($_total)',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Browse accounts using the existing admin API.',
                            style: TextStyle(color: Color(0xFF718082)),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            onChanged: (value) => setState(() => _search = value),
                            decoration: InputDecoration(
                              hintText: 'Search this page by name, email or role',
                              prefixIcon: const Icon(Icons.search_rounded),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (filtered.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(child: Text('No matching users on this page.')),
                            ),
                          for (final user in filtered)
                            Card(
                              color: Colors.white,
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 9),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _primary.withValues(alpha: .1),
                                  child: const Icon(Icons.person_outline, color: _primary),
                                ),
                                title: Text(
                                  (user['name'] ?? 'Unnamed user').toString(),
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                subtitle: Text(
                                  '${user['email'] ?? ''}\n${user['role'] ?? ''}',
                                ),
                                isThreeLine: true,
                              ),
                            ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                tooltip: 'Previous page',
                                onPressed: _page > 1 ? () => _load(_page - 1) : null,
                                icon: const Icon(Icons.chevron_left),
                              ),
                              Text('Page $_page of $_lastPage'),
                              IconButton(
                                tooltip: 'Next page',
                                onPressed: _page < _lastPage ? () => _load(_page + 1) : null,
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Account editing, role changes and suspension are not enabled because those actions require verified API endpoints.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Color(0xFF718082)),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}
