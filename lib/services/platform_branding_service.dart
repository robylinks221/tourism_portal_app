import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class PlatformBrandingService {
  PlatformBrandingService._();
  static final instance = PlatformBrandingService._();
  Future<String>? _logoRequest;

  Future<String> logoUrl({bool refresh = false}) {
    if (refresh) _logoRequest = null;
    return _logoRequest ??= _fetchLogo();
  }

  Future<String> _fetchLogo() async {
    try {
      final base = Uri.parse(await AuthService.instance.resolveBaseUrl());
      final endpoint = Uri.parse('${base.toString().replaceAll(RegExp(r"/+$"), "")}/branding');
      final response = await http.get(endpoint, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 9));
      if (response.statusCode != 200) return '';
      final body = jsonDecode(response.body);
      if (body is! Map) return '';
      final raw = (body['logo_url'] ?? '').toString();
      if (raw.isEmpty) return '';
      final uri = Uri.tryParse(raw);
      if (uri == null) return '';
      if (uri.path.startsWith('/storage/')) {
        // Uploaded logos may contain an old APP_URL host. Use the live API host.
        return base.replace(path: uri.path, query: uri.query, fragment: '').toString();
      }
      return base.resolve(raw).toString();
    } catch (_) {
      return '';
    }
  }
}
