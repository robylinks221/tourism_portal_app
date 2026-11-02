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


class CarHireVehiclePage {
  const CarHireVehiclePage({
    required this.vehicles,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.hasMore,
  });

  final List<CarHireVehicle> vehicles;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final bool hasMore;

  factory CarHireVehiclePage.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final vehicles = raw is List
        ? raw
            .whereType<Map>()
            .map((item) => CarHireVehicle.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList()
        : <CarHireVehicle>[];

    final meta = json['meta'] is Map
        ? Map<String, dynamic>.from(json['meta'] as Map)
        : const <String, dynamic>{};

    int integer(dynamic value, [int fallback = 0]) =>
        value is int ? value : int.tryParse(value?.toString() ?? '') ?? fallback;

    return CarHireVehiclePage(
      vehicles: vehicles,
      currentPage: integer(meta['current_page'], 1),
      lastPage: integer(meta['last_page'], 1),
      perPage: integer(meta['per_page'], 20),
      total: integer(meta['total']),
      hasMore: meta['has_more'] == true,
    );
  }
}

class OperatorOfferingsService {
  OperatorOfferingsService._();

  static final instance = OperatorOfferingsService._();

  Future<OperatorOfferings> fetch() async {
    String? requestBaseUrl;
    try {
      requestBaseUrl = await AuthService.instance.resolveFeatureBaseUrl();
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

  Future<CarHireVehiclePage> fetchVehicles({
    int page = 1,
    int perPage = 20,
    String query = '',
    String transmission = 'All',
    String fuelType = 'All',
    int minimumSeats = 0,
    String sort = 'latest',
  }) async {
    String? requestBaseUrl;

    try {
      requestBaseUrl =
          await AuthService.instance.resolveFeatureBaseUrl();

      final parameters = <String, String>{
        'page': '$page',
        'per_page': '$perPage',
        'sort': sort,
      };

      if (query.trim().isNotEmpty) {
        parameters['q'] = query.trim();
      }

      if (transmission.trim().isNotEmpty &&
          transmission.trim().toLowerCase() != 'all') {
        parameters['transmission'] = transmission.trim();
      }

      if (fuelType.trim().isNotEmpty &&
          fuelType.trim().toLowerCase() != 'all') {
        parameters['fuel_type'] = fuelType.trim();
      }

      if (minimumSeats > 0) {
        parameters['min_seats'] = '$minimumSeats';
      }

      final uri = Uri.parse(
        '$requestBaseUrl/car-hire/vehicles',
      ).replace(
        queryParameters: parameters,
      );

      final response = await http
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 20));

      final decoded = jsonDecode(response.body);

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw ApiException(
          decoded is Map && decoded['message'] != null
              ? decoded['message'].toString()
              : 'Safari vehicles could not be loaded.',
          statusCode: response.statusCode,
        );
      }

      if (decoded is! Map) {
        throw const ApiException(
          'The vehicle response was unreadable.',
        );
      }

      return CarHireVehiclePage.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } on ApiEndpointUnavailable {
      throw const ApiException(
        'Cannot reach the car hire service.',
      );
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException(
        'The car hire connection failed.',
      );
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException(
        'The car hire request timed out.',
      );
    } on FormatException {
      throw const ApiException(
        'The car hire response was unreadable.',
      );
    } on http.ClientException {
      throw const ApiException(
        'The car hire request failed.',
      );
    }
  }


}
