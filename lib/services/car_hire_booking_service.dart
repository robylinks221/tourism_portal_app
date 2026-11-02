import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/car_hire_booking.dart';
import '../models/operator_management.dart';
import 'api_endpoint_resolver.dart';
import 'api_exception.dart';
import 'auth_service.dart';

class CarHireBookingService {
  CarHireBookingService._();

  static final instance = CarHireBookingService._();

  Future<CarHireBooking> createBooking({
    required CarHireVehicle vehicle,
    required DateTime pickupDate,
    required DateTime returnDate,
    required String pickupLocation,
    required int passengers,
    required String hireType,
    String? pickupTime,
    String? returnTime,
    String? dropoffLocation,
    String? specialRequests,
  }) async {
    String? baseUrl;

    try {
      baseUrl = await AuthService.instance.resolveFeatureBaseUrl();
      final token = await AuthService.instance.requireToken();

      final response = await http
          .post(
            Uri.parse(
              '$baseUrl/car-hire/vehicles/${vehicle.id}/book',
            ),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'pickup_date': _date(pickupDate),
              'pickup_time': pickupTime,
              'return_date': _date(returnDate),
              'return_time': returnTime,
              'pickup_location': pickupLocation.trim(),
              'dropoff_location':
                  dropoffLocation?.trim().isEmpty == true
                      ? null
                      : dropoffLocation?.trim(),
              'passengers': passengers,
              'hire_type': hireType,
              'special_requests':
                  specialRequests?.trim().isEmpty == true
                      ? null
                      : specialRequests?.trim(),
            }),
          )
          .timeout(const Duration(seconds: 20));

      final decoded = jsonDecode(response.body);

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw ApiException(
          _message(
            decoded,
            fallback:
                'The car hire request could not be sent.',
          ),
          statusCode: response.statusCode,
        );
      }

      if (decoded is! Map || decoded['booking'] is! Map) {
        throw const ApiException(
          'The car hire booking response was unreadable.',
        );
      }

      return CarHireBooking.fromJson(
        Map<String, dynamic>.from(
          decoded['booking'] as Map,
        ),
      );
    } on ApiException {
      rethrow;
    } on ApiEndpointUnavailable {
      throw const ApiException(
        'Cannot reach the car hire booking service.',
      );
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(baseUrl);
      throw const ApiException(
        'The car hire booking connection failed.',
      );
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(baseUrl);
      throw const ApiException(
        'The car hire booking request timed out.',
      );
    } on FormatException {
      throw const ApiException(
        'The car hire booking response was unreadable.',
      );
    } on http.ClientException {
      throw const ApiException(
        'The car hire booking request failed.',
      );
    }
  }

  Future<List<CarHireBooking>> touristBookings() async {
    String? baseUrl;

    try {
      baseUrl = await AuthService.instance.resolveFeatureBaseUrl();
      final token = await AuthService.instance.requireToken();

      final response = await http
          .get(
            Uri.parse('$baseUrl/car-hire/bookings'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      final decoded = jsonDecode(response.body);

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw ApiException(
          _message(
            decoded,
            fallback:
                'Car hire bookings could not be loaded.',
          ),
          statusCode: response.statusCode,
        );
      }

      if (decoded is! Map || decoded['bookings'] is! List) {
        return const [];
      }

      return (decoded['bookings'] as List)
          .whereType<Map>()
          .map(
            (item) => CarHireBooking.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } on ApiException {
      rethrow;
    } on ApiEndpointUnavailable {
      throw const ApiException(
        'Cannot reach the car hire booking service.',
      );
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(baseUrl);
      throw const ApiException(
        'The car hire booking connection failed.',
      );
    } on TimeoutException {
      throw const ApiException(
        'The car hire bookings request timed out.',
      );
    } on FormatException {
      throw const ApiException(
        'The car hire bookings response was unreadable.',
      );
    } on http.ClientException {
      throw const ApiException(
        'The car hire bookings request failed.',
      );
    }
  }

  Future<List<CarHireBooking>> operatorBookings({
    String status = '',
  }) async {
    final query = status.trim().isEmpty
        ? ''
        : '?status=${Uri.encodeQueryComponent(status.trim())}';

    final decoded = await _authorizedRequest(
      method: 'GET',
      path: '/operator/car-hire/bookings$query',
    );

    if (decoded is! Map || decoded['bookings'] is! List) {
      return const [];
    }

    return (decoded['bookings'] as List)
        .whereType<Map>()
        .map(
          (item) => CarHireBooking.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<CarHireBooking> confirm(
    CarHireBooking booking, {
    String operatorNotes = '',
  }) {
    return _bookingAction(
      booking,
      action: 'confirm',
      operatorNotes: operatorNotes,
    );
  }

  Future<CarHireBooking> decline(
    CarHireBooking booking, {
    String operatorNotes = '',
  }) {
    return _bookingAction(
      booking,
      action: 'decline',
      operatorNotes: operatorNotes,
    );
  }

  Future<CarHireBooking> complete(
    CarHireBooking booking,
  ) {
    return _bookingAction(
      booking,
      action: 'complete',
    );
  }

  Future<CarHireBooking> cancelTouristBooking(
    CarHireBooking booking,
  ) {
    return _bookingAction(
      booking,
      action: 'cancel',
      operator: false,
    );
  }

  Future<CarHireBooking> _bookingAction(
    CarHireBooking booking, {
    required String action,
    String operatorNotes = '',
    bool operator = true,
  }) async {
    final prefix =
        operator ? '/operator/car-hire/bookings' : '/car-hire/bookings';

    final decoded = await _authorizedRequest(
      method: 'POST',
      path: '$prefix/${booking.id}/$action',
      body: operatorNotes.trim().isEmpty
          ? const {}
          : {'operator_notes': operatorNotes.trim()},
    );

    if (decoded is! Map || decoded['booking'] is! Map) {
      throw const ApiException(
        'The car hire booking response was unreadable.',
      );
    }

    return CarHireBooking.fromJson(
      Map<String, dynamic>.from(decoded['booking'] as Map),
    );
  }

  Future<dynamic> _authorizedRequest({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    String? baseUrl;

    try {
      baseUrl = await AuthService.instance.resolveFeatureBaseUrl();
      final token = await AuthService.instance.requireToken();

      final uri = Uri.parse('$baseUrl$path');
      late http.Response response;

      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      if (method == 'GET') {
        response = await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 20));
      } else {
        response = await http
            .post(
              uri,
              headers: headers,
              body: jsonEncode(body ?? const {}),
            )
            .timeout(const Duration(seconds: 20));
      }

      final decoded = jsonDecode(response.body);

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw ApiException(
          _message(
            decoded,
            fallback: 'The car hire booking request failed.',
          ),
          statusCode: response.statusCode,
        );
      }

      return decoded;
    } on ApiException {
      rethrow;
    } on ApiEndpointUnavailable {
      throw const ApiException(
        'Cannot reach the car hire booking service.',
      );
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(baseUrl);
      throw const ApiException(
        'The car hire booking connection failed.',
      );
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(baseUrl);
      throw const ApiException(
        'The car hire booking request timed out.',
      );
    } on FormatException {
      throw const ApiException(
        'The car hire booking response was unreadable.',
      );
    } on http.ClientException {
      throw const ApiException(
        'The car hire booking request failed.',
      );
    }
  }

  static String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String _message(
    dynamic decoded, {
    required String fallback,
  }) {
    if (decoded is Map) {
      final message = decoded['message']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }

      final errors = decoded['errors'];
      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            return value.first.toString();
          }
        }
      }
    }

    return fallback;
  }
}
