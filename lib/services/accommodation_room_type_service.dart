import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/accommodation_room_type.dart';
import 'auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Uses the same resolved API base URL and bearer token as the host app.
class AccommodationRoomTypeService {
  const AccommodationRoomTypeService({required this.baseUrl, this.token});
  static Future<AccommodationRoomTypeService> forCurrentApp() async {
    final baseUrl = await AuthService.instance.resolveFeatureBaseUrl();
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    final token = await storage.read(key: 'tourism_portal_auth_token');
    return AccommodationRoomTypeService(baseUrl: baseUrl, token: token);
  }
  final String baseUrl;
  final String? token;
  Map<String,String> get _headers => {
    'Accept':'application/json',
    'Content-Type':'application/json',
    if (token != null && token!.isNotEmpty) 'Authorization':'Bearer $token',
  };
  Uri _uri(String path) => Uri.parse('${baseUrl.replaceAll(RegExp(r'/$'), '')}$path');
  Future<Map<String,dynamic>> _send(String method,String path,[Map<String,dynamic>? body]) async {
    final request = http.Request(method,_uri(path));
    request.headers.addAll(_headers);
    if(body != null) request.body = jsonEncode(body);
    final response = await http.Response.fromStream(await request.send().timeout(const Duration(seconds:20)));
    final dynamic data = jsonDecode(response.body);
    if(response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map ? data['message'] : null;
      throw Exception(message?.toString() ?? 'Request failed (${response.statusCode})');
    }
    if(data is! Map) throw const FormatException('Expected an object response');
    return Map<String,dynamic>.from(data);
  }
  Future<List<AccommodationRoomType>> list(int accommodationId) async {
    final json = await _send('GET','/accommodations/$accommodationId/room-types');
    final values = json['room_types'];
    if(values is! List) throw const FormatException('Missing room_types array');
    return values.map((e)=>AccommodationRoomType.fromJson(Map<String,dynamic>.from(e as Map))).toList();
  }
  Future<AccommodationRoomType> create(int accommodationId, Map<String,dynamic> fields) async {
    final json = await _send('POST','/admin/accommodations/$accommodationId/room-types',fields);
    return AccommodationRoomType.fromJson(Map<String,dynamic>.from(json['room_type'] as Map));
  }
  Future<AccommodationRoomType> update(int roomTypeId, Map<String,dynamic> fields) async {
    final json = await _send('PUT','/admin/accommodation-room-types/$roomTypeId',fields);
    return AccommodationRoomType.fromJson(Map<String,dynamic>.from(json['room_type'] as Map));
  }
  Future<AccommodationRoomType> setActive(int roomTypeId,bool active) async {
    final json = await _send('PATCH','/admin/accommodation-room-types/$roomTypeId/status',{'is_active':active});
    return AccommodationRoomType.fromJson(Map<String,dynamic>.from(json['room_type'] as Map));
  }
}
