import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class AdminCustomizationService {
  AdminCustomizationService._();
  static final instance = AdminCustomizationService._();
  static const _timeout = Duration(seconds: 30);

  Future<Map<String, dynamic>> _request(String method, String path,
      {Map<String, dynamic>? body, bool authenticated = true}) async {
    final base = await AuthService.instance.resolveFeatureBaseUrl();
    final token = authenticated ? await AuthService.instance.requireToken() : null;
    final req = http.Request(method, Uri.parse('$base$path'));
    req.headers['Accept'] = 'application/json';
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      req.headers['Content-Type'] = 'application/json';
      req.body = jsonEncode(body);
    }
    final streamed = await req.send().timeout(_timeout);
    return _decode(await http.Response.fromStream(streamed));
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> data;
    try {
      data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      throw Exception('Unexpected server response (${response.statusCode}).');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String? detail;
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        detail = first is List && first.isNotEmpty ? first.first.toString() : first.toString();
      }
      throw Exception(detail ?? data['message']?.toString() ?? 'Request failed (${response.statusCode}).');
    }
    return data;
  }

  Future<Map<String, dynamic>> appearance() => _request('GET', '/app/appearance', authenticated: false);
  Future<Map<String, dynamic>> saveAppearance({required String font, required String primary,
    required String secondary, required String background, required String mode}) =>
      _request('PUT', '/admin/app/appearance', body: {
        'font_family': font, 'primary_color': primary, 'secondary_color': secondary,
        'background_color': background, 'display_mode': mode,
      });
  Future<Map<String, dynamic>> resetAppearance() => _request('POST', '/admin/app/appearance/reset');
  Future<Map<String, dynamic>> profile() => _request('GET', '/admin/profile');
  Future<Map<String, dynamic>> updateProfile({required String name, required String email,
      String? currentPassword}) => _request('PATCH', '/admin/profile', body: {
        'name': name, 'email': email,
        if (currentPassword != null && currentPassword.isNotEmpty) 'current_password': currentPassword,
      });
  Future<Map<String, dynamic>> changePassword({required String current, required String password,
      required String confirmation}) => _request('PUT', '/admin/profile/password', body: {
        'current_password': current, 'password': password, 'password_confirmation': confirmation,
      });
  Future<Map<String, dynamic>> uploadPhoto(Uint8List bytes, String filename) async {
    final base = await AuthService.instance.resolveFeatureBaseUrl();
    final token = await AuthService.instance.requireToken();
    final req = http.MultipartRequest('POST', Uri.parse('$base/admin/profile/photo'));
    req.headers.addAll({'Accept': 'application/json', 'Authorization': 'Bearer $token'});
    req.files.add(http.MultipartFile.fromBytes('photo', bytes, filename: filename));
    final streamed = await req.send().timeout(const Duration(seconds: 90));
    return _decode(await http.Response.fromStream(streamed));
  }
}
