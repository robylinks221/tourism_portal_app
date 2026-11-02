import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_endpoint_resolver.dart';

class PublicAdvertisement {
  const PublicAdvertisement({required this.id, required this.title, required this.advertiser,
    required this.imagePath, required this.description, required this.actionType,
    required this.actionValue});
  final int id;
  final String title, advertiser, imagePath, description, actionType, actionValue;
  factory PublicAdvertisement.fromJson(Map<String,dynamic> data) => PublicAdvertisement(
    id: (data['id'] as num).toInt(), title: '${data['title'] ?? ''}',
    advertiser: '${data['advertiser_name'] ?? ''}', imagePath: '${data['image_path'] ?? ''}',
    description: '${data['description'] ?? ''}', actionType: '${data['action_type'] ?? 'none'}',
    actionValue: '${data['action_value'] ?? ''}',
  );
}

class AdvertisementPublicService {
  AdvertisementPublicService._();
  static final instance=AdvertisementPublicService._();
  Future<Uri> _uri(String path, [Map<String,String>? query]) async {
    final base=await ApiEndpointResolver.instance.resolve();
    return Uri.parse('$base$path').replace(queryParameters:query);
  }
  Future<List<PublicAdvertisement>> load(String placement, {String? country}) async {
    final query=<String,String>{'placement':placement};
    if(country!=null && country.isNotEmpty)query['country']=country;
    final response=await http.get(await _uri('/advertisements',query),headers:{'Accept':'application/json'}).timeout(const Duration(seconds:20));
    if(response.statusCode!=200)throw Exception('Unable to load advertisements (${response.statusCode})');
    final decoded=jsonDecode(response.body);
    final rows=decoded is Map?decoded['advertisements']:null;
    if(rows is! List)return [];
    return rows.whereType<Map>().map((e)=>PublicAdvertisement.fromJson(Map<String,dynamic>.from(e))).toList();
  }
  Future<void> impression(int id) async {await _post(id,'impression');}
  Future<void> click(int id) async {await _post(id,'click');}
  Future<void> _post(int id,String action) async {
    try {await http.post(await _uri('/advertisements/$id/$action'),headers:{'Accept':'application/json'}).timeout(const Duration(seconds:10));}
    catch (_) { /* Tracking must not interrupt browsing. */ }
  }
}
