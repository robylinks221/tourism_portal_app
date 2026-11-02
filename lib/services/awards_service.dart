import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/awards.dart';
import 'api_endpoint_resolver.dart';
import 'api_exception.dart';
import 'auth_service.dart';

class AwardsService {
  AwardsService._();
  static final AwardsService instance = AwardsService._();
  static const _timeout = Duration(seconds: 20);

  Future<AwardsHomeData> fetchHome() async => AwardsHomeData.fromJson(
    await _request('GET', '/awards', authenticated: false),
  );

  Future<List<AwardCategory>> fetchCategories() async {
    final d = await _request('GET', '/awards/categories', authenticated: false);
    return _maps(d['categories']).map(AwardCategory.fromJson).toList();
  }

  Future<List<AwardFinalist>> fetchFinalists({int? categoryId}) async {
    final path =
        categoryId == null
            ? '/awards/finalists'
            : '/awards/categories/$categoryId/finalists';
    final d = await _request(
      'GET',
      path,
      authenticated: AuthService.instance.currentUser != null,
    );
    return _maps(d['finalists']).map(AwardFinalist.fromJson).toList();
  }

  Future<AwardFinalist> fetchFinalist(int id) async {
    final d = await _request(
      'GET',
      '/awards/finalists/$id',
      authenticated: AuthService.instance.currentUser != null,
    );
    final raw = d['finalist'];
    if (raw is! Map) {
      throw const ApiException('The finalist could not be loaded.');
    }
    return AwardFinalist.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<AwardNominationOptions> fetchNominationOptions({
    String search = '',
    int? categoryId,
  }) async {
    final query = search.trim();
    final params = <String>[];
    if (query.length >= 2) {
      params.add('q=${Uri.encodeQueryComponent(query)}');
    }
    if (categoryId != null && categoryId > 0) {
      params.add('category_id=$categoryId');
    }
    final suffix = params.isEmpty ? '' : '?${params.join('&')}';
    return AwardNominationOptions.fromJson(
      await _request('GET', '/awards/nomination-options$suffix'),
    );
  }

  Future<AwardNominationRecord> submitNomination({
    required int categoryId,
    required int guideUserId,
    required Map<String, int> ratings,
    String supportingComment = '',
  }) async {
    final d = await _request(
      'POST',
      '/awards/nominations',
      body: {
        'award_category_id': categoryId,
        'guide_user_id': guideUserId,
        'ratings':
            ratings.entries
                .map((e) => {'criterion_key': e.key, 'rating': e.value})
                .toList(),
        'supporting_comment': supportingComment.trim(),
      },
    );
    final raw = d['nomination'];
    if (raw is! Map) {
      throw const ApiException('The nomination response was incomplete.');
    }
    return AwardNominationRecord.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<List<AwardNominationRecord>> fetchMyNominations() async {
    final d = await _request('GET', '/awards/my-nominations');
    return _maps(d['nominations']).map(AwardNominationRecord.fromJson).toList();
  }

  Future<Map<String, dynamic>> vote(int finalistId) =>
      _request('POST', '/awards/finalists/$finalistId/vote');
  Future<List<AwardVoteRecord>> fetchMyVotes() async {
    final d = await _request('GET', '/awards/my-votes');
    return _maps(d['votes']).map(AwardVoteRecord.fromJson).toList();
  }

  Future<List<AwardWinner>> fetchWinners({int? year}) async {
    final suffix = year == null ? '' : '?year=$year';
    final d = await _request(
      'GET',
      '/awards/winners$suffix',
      authenticated: false,
    );
    return _maps(d['winners']).map(AwardWinner.fromJson).toList();
  }

  Future<AwardResultsData> fetchResults() async => AwardResultsData.fromJson(
    await _request('GET', '/awards/results', authenticated: false),
  );

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    bool authenticated = true,
    Map<String, dynamic>? body,
  }) async {
    String? base;
    try {
      base = await AuthService.instance.resolveFeatureBaseUrl();
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      if (authenticated) {
        headers['Authorization'] =
            'Bearer ${await AuthService.instance.requireToken()}';
      }
      final uri = Uri.parse('$base$path');
      final r = await (method == 'POST'
              ? http.post(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              : http.get(uri, headers: headers))
          .timeout(_timeout);
      final dynamic decoded =
          r.body.trim().isEmpty ? <String, dynamic>{} : jsonDecode(r.body);
      final data =
          decoded is Map
              ? Map<String, dynamic>.from(decoded)
              : <String, dynamic>{};
      if (r.statusCode >= 200 && r.statusCode < 300) return data;
      throw ApiException(
        _message(data, r.statusCode),
        statusCode: r.statusCode,
      );
    } on ApiException {
      rethrow;
    } on ApiEndpointUnavailable {
      throw const ApiException('Cannot reach the Awards service.');
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(base);
      throw const ApiException('The Awards connection was interrupted.');
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(base);
      throw const ApiException('The Awards request timed out.');
    } on FormatException {
      throw const ApiException('The Awards response was unreadable.');
    } on http.ClientException {
      throw const ApiException('The Awards request failed.');
    }
  }

  static List<Map<String, dynamic>> _maps(dynamic v) =>
      v is List
          ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : [];
  static String _message(Map<String, dynamic> d, int code) {
    final e = d['errors'];
    if (e is Map) {
      for (final v in e.values) {
        if (v is List && v.isNotEmpty) return v.first.toString();
        if (v != null) return v.toString();
      }
    }
    final m = d['message']?.toString();
    return m != null && m.trim().isNotEmpty
        ? m
        : 'Request failed (HTTP $code).';
  }
}
