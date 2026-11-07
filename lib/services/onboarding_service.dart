import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/onboarding_slide.dart';
import 'api_endpoint_resolver.dart';
import 'api_exception.dart';
import 'auth_service.dart';

class OnboardingService {
  OnboardingService._();

  static final OnboardingService instance = OnboardingService._();
  static const _completedKey = 'tourism_portal_onboarding_completed_v1';
  static const _timeout = Duration(seconds: 20);
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<bool> hasCompleted() async {
    return await _storage.read(key: _completedKey) == 'true';
  }

  Future<void> complete() {
    return _storage.write(key: _completedKey, value: 'true');
  }

  Future<List<OnboardingSlide>> fetchSlides({bool admin = false}) async {
    String? baseUrl;
    try {
      final token = admin ? await AuthService.instance.requireToken() : null;
      baseUrl = await AuthService.instance.resolveFeatureBaseUrl();
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl${admin ? '/admin/onboarding-slides' : '/onboarding-slides'}',
            ),
            headers: {
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);
      final data = _decode(response);
      final rawSlides = data['slides'];
      if (rawSlides is! List) throw const FormatException();
      return rawSlides
          .whereType<Map>()
          .map(
            (item) => OnboardingSlide.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on ApiEndpointUnavailable {
      if (!admin) return fallbackOnboardingSlides;
      throw const ApiException(
        'Cannot reach the onboarding settings. Check the API connection.',
      );
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(baseUrl);
      if (!admin) return fallbackOnboardingSlides;
      throw const ApiException(
        'The onboarding settings connection was interrupted.',
      );
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(baseUrl);
      if (!admin) return fallbackOnboardingSlides;
      throw const ApiException('Loading the onboarding settings timed out.');
    } on FormatException {
      if (!admin) return fallbackOnboardingSlides;
      throw const ApiException('The onboarding response was unreadable.');
    } on http.ClientException {
      if (!admin) return fallbackOnboardingSlides;
      throw const ApiException('The onboarding request failed.');
    }
  }

  Future<void> saveSlide({
    OnboardingSlide? slide,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required bool isActive,
    XFile? imageFile,
  }) async {
    final token = await AuthService.instance.requireToken();
    String? baseUrl;
    try {
      baseUrl = await AuthService.instance.resolveFeatureBaseUrl();
      final path =
          slide == null
              ? '/admin/onboarding-slides'
              : '/admin/onboarding-slides/${slide.id}';
      final request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
            ..headers.addAll({
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            })
            ..fields.addAll({
              'title': title.trim(),
              'subtitle': subtitle.trim(),
              'button_label': buttonLabel.trim(),
              'is_active': isActive ? '1' : '0',
            });
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: imageFile.name,
          ),
        );
      }
      final streamed = await request.send().timeout(
        const Duration(seconds: 90),
      );
      _decode(await http.Response.fromStream(streamed));
    } on ApiEndpointUnavailable {
      throw const ApiException(
        'Cannot save this slide. Check the API connection.',
      );
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(baseUrl);
      throw const ApiException('The slide upload connection was interrupted.');
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(baseUrl);
      throw const ApiException('Saving the slide timed out.');
    } on FileSystemException {
      throw const ApiException('The selected image is no longer available.');
    } on http.ClientException {
      throw const ApiException('The slide request failed.');
    }
  }

  Future<void> reorder(List<int> slideIds) async {
    await _jsonRequest(
      'POST',
      '/admin/onboarding-slides/reorder',
      body: {'slide_ids': slideIds},
    );
  }

  Future<void> deleteSlide(OnboardingSlide slide) {
    return _jsonRequest('DELETE', '/admin/onboarding-slides/${slide.id}');
  }

  Future<void> _jsonRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = await AuthService.instance.requireToken();
    String? baseUrl;
    try {
      baseUrl = await AuthService.instance.resolveFeatureBaseUrl();
      final request = http.Request(method, Uri.parse('$baseUrl$path'))
        ..headers.addAll({
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        });
      if (body != null) request.body = jsonEncode(body);
      final streamed = await request.send().timeout(_timeout);
      _decode(await http.Response.fromStream(streamed));
    } on ApiEndpointUnavailable {
      throw const ApiException(
        'Cannot update the onboarding settings. Check the API connection.',
      );
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(baseUrl);
      throw const ApiException(
        'The onboarding settings connection was interrupted.',
      );
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(baseUrl);
      throw const ApiException('Updating the onboarding settings timed out.');
    } on http.ClientException {
      throw const ApiException('The onboarding settings request failed.');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded =
        response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    if (decoded is! Map) throw const FormatException();
    final data = Map<String, dynamic>.from(decoded);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errors = data['errors'];
      String? validationMessage;
      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            validationMessage = value.first.toString();
            break;
          }
        }
      }
      throw ApiException(
        validationMessage ??
            data['message']?.toString() ??
            'The onboarding request failed.',
        statusCode: response.statusCode,
      );
    }
    return data;
  }
}
