import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/tourism_country.dart';
import 'api_endpoint_resolver.dart';
import 'api_exception.dart';
import 'auth_service.dart';

class CountryService {
  CountryService._();

  static final CountryService instance = CountryService._();

  Future<List<TourismCountry>> fetchCountries({bool admin = false}) async {
    String? requestBaseUrl;

    try {
      final token = admin ? await AuthService.instance.requireToken() : null;
      requestBaseUrl = await AuthService.instance.resolveFeatureBaseUrl();

      final response = await http
          .get(
            Uri.parse(
              '$requestBaseUrl${admin ? '/admin/countries' : '/countries'}',
            ),
            headers: {
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      final data = _decode(response);
      final raw = data['countries'];

      if (raw is! List) return const [];

      return raw
          .whereType<Map>()
          .map(
            (item) => TourismCountry.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } on ApiEndpointUnavailable {
      throw const ApiException(
        'Cannot load countries. Keep Docker running and check the API connection.',
      );
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException('Cannot load countries. Check the connection.');
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException('Loading countries timed out.');
    } on FormatException {
      throw const ApiException('The countries response was unreadable.');
    }
  }

  Future<void> updateCountry({
    required TourismCountry country,
    required String tagline,
    required String introduction,
    required int sortOrder,
    required bool isActive,
    String? cardImagePath,
    String? heroImagePath,
    required List<int> moodIds,
    required List<int> activityIds,
    required List<int> destinationIds,
  }) async {
    String? requestBaseUrl;

    try {
      final token = await AuthService.instance.requireToken();
      requestBaseUrl = await AuthService.instance.resolveFeatureBaseUrl();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$requestBaseUrl/admin/countries/${country.id}'),
      )
        ..headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        })
        ..fields.addAll({
          'tagline': tagline.trim(),
          'introduction': introduction.trim(),
          'sort_order': sortOrder.toString(),
          'is_active': isActive ? '1' : '0',
        });

      if (moodIds.isEmpty) {
        request.fields['mood_ids'] = '';
      } else {
        for (var index = 0; index < moodIds.length; index++) {
          request.fields['mood_ids[$index]'] = moodIds[index].toString();
        }
      }

      if (activityIds.isEmpty) {
        request.fields['activity_ids'] = '';
      } else {
        for (var index = 0; index < activityIds.length; index++) {
          request.fields['activity_ids[$index]'] =
              activityIds[index].toString();
        }
      }

      if (destinationIds.isEmpty) {
        request.fields['destination_ids'] = '';
      } else {
        for (var index = 0; index < destinationIds.length; index++) {
          request.fields['destination_ids[$index]'] =
              destinationIds[index].toString();
        }
      }

      if (cardImagePath != null && cardImagePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('card_image', cardImagePath),
        );
      }

      if (heroImagePath != null && heroImagePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('hero_image', heroImagePath),
        );
      }

      final streamed =
          await request.send().timeout(const Duration(seconds: 90));
      _decode(await http.Response.fromStream(streamed));
    } on ApiEndpointUnavailable {
      throw const ApiException(
        'Cannot save this country. Keep Docker running and check the API connection.',
      );
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException('Cannot save this country. Check the connection.');
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException('Saving the country timed out.');
    } on FileSystemException {
      throw const ApiException('A selected image is no longer available.');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    dynamic decoded;

    try {
      decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } on FormatException {
      throw const ApiException('The server returned an unreadable response.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);
        final errors = map['errors'];

        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) {
            throw ApiException(first.first.toString());
          }
        }

        final message = map['message'];
        if (message != null && message.toString().trim().isNotEmpty) {
          throw ApiException(message.toString());
        }
      }

      throw ApiException('Request failed (${response.statusCode}).');
    }

    if (decoded is! Map) {
      throw const FormatException();
    }

    return Map<String, dynamic>.from(decoded);
  }
}
