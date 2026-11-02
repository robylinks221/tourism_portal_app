import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/operator_management.dart';
import 'api_exception.dart';
import 'auth_service.dart';
import 'booking_service.dart';

class TourBookingService {
  TourBookingService._();

  static final TourBookingService instance = TourBookingService._();

  static const Duration _timeout = Duration(seconds: 20);

  Future<BookingItem> bookTour({
    required OperatorTour tour,
    required DateTime startDate,
    required int travellers,
    required String accommodationType,
    String? touristNotes,
  }) async {
    if (travellers < 1) {
      throw const ApiException('At least one traveller is required.');
    }

    final token = await AuthService.instance.requireToken();

    final baseUrl = await AuthService.instance.resolveFeatureBaseUrl();

    final uri = Uri.parse('$baseUrl/bookings/tours/${tour.id}');

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'start_date': _dateOnly(startDate),
              'travellers': travellers,
              'accommodation_type': accommodationType,
              if ((touristNotes ?? '').trim().isNotEmpty)
                'tourist_notes': touristNotes!.trim(),
            }),
          )
          .timeout(_timeout);

      final decoded =
          response.body.trim().isEmpty
              ? <String, dynamic>{}
              : jsonDecode(response.body);

      final data =
          decoded is Map
              ? Map<String, dynamic>.from(decoded)
              : <String, dynamic>{};

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          _message(data, response.statusCode),
          statusCode: response.statusCode,
        );
      }

      final booking = data['booking'];

      if (booking is! Map) {
        throw const ApiException('The booking response was incomplete.');
      }

      return BookingItem.fromJson(Map<String, dynamic>.from(booking));
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('The booking connection was interrupted.');
    } on TimeoutException {
      throw const ApiException('The booking request timed out.');
    } on FormatException {
      throw const ApiException('The booking response was unreadable.');
    } on http.ClientException {
      throw const ApiException('The booking request failed.');
    }
  }

  static String _dateOnly(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  static String _message(Map<String, dynamic> data, int statusCode) {
    final errors = data['errors'];

    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }

        if (value != null) {
          return value.toString();
        }
      }
    }

    return data['message']?.toString() ?? 'Booking failed (HTTP $statusCode).';
  }
}
