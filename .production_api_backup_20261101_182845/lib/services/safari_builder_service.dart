import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/operator_management.dart';
import 'api_endpoint_resolver.dart';
import 'api_exception.dart';
import 'auth_service.dart';

class SafariBuilderService {
  SafariBuilderService._();

  static final instance = SafariBuilderService._();

  Future<List<OperatorTour>> recommend({
    required List<int> activityIds,
    required DateTime dateStart,
    required DateTime dateEnd,
    required double budget,
  }) async {
    String? baseUrl;
    try {
      baseUrl = await AuthService.instance.resolveBaseUrl();
      final response = await http
          .post(
            Uri.parse('$baseUrl/safari-builder/recommendations'),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'activity_ids': activityIds,
              'date_start': _date(dateStart),
              'date_end': _date(dateEnd),
              'budget': budget,
            }),
          )
          .timeout(const Duration(seconds: 20));
      final decoded =
          response.body.isEmpty
              ? <String, dynamic>{}
              : jsonDecode(response.body);
      final data =
          decoded is Map
              ? Map<String, dynamic>.from(decoded)
              : <String, dynamic>{};
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          _message(data) ?? 'Safari recommendations could not be created.',
          statusCode: response.statusCode,
        );
      }
      final items = data['recommendations'];
      if (items is! List) return const [];
      return items
          .whereType<Map>()
          .map((item) => OperatorTour.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on ApiEndpointUnavailable {
      throw const ApiException(
        'Cannot reach the safari recommendation service.',
      );
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(baseUrl);
      throw const ApiException('The safari recommendation connection failed.');
    } on TimeoutException {
      throw const ApiException('Creating recommendations timed out.');
    } on FormatException {
      throw const ApiException('The recommendation response was unreadable.');
    } on http.ClientException {
      throw const ApiException('The recommendation request failed.');
    }
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  static String? _message(Map<String, dynamic> data) {
    final errors = data['errors'];
    if (errors is Map) {
      for (final error in errors.values) {
        if (error is List && error.isNotEmpty) return error.first.toString();
      }
    }
    return data['message']?.toString();
  }
}
