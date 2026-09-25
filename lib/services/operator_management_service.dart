import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/operator_management.dart';
import 'api_endpoint_resolver.dart';
import 'api_exception.dart';
import 'auth_service.dart';

class OperatorManagementService {
  OperatorManagementService._();

  static final OperatorManagementService instance =
      OperatorManagementService._();

  Future<OperatorManagementData> fetch() async {
    final data = await _request('GET', '/operator/manage');
    return OperatorManagementData.fromJson(data);
  }

  Future<void> setCarHireEnabled(bool enabled) async {
    await _request('POST', '/operator/car-hire', body: {'enabled': enabled});
  }

  Future<void> saveTour({
    OperatorTour? tour,
    required Map<String, String> fields,
    required List<int> activityIds,
    required List<int> destinationIds,
    required List<int> moodIds,
    String? imagePath,
  }) async {
    await _multipart(
      tour == null ? '/operator/tours' : '/operator/tours/${tour.id}',
      fields: fields,
      lists: {
        'activity_ids': activityIds.map((id) => id.toString()).toList(),
        'destination_ids': destinationIds.map((id) => id.toString()).toList(),
        'mood_ids': moodIds.map((id) => id.toString()).toList(),
      },
      imagePath: imagePath,
    );
  }

  Future<void> deleteTour(OperatorTour tour) =>
      _delete('/operator/tours/${tour.id}');

  Future<void> saveVehicle({
    CarHireVehicle? vehicle,
    required Map<String, String> fields,
    required List<String> amenities,
    String? imagePath,
  }) async {
    await _multipart(
      vehicle == null
          ? '/operator/vehicles'
          : '/operator/vehicles/${vehicle.id}',
      fields: fields,
      lists: {'amenities': amenities},
      imagePath: imagePath,
    );
  }

  Future<void> deleteVehicle(CarHireVehicle vehicle) =>
      _delete('/operator/vehicles/${vehicle.id}');

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = await AuthService.instance.requireToken();
    String? requestBaseUrl;

    try {
      requestBaseUrl = await AuthService.instance.resolveBaseUrl();
      final uri = Uri.parse('$requestBaseUrl$path');
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final response =
          method == 'GET'
              ? await http
                  .get(uri, headers: headers)
                  .timeout(const Duration(seconds: 20))
              : await http
                  .post(uri, headers: headers, body: jsonEncode(body))
                  .timeout(const Duration(seconds: 20));
      return _decode(response);
    } on ApiEndpointUnavailable {
      throw const ApiException(
        'Cannot reach tour management. Keep Docker running and check Wi-Fi.',
      );
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException('The tour management connection failed.');
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException('The tour management request timed out.');
    } on FormatException {
      throw const ApiException('The tour management response was unreadable.');
    } on http.ClientException {
      throw const ApiException('The tour management request failed.');
    }
  }

  Future<void> _multipart(
    String path, {
    required Map<String, String> fields,
    required Map<String, List<String>> lists,
    String? imagePath,
  }) async {
    final token = await AuthService.instance.requireToken();
    String? requestBaseUrl;

    try {
      requestBaseUrl = await AuthService.instance.resolveBaseUrl();
      final request =
          http.MultipartRequest('POST', Uri.parse('$requestBaseUrl$path'))
            ..headers.addAll({
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            })
            ..fields.addAll(fields);

      for (final entry in lists.entries) {
        if (entry.value.isEmpty) {
          request.fields[entry.key] = '';
        } else {
          for (var index = 0; index < entry.value.length; index++) {
            request.fields['${entry.key}[$index]'] = entry.value[index];
          }
        }
      }
      if (imagePath != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imagePath),
        );
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 90),
      );
      _decode(await http.Response.fromStream(streamed));
    } on ApiEndpointUnavailable {
      throw const ApiException(
        'Cannot save this item. Keep Docker running and check Wi-Fi.',
      );
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException('The save connection was interrupted.');
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException('The image upload timed out.');
    } on FileSystemException {
      throw const ApiException('The selected image is no longer available.');
    } on FormatException {
      throw const ApiException('The API response was unreadable.');
    } on http.ClientException {
      throw const ApiException('The save request failed.');
    }
  }

  Future<void> _delete(String path) async {
    final token = await AuthService.instance.requireToken();
    String? requestBaseUrl;

    try {
      requestBaseUrl = await AuthService.instance.resolveBaseUrl();
      final response = await http
          .delete(
            Uri.parse('$requestBaseUrl$path'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));
      _decode(response);
    } on ApiEndpointUnavailable {
      throw const ApiException(
        'Cannot delete this item. Check the API connection.',
      );
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException('The delete connection was interrupted.');
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException('The delete request timed out.');
    } on FormatException {
      throw const ApiException('The API response was unreadable.');
    } on http.ClientException {
      throw const ApiException('The delete request failed.');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded =
        response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    final data =
        decoded is Map
            ? Map<String, dynamic>.from(decoded)
            : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) return data;

    final errors = data['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          throw ApiException(value.first.toString());
        }
        if (value != null) throw ApiException(value.toString());
      }
    }
    throw ApiException(
      data['message']?.toString() ?? 'Tour management request failed.',
      statusCode: response.statusCode,
    );
  }
}
