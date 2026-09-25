import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/admin_provider.dart';
import 'api_endpoint_resolver.dart';
import 'api_exception.dart';
import 'auth_service.dart';

class AdminProviderService {
  AdminProviderService._();

  static final instance = AdminProviderService._();

  Future<AdminProviderQueue> fetch() async {
    final data = await _request('GET', '/admin/providers');
    return AdminProviderQueue.fromJson(data);
  }

  Future<void> review({
    required int providerId,
    required String status,
    required String notes,
  }) async {
    await _request(
      'POST',
      '/admin/providers/$providerId/verification',
      body: {'status': status, 'notes': notes.trim()},
    );
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    String? baseUrl;
    try {
      final token = await AuthService.instance.requireToken();
      baseUrl = await AuthService.instance.resolveBaseUrl();
      final uri = Uri.parse('$baseUrl$path');
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final response =
          method == 'GET'
              ? await http
                  .get(uri, headers: headers)
                  .timeout(const Duration(seconds: 20))
              : await http
                  .post(uri, headers: headers, body: jsonEncode(body))
                  .timeout(const Duration(seconds: 20));
      final decoded =
          response.body.isEmpty
              ? <String, dynamic>{}
              : jsonDecode(response.body);
      final data =
          decoded is Map
              ? Map<String, dynamic>.from(decoded)
              : <String, dynamic>{};
      if (response.statusCode >= 200 && response.statusCode < 300) return data;
      throw ApiException(
        data['message']?.toString() ?? 'Provider review failed.',
        statusCode: response.statusCode,
      );
    } on ApiEndpointUnavailable {
      throw const ApiException('Cannot reach provider verification services.');
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(baseUrl);
      throw const ApiException('The provider verification connection failed.');
    } on TimeoutException {
      throw const ApiException('Provider verification timed out.');
    } on FormatException {
      throw const ApiException(
        'The provider verification response was unreadable.',
      );
    } on http.ClientException {
      throw const ApiException('The provider verification request failed.');
    }
  }
}
