import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/admin_award_nomination.dart';
import '../models/admin_award_shortlisting.dart';
import 'api_endpoint_resolver.dart';
import 'api_exception.dart';
import 'auth_service.dart';

class AdminAwardsService {
  AdminAwardsService._();
  static final instance = AdminAwardsService._();

  Future<List<AdminAwardNomination>> nominations({String? status}) async {
    final suffix = status == null ? '' : '?status=${Uri.encodeQueryComponent(status)}';
    final data = await _request('GET', '/admin/award-nominations$suffix');
    final raw = data['nominations'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => AdminAwardNomination.fromJson(Map<String,dynamic>.from(e))).toList();
  }

  Future<void> verify(int id,{String notes=''}) => _request('POST','/admin/award-nominations/$id/verify',body:{'admin_notes':notes.trim().isEmpty?null:notes.trim()});
  Future<void> reject(int id,{required String notes}) => _request('POST','/admin/award-nominations/$id/reject',body:{'admin_notes':notes.trim()});

  Future<AdminAwardShortlistingData> shortlisting(int id) async =>
    AdminAwardShortlistingData.fromJson(await _request('GET','/admin/awards/$id/shortlisting'));

  Future<AdminAwardShortlistingData> calculateShortlisting(int id) async {
    await _request('POST','/admin/awards/$id/shortlisting/calculate');
    return shortlisting(id);
  }

  Future<void> confirmFinalists(int categoryId,{List<int>? nominationIds}) =>
    _request('POST','/admin/award-categories/$categoryId/confirm-finalists',
      body: nominationIds==null?<String,dynamic>{}:{'nomination_ids':nominationIds});

  Future<List<Map<String,dynamic>>> awardCycles() async {
    final data=await _request('GET','/admin/awards');
    final raw=data['awards'];
    if(raw is! List) return const [];
    return raw.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();
  }

  Future<Map<String,dynamic>> awardCycle(int id) async {
    final cycles=await awardCycles();
    for(final cycle in cycles){
      if(int.tryParse(cycle['id'].toString())==id) return cycle;
    }
    throw const ApiException('The requested awards cycle was not found.');
  }

  Future<Map<String,dynamic>> updateAwardCycle(int id,{
    String? title,String? introduction,String? stage,String? votingOpensAt,
    String? votingClosesAt,String? resultsVisibility,bool? isActive,bool? isPublished,
  }) async {
    final body=<String,dynamic>{};
    if(title!=null) body['title']=title;
    if(introduction!=null) body['introduction']=introduction;
    if(stage!=null) body['stage']=stage;
    if(votingOpensAt!=null) body['voting_opens_at']=votingOpensAt;
    if(votingClosesAt!=null) body['voting_closes_at']=votingClosesAt;
    if(resultsVisibility!=null) body['results_visibility']=resultsVisibility;
    if(isActive!=null) body['is_active']=isActive;
    if(isPublished!=null) body['is_published']=isPublished;
    final data=await _request('POST','/admin/awards/$id',body:body);
    return data['award'] is Map ? Map<String,dynamic>.from(data['award']) : data;
  }

  Future<Map<String,dynamic>> _request(String method,String path,{Map<String,dynamic>? body}) async {
    String? baseUrl;
    try {
      final token=await AuthService.instance.requireToken();
      baseUrl=await AuthService.instance.resolveFeatureBaseUrl();
      final uri=Uri.parse('$baseUrl$path');
      final headers={'Accept':'application/json','Content-Type':'application/json','Authorization':'Bearer $token'};
      final response=method=='GET'
        ? await http.get(uri,headers:headers).timeout(const Duration(seconds:20))
        : await http.post(uri,headers:headers,body:jsonEncode(body??<String,dynamic>{})).timeout(const Duration(seconds:20));
      final decoded=response.body.isEmpty?<String,dynamic>{}:jsonDecode(response.body);
      final data=decoded is Map?Map<String,dynamic>.from(decoded):<String,dynamic>{};
      if(response.statusCode>=200&&response.statusCode<300) return data;
      throw ApiException(data['message']?.toString()??'Awards administration request failed.',statusCode:response.statusCode);
    } on ApiEndpointUnavailable { throw const ApiException('Cannot reach awards administration services.');
    } on SocketException { ApiEndpointResolver.instance.invalidate(baseUrl); throw const ApiException('The awards administration connection failed.');
    } on TimeoutException { throw const ApiException('Awards administration request timed out.');
    } on FormatException { throw const ApiException('The awards administration response was unreadable.');
    } on http.ClientException { throw const ApiException('The awards administration request failed.'); }
  }
}
