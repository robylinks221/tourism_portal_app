import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/mood_discovery.dart';
import 'api_endpoint_resolver.dart';
import 'api_exception.dart';
import 'auth_service.dart';

class MoodDiscoveryService {
  MoodDiscoveryService._();

  static final MoodDiscoveryService instance = MoodDiscoveryService._();

  static const _freshFor = Duration(minutes: 2);
  final Map<String, Future<MoodDiscoveryData>> _requests = {};
  final Map<String, DateTime> _requestedAt = {};

  Future<MoodDiscoveryData> fetch(String moodKey, {bool refresh = false}) {
    if (refresh) invalidate(moodKey);
    final existing = _requests[moodKey];
    final requestedAt = _requestedAt[moodKey];
    if (existing != null &&
        requestedAt != null &&
        DateTime.now().difference(requestedAt) < _freshFor) {
      return existing;
    }
    _requests.remove(moodKey);
    _requestedAt.remove(moodKey);

    late final Future<MoodDiscoveryData> request;
    request = _load(moodKey).catchError((Object error, StackTrace stackTrace) {
      if (identical(_requests[moodKey], request)) {
        _requests.remove(moodKey);
        _requestedAt.remove(moodKey);
      }
      Error.throwWithStackTrace(error, stackTrace);
    });
    _requests[moodKey] = request;
    _requestedAt[moodKey] = DateTime.now();
    return request;
  }

  void invalidate(String moodKey) {
    _requests.remove(moodKey);
    _requestedAt.remove(moodKey);
  }

  Future<MoodDiscoveryData> _load(String moodKey) async {
    String? requestBaseUrl;
    try {
      requestBaseUrl = await AuthService.instance.resolveFeatureBaseUrl();
      final encodedMood = Uri.encodeComponent(moodKey);
      final response = await http
          .get(
            Uri.parse('$requestBaseUrl/safari-moods/$encodedMood'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));

      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          decoded is Map && decoded['message'] != null
              ? decoded['message'].toString()
              : 'This Safari Mood could not be loaded.',
          statusCode: response.statusCode,
        );
      }
      if (decoded is! Map) {
        throw const FormatException('Unreadable mood discovery response.');
      }
      return MoodDiscoveryData.fromJson(Map<String, dynamic>.from(decoded));
    } on ApiEndpointUnavailable {
      throw const ApiException(
        'Cannot reach Safari Mood discovery. Check the API connection.',
      );
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException('The Safari Mood connection failed.');
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException('Safari Mood discovery timed out.');
    } on FormatException {
      throw const ApiException('The Safari Mood response was unreadable.');
    } on http.ClientException {
      throw const ApiException('The Safari Mood request failed.');
    }
  }
}
