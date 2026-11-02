import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'auth_service.dart';

class AdvertisementAdminService {
  AdvertisementAdminService._();
  static final instance = AdvertisementAdminService._();
  Future<Map<String, String>> _headers() async => {
    'Accept':'application/json',
    'Authorization':'Bearer ${await AuthService.instance.requireToken()}',
  };
  Future<Uri> _uri(String path) async => Uri.parse('${await AuthService.instance.resolveFeatureBaseUrl()}$path');
  Map<String,dynamic> _decode(http.Response response) {
    dynamic json;
    try { json=jsonDecode(response.body); } catch (_) { throw Exception('Unreadable server response (${response.statusCode})'); }
    if(response.statusCode>=400) {
      final data=json is Map?json:<String,dynamic>{};
      throw Exception(data['message']?.toString()??'Request failed (${response.statusCode})');
    }
    return json is Map ? Map<String,dynamic>.from(json) : <String,dynamic>{};
  }
  Future<List<Map<String,dynamic>>> all() async {
    final response=await http.get(await _uri('/admin/advertisements'),headers:await _headers()).timeout(const Duration(seconds:30));
    final data=_decode(response)['advertisements'];
    final items=data is Map?data['data']:data;
    return items is List?items.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList():[];
  }
  Future<void> save({int? id,required Map<String,String> fields,XFile? image}) async {
    final req=http.MultipartRequest('POST',await _uri(id==null?'/admin/advertisements':'/admin/advertisements/$id'));
    req.headers.addAll(await _headers());
    req.fields.addAll(fields);
    if(image!=null) {
      req.files.add(await http.MultipartFile.fromPath('image',image.path,filename:image.name));
    }
    final streamed=await req.send().timeout(const Duration(seconds:60));
    _decode(await http.Response.fromStream(streamed));
  }
  Future<void> delete(int id) async {
    final response=await http.delete(await _uri('/admin/advertisements/$id'),headers:await _headers()).timeout(const Duration(seconds:30));
    _decode(response);
  }
}
