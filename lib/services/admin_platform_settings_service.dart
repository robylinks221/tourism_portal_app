import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AdminPlatformSettingsService {
  static Future<Uri> _url(String path) async => Uri.parse('${await AuthService.instance.resolveFeatureBaseUrl()}$path');
  static Future<Map<String, String>> _headers() async => {
    'Authorization': 'Bearer ${await AuthService.instance.requireToken()}',
    'Accept': 'application/json', 'Content-Type': 'application/json',
  };
  static Map<String, dynamic> _decode(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      final detail = body is Map ? (body['message'] ?? body['errors'] ?? 'Request failed') : 'Request failed';
      throw Exception('$detail (${response.statusCode})');
    }
    return Map<String, dynamic>.from(body as Map);
  }
  // Resolve server-provided /storage URLs against the same server used by the API.
  // This avoids relying on a stale LAN IP in APP_URL when ADB reverse is active.
  Future<String> displayLogoUrl(String raw) async {
    final base = Uri.parse(await AuthService.instance.resolveFeatureBaseUrl());
    final original = Uri.tryParse(raw);
    if (original == null) return raw;
    if (original.path.startsWith('/storage/')) {
      return base.replace(path: original.path, query: original.query, fragment: '').toString();
    }
    return raw;
  }
  Future<Map<String, dynamic>> load() async => _decode(await http.get(await _url('/admin/platform-settings'), headers: await _headers()));
  Future<Map<String, dynamic>> save(String section, Map<String, dynamic> data) async => _decode(await http.put(
    await _url('/admin/platform-settings/$section'), headers: await _headers(), body: jsonEncode(data)));
  Future<List<dynamic>> users() async {
    final response = _decode(await http.get(await _url('/admin/platform-users'), headers: await _headers()));
    return List<dynamic>.from(response['data'] as List);
  }
  Future<void> addAdmin(String name, String email, String password) async {
    _decode(await http.post(await _url('/admin/platform-users/administrators'), headers: await _headers(), body: jsonEncode({
      'name': name, 'email': email, 'password': password, 'password_confirmation': password,
    })));
  }
  Future<String> uploadLogo(String filePath) async {
    final request = http.MultipartRequest('POST', await _url('/admin/platform-settings/logo'));
    request.headers['Authorization'] = 'Bearer ${await AuthService.instance.requireToken()}';
    request.headers['Accept'] = 'application/json';
    request.files.add(await http.MultipartFile.fromPath('logo', filePath));
    final response = await http.Response.fromStream(await request.send());
    return (_decode(response)['logo_url'] ?? '').toString();
  }
}
