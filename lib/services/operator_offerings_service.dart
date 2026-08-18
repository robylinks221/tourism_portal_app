import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/operator_management.dart';
import 'api_endpoint_resolver.dart';
import 'api_exception.dart';
import 'auth_service.dart';

class OperatorOfferings {
  const OperatorOfferings({required this.tours, required this.vehicles});

  final List<OperatorTour> tours;
  final List<CarHireVehicle> vehicles;

  factory OperatorOfferings.fromJson(Map<String, dynamic> json) {
    return OperatorOfferings(
      tours: _maps(json['tours']).map(OperatorTour.fromJson).toList(),
      vehicles: _maps(json['vehicles']).map(CarHireVehicle.fromJson).toList(),
    );
  }

  static List<Map<String, dynamic>> _maps(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}

class OperatorOfferingsService {
  OperatorOfferingsService._();

  static final instance = OperatorOfferingsService._();

  Future<OperatorOfferings> fetch() async {
    String? requestBaseUrl;
    try {
      requestBaseUrl = await AuthService.instance.resolveBaseUrl();
      final response = await http
          .get(
            Uri.parse('$requestBaseUrl/offerings'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));

      final decoded = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          decoded is Map && decoded['message'] != null
              ? decoded['message'].toString()
              : 'Operator offerings could not be loaded.',
          statusCode: response.statusCode,
        );
      }
      if (decoded is! Map) {
        throw const ApiException('The offerings response was unreadable.');
      }
      return OperatorOfferings.fromJson(Map<String, dynamic>.from(decoded));
    } on ApiEndpointUnavailable {
      throw const ApiException('Cannot reach tours and car hire services.');
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException('The offerings connection failed.');
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException('The offerings request timed out.');
    } on FormatException {
      throw const ApiException('The offerings response was unreadable.');
    } on http.ClientException {
      throw const ApiException('The offerings request failed.');
    }
  }
}
