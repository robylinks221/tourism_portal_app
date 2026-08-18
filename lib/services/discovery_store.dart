import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/discovery_item.dart';
import 'auth_service.dart';

class DiscoveryStore extends ChangeNotifier {
  DiscoveryStore._();

  static final instance = DiscoveryStore._();
  static const _storage = FlutterSecureStorage();
  static const _savedPrefix = 'tourism.saved.discovery';
  static const _recentPrefix = 'tourism.recent.discovery';

  final Map<String, DiscoveryRecord> _saved = {};
  final List<DiscoveryRecord> _recent = [];
  Future<void>? _loading;
  int? _ownerId;

  List<DiscoveryRecord> get saved => List.unmodifiable(_saved.values);
  List<DiscoveryRecord> get recent => List.unmodifiable(_recent);
  bool get isLoaded => _ownerId != null;

  int get _currentOwner => AuthService.instance.currentUser?.id ?? 0;
  String _key(String prefix, int owner) => '$prefix.$owner';

  Future<void> ensureLoaded() {
    final owner = _currentOwner;
    if (_ownerId == owner) return Future.value();
    if (_loading != null) return _loading!.then((_) => ensureLoaded());
    if (_ownerId != null) {
      _saved.clear();
      _recent.clear();
      _ownerId = null;
      notifyListeners();
    }
    return _loading = _load(owner);
  }

  Future<void> _load(int owner) async {
    try {
      final values = await Future.wait([
        _storage.read(key: _key(_savedPrefix, owner)),
        _storage.read(key: _key(_recentPrefix, owner)),
      ]);
      _saved
        ..clear()
        ..addEntries(
          _decode(values[0]).map((record) => MapEntry(record.key, record)),
        );
      _recent
        ..clear()
        ..addAll(_decode(values[1]));
      _ownerId = owner;
      notifyListeners();
    } on Object {
      _saved.clear();
      _recent.clear();
      _ownerId = owner;
      notifyListeners();
    } finally {
      _loading = null;
    }
  }

  bool isSaved(DiscoveryRecord record) => _saved.containsKey(record.key);

  Future<bool> toggleSaved(DiscoveryRecord record) async {
    await ensureLoaded();
    final nowSaved = !_saved.containsKey(record.key);
    if (nowSaved) {
      _saved[record.key] = record;
    } else {
      _saved.remove(record.key);
    }
    notifyListeners();
    await _write(_savedPrefix, _saved.values.toList());
    return nowSaved;
  }

  Future<void> recordView(DiscoveryRecord record) async {
    await ensureLoaded();
    _recent.removeWhere((item) => item.key == record.key);
    _recent.insert(0, record);
    if (_recent.length > 12) _recent.removeRange(12, _recent.length);
    notifyListeners();
    await _write(_recentPrefix, _recent);
  }

  Future<void> clearRecent() async {
    await ensureLoaded();
    _recent.clear();
    notifyListeners();
    await _write(_recentPrefix, _recent);
  }

  Future<void> _write(
    String prefix,
    Iterable<DiscoveryRecord> records,
  ) async {
    final owner = _ownerId ?? _currentOwner;
    try {
      await _storage.write(
        key: _key(prefix, owner),
        value: jsonEncode(records.map((record) => record.toJson()).toList()),
      );
    } on Object {
      // Keep the in-memory shortlist usable when device storage is unavailable.
    }
  }

  static List<DiscoveryRecord> _decode(String? encoded) {
    if (encoded?.trim().isEmpty != false) return const [];
    try {
      final value = jsonDecode(encoded!);
      if (value is! List) return const [];
      return value
          .whereType<Map>()
          .map((item) => DiscoveryRecord.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .where((record) => record.id > 0 && record.title.isNotEmpty)
          .toList();
    } on Object {
      return const [];
    }
  }
}
