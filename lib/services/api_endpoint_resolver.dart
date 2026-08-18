import 'dart:async';

import 'package:http/http.dart' as http;

typedef EndpointProbe = Future<bool> Function(String baseUrl);

class ApiEndpointUnavailable implements Exception {
  const ApiEndpointUnavailable(this.candidates);

  final List<String> candidates;
}

class ApiEndpointResolver {
  ApiEndpointResolver({
    List<String>? candidates,
    EndpointProbe? probe,
    Duration cacheDuration = const Duration(seconds: 15),
  }) : candidates = List.unmodifiable(candidates ?? defaultCandidates),
       _probe = probe,
       _cacheDuration = cacheDuration;

  static final ApiEndpointResolver instance = ApiEndpointResolver();

  // ============================================================
  // OPTIONAL BUILD-TIME CONFIGURATION
  // ============================================================

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _lanHost = String.fromEnvironment(
    'API_LAN_HOST',
    defaultValue: 'sinters-macbook-pro.local',
  );

  // ============================================================
  // DEFAULT API CANDIDATES
  // ============================================================
  //
  // Order:
  //
  // 1. Explicit API_BASE_URL if supplied
  // 2. Android phone through ADB reverse
  // 3. Mac hostname over local Wi-Fi
  //
  // Using 127.0.0.1 first makes Android USB testing faster.
  //
  // ============================================================

  static List<String> get defaultCandidates => _unique([
    if (_configuredBaseUrl.trim().isNotEmpty) _configuredBaseUrl,

    // Physical Android phone through:
    // adb reverse tcp:8000 tcp:8000
    'http://127.0.0.1:8000/api',

    // Mac over Wi-Fi
    'http://$_lanHost:8000/api',
  ]);

  final List<String> candidates;

  final EndpointProbe? _probe;

  final Duration _cacheDuration;

  String? _activeBaseUrl;

  DateTime? _lastVerifiedAt;

  Future<String>? _resolutionInProgress;

  // ============================================================
  // CURRENT PREFERRED URL
  // ============================================================

  String get preferredBaseUrl {
    if (_activeBaseUrl != null) {
      return _activeBaseUrl!;
    }

    if (candidates.isNotEmpty) {
      return candidates.first;
    }

    return '';
  }

  // ============================================================
  // RESOLVE AVAILABLE API
  // ============================================================

  Future<String> resolve() async {
    final active = _activeBaseUrl;

    final verifiedAt = _lastVerifiedAt;

    if (active != null &&
        verifiedAt != null &&
        DateTime.now().difference(verifiedAt).compareTo(_cacheDuration) < 0) {
      return active;
    }

    final existing = _resolutionInProgress;

    if (existing != null) {
      return existing;
    }

    final resolution = _resolveAvailableEndpoint();

    _resolutionInProgress = resolution;

    try {
      return await resolution;
    } finally {
      if (identical(_resolutionInProgress, resolution)) {
        _resolutionInProgress = null;
      }
    }
  }

  // ============================================================
  // INVALIDATE FAILED URL
  // ============================================================

  void invalidate([String? failedBaseUrl]) {
    if (failedBaseUrl == null || failedBaseUrl == _activeBaseUrl) {
      _activeBaseUrl = null;
      _lastVerifiedAt = null;
    }
  }

  // ============================================================
  // FIND WORKING ENDPOINT
  // ============================================================

  Future<String> _resolveAvailableEndpoint() async {
    if (candidates.isEmpty) {
      throw const ApiEndpointUnavailable([]);
    }

    // Try currently remembered endpoint first.
    final active = _activeBaseUrl;

    if (active != null) {
      final healthy = await _isHealthy(active);

      if (healthy) {
        return _remember(active);
      }
    }

    // Probe candidates sequentially.
    //
    // Sequential probing is intentional:
    // ADB reverse is first, so Android testing
    // will use 127.0.0.1 before trying Wi-Fi.
    for (final candidate in candidates) {
      if (candidate == active) {
        continue;
      }

      final healthy = await _isHealthy(candidate);

      if (healthy) {
        return _remember(candidate);
      }
    }

    throw ApiEndpointUnavailable(candidates);
  }

  // ============================================================
  // REMEMBER WORKING URL
  // ============================================================

  String _remember(String value) {
    _activeBaseUrl = value;

    _lastVerifiedAt = DateTime.now();

    return value;
  }

  // ============================================================
  // HEALTH CHECK
  // ============================================================
  //
  // IMPORTANT:
  //
  // We deliberately test /catalog instead of /health.
  //
  // Your Laravel API has already confirmed:
  //
  // GET /api/catalog -> HTTP 200
  //
  // So /catalog is a safe public endpoint for deciding whether
  // the Tourism Portal API is reachable.
  //
  // ============================================================

  Future<bool> _isHealthy(String baseUrl) async {
    final customProbe = _probe;

    if (customProbe != null) {
      try {
        return await customProbe(baseUrl);
      } catch (_) {
        return false;
      }
    }

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/catalog'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // REMOVE DUPLICATE URLS
  // ============================================================

  static List<String> _unique(Iterable<String> values) {
    final result = <String>[];

    for (final rawValue in values) {
      final value = rawValue.trim().replaceFirst(RegExp(r'/+$'), '');

      if (value.isNotEmpty && !result.contains(value)) {
        result.add(value);
      }
    }

    return result;
  }
}
