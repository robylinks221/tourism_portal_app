import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/auth_user.dart';
import 'api_endpoint_resolver.dart';
import 'api_exception.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const String _tokenKey = 'tourism_portal_auth_token';

  // Remembered login details are stored in FlutterSecureStorage,
  // separate from the authenticated session token.
  static const String _rememberLoginKey = 'tourism_portal_remember_login';
  static const String _rememberedEmailKey = 'tourism_portal_remembered_email';
  static const String _rememberedPasswordKey =
      'tourism_portal_remembered_password';

  static const Duration _requestTimeout = Duration(seconds: 20);
  static const Duration _uploadTimeout = Duration(seconds: 90);

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final http.Client _client = http.Client();

  AuthUser? currentUser;
  Future<String>? _profilePhotoUrlFuture;
  int _profilePhotoRevision = 0;

  Future<String> resolveBaseUrl() => ApiEndpointResolver.instance.resolve();

  // Use the same production API for all feature requests, including
  // catalog data required by guide and operator profile forms.
  Future<String> resolveFeatureBaseUrl() => resolveBaseUrl();

  Future<RememberedLogin> loadRememberedLogin() async {
    final rememberValue = await _storage.read(key: _rememberLoginKey);
    final remember = rememberValue == 'true';

    if (!remember) {
      return const RememberedLogin(enabled: false, email: '', password: '');
    }

    final email = await _storage.read(key: _rememberedEmailKey) ?? '';
    final password = await _storage.read(key: _rememberedPasswordKey) ?? '';

    return RememberedLogin(enabled: true, email: email, password: password);
  }

  Future<void> saveRememberedLogin({
    required String email,
    required String password,
  }) async {
    await _storage.write(key: _rememberLoginKey, value: 'true');
    await _storage.write(
      key: _rememberedEmailKey,
      value: email.trim().toLowerCase(),
    );
    await _storage.write(key: _rememberedPasswordKey, value: password);
  }

  Future<void> clearRememberedLogin() async {
    await _storage.delete(key: _rememberLoginKey);
    await _storage.delete(key: _rememberedEmailKey);
    await _storage.delete(key: _rememberedPasswordKey);
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _post(
      '/login',
      body: {'email': email.trim().toLowerCase(), 'password': password},
    );

    return _saveAuthenticatedSession(response);
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final token = await _requiredToken();
    final response = await _get('/profile', token: token);
    final profile = response['profile'];

    if (profile is! Map) {
      throw const ApiException(
        'No completed profile was found for this account.',
      );
    }

    return Map<String, dynamic>.from(profile);
  }

  Future<String> currentUserProfilePhotoUrl() {
    return _profilePhotoUrlFuture ??= _loadCurrentUserProfilePhotoUrl();
  }

  Future<String> _loadCurrentUserProfilePhotoUrl() async {
    final user = currentUser;
    if (user == null || !user.profileCompleted) return '';

    try {
      final profile = await fetchProfile();
      return _withImageRevision(storageUrl(_profilePhotoPath(profile, user.role)));
    } on ApiException {
      return '';
    }
  }

  String _profilePhotoPath(Map<String, dynamic> profile, String role) {
    final field = role == 'tour_operator' ? 'company_logo' : 'profile_photo';
    return profile[field]?.toString() ?? '';
  }

  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await _post(
      '/register',
      body: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'password_confirmation': password,
        'role': role,
      },
    );

    final userJson = response['user'];
    if (userJson is Map) {
      response['user'] = {
        ...Map<String, dynamic>.from(userJson),
        'profile_completed': false,
      };
    }

    return _saveAuthenticatedSession(response);
  }

  Future<AuthUser?> restoreSession() async {
    final token = await _storage.read(key: _tokenKey);

    if (token == null || token.isEmpty) {
      currentUser = null;
      _profilePhotoUrlFuture = null;
      return null;
    }

    try {
      final response = await _get('/user', token: token);
      final userJson = response['user'];

      if (userJson is! Map) {
        throw const ApiException('The API returned an invalid user record.');
      }

      currentUser = AuthUser.fromJson(Map<String, dynamic>.from(userJson));
      _profilePhotoUrlFuture = null;
      return currentUser;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _clearLocalSession();
      }
      return null;
    }
  }

  Future<void> logout() async {
    final token = await _storage.read(key: _tokenKey);

    try {
      if (token != null && token.isNotEmpty) {
        await _post('/logout', token: token);
      }
    } catch (_) {
      // Local sign out must still succeed if the API is temporarily unavailable.
    } finally {
      await _clearLocalSession();
    }
  }

  Future<AuthUser> completeProfile({
    required Map<String, String> fields,
    required Map<String, String> files,
    Map<String, List<String>> fileLists = const {},
    Map<String, List<String>> listFields = const {},
  }) async {
    return _saveProfile(
      path: '/profile/complete',
      fields: fields,
      files: files,
      fileLists: fileLists,
      listFields: listFields,
    );
  }

  Future<AuthUser> updateProfile({
    required Map<String, String> fields,
    required Map<String, String> files,
    Map<String, List<String>> fileLists = const {},
    Map<String, List<String>> listFields = const {},
  }) {
    return _saveProfile(
      path: '/profile',
      fields: fields,
      files: files,
      fileLists: fileLists,
      listFields: listFields,
    );
  }

  Future<void> deleteAccount() async {
    final token = await _requiredToken();

    try {
      await _delete('/account', token: token);
      await _clearLocalSession();
    } on ApiException {
      rethrow;
    }
  }

  Future<AuthUser> _saveProfile({
    required String path,
    required Map<String, String> fields,
    required Map<String, String> files,
    required Map<String, List<String>> fileLists,
    required Map<String, List<String>> listFields,
  }) async {
    final token = await _requiredToken();
    String? requestBaseUrl;

    try {
      requestBaseUrl = await resolveBaseUrl();
      final request =
          http.MultipartRequest('POST', Uri.parse('$requestBaseUrl$path'))
            ..headers.addAll({
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            })
            ..fields.addAll(fields);

      for (final entry in listFields.entries) {
        for (var index = 0; index < entry.value.length; index++) {
          request.fields['${entry.key}[$index]'] = entry.value[index];
        }
      }

      for (final entry in files.entries) {
        final image = File(entry.value);
        if (!await image.exists() || await image.length() == 0) {
          throw const ApiException('A selected image is missing or empty. Please select it again.');
        }
        request.files.add(
          await http.MultipartFile.fromPath(entry.key, entry.value),
        );
      }

      for (final entry in fileLists.entries) {
        for (final path in entry.value) {
          final image = File(path);
          if (!await image.exists() || await image.length() == 0) {
            throw const ApiException('A selected gallery image is missing or empty. Please select it again.');
          }
          request.files.add(
            await http.MultipartFile.fromPath('${entry.key}[]', path),
          );
        }
      }

      final streamedResponse = await request.send().timeout(_uploadTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      final data = _decodeResponse(response);
      final userJson = data['user'];
      final profileJson = data['profile'];

      if (userJson is! Map) {
        throw const ApiException('The API returned an invalid user record.');
      }

      currentUser = AuthUser.fromJson(Map<String, dynamic>.from(userJson));
      // An image upload can succeed while the old URL is still cached by the
      // image provider. Bump the revision and resolve the canonical image path.
      if (files.isNotEmpty || fileLists.isNotEmpty) {
        _profilePhotoRevision++;
      }
      _profilePhotoUrlFuture = null;
      if (profileJson is Map) {
        final path = _profilePhotoPath(
          Map<String, dynamic>.from(profileJson),
          currentUser!.role,
        );
        if (path.trim().isNotEmpty) {
          _profilePhotoUrlFuture = Future<String>.value(
            _withImageRevision(storageUrl(path)),
          );
        }
      }
      return currentUser!;
    } on ApiEndpointUnavailable catch (error) {
      throw ApiException(_connectionError(error.candidates));
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException(
        'The Tourism Portal API connection was interrupted. Try again.',
      );
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException(
        'The profile upload timed out. Check the connection and try again.',
      );
    } on FormatException {
      throw const ApiException('The API returned an unreadable response.');
    } on FileSystemException {
      throw const ApiException(
        'One of the selected images is no longer available. Select it again.',
      );
    } on http.ClientException {
      throw const ApiException(
        'The profile upload failed. Check the API connection and try again.',
      );
    }
  }

  Future<String> _requiredToken() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Your session has expired. Please sign in again.',
      );
    }
    return token;
  }

  Future<String> requireToken() => _requiredToken();

  Future<AuthUser> _saveAuthenticatedSession(
    Map<String, dynamic> response,
  ) async {
    final token = response['token']?.toString();
    final userJson = response['user'];

    if (token == null || token.isEmpty || userJson is! Map) {
      throw const ApiException('The API returned an invalid login response.');
    }

    final user = AuthUser.fromJson(Map<String, dynamic>.from(userJson));

    try {
      user.homeRoute;
    } on StateError {
      throw const ApiException(
        'This account role is not supported by the app.',
      );
    }

    await _storage.write(key: _tokenKey, value: token);
    currentUser = user;
    _profilePhotoUrlFuture = null;
    return user;
  }

  Future<Map<String, dynamic>> _get(String path, {String? token}) async {
    String? requestBaseUrl;
    try {
      requestBaseUrl = await resolveBaseUrl();
      final response = await _client
          .get(
            Uri.parse('$requestBaseUrl$path'),
            headers: _headers(token: token),
          )
          .timeout(_requestTimeout);
      return _decodeResponse(response);
    } on ApiEndpointUnavailable catch (error) {
      throw ApiException(_connectionError(error.candidates));
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException(
        'The Tourism Portal API connection was interrupted. Try again.',
      );
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException(
        'The Tourism Portal API did not respond. Try again.',
      );
    } on FormatException {
      throw const ApiException('The API returned an unreadable response.');
    } on http.ClientException {
      throw const ApiException(
        'The account request failed. Check the API connection and try again.',
      );
    }
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    String? requestBaseUrl;
    try {
      requestBaseUrl = await resolveBaseUrl();
      final response = await _client
          .post(
            Uri.parse('$requestBaseUrl$path'),
            headers: _headers(token: token),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(_requestTimeout);
      return _decodeResponse(response);
    } on ApiEndpointUnavailable catch (error) {
      throw ApiException(_connectionError(error.candidates));
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException(
        'The Tourism Portal API connection was interrupted. Try again.',
      );
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException(
        'The Tourism Portal API did not respond. Try again.',
      );
    } on FormatException {
      throw const ApiException('The API returned an unreadable response.');
    } on http.ClientException {
      throw const ApiException(
        'The API request failed. Check the connection and try again.',
      );
    }
  }

  Future<Map<String, dynamic>> _delete(
    String path, {
    required String token,
  }) async {
    String? requestBaseUrl;
    try {
      requestBaseUrl = await resolveBaseUrl();
      final response = await _client
          .delete(
            Uri.parse('$requestBaseUrl$path'),
            headers: _headers(token: token),
          )
          .timeout(_requestTimeout);
      return _decodeResponse(response);
    } on ApiEndpointUnavailable catch (error) {
      throw ApiException(_connectionError(error.candidates));
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException(
        'The Tourism Portal API connection was interrupted. Try again.',
      );
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException(
        'The Tourism Portal API did not respond. Try again.',
      );
    } on FormatException {
      throw const ApiException('The API returned an unreadable response.');
    } on http.ClientException {
      throw const ApiException(
        'The account request failed. Check the API connection and try again.',
      );
    }
  }

  // Accept absolute URLs, /storage/... URLs, and Laravel's storage/...
  // database paths without accidentally producing /storage/storage/....
  static String storageUrl(String? path) {
    var value = path?.trim() ?? '';
    if (value.isEmpty) return '';
    final uri = Uri.tryParse(value);
    if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
      return value;
    }
    value = value.replaceFirst(RegExp(r'^/+'), '');
    if (value.startsWith('api/storage/')) {
      value = value.substring('api/storage/'.length);
    } else if (value.startsWith('storage/')) {
      value = value.substring('storage/'.length);
    } else if (value.startsWith('public/')) {
      value = value.substring('public/'.length);
    }
    final baseUrl = ApiEndpointResolver.instance.preferredBaseUrl;
    final apiRoot = baseUrl.endsWith('/api')
        ? baseUrl.substring(0, baseUrl.length - 4)
        : baseUrl;
    return '$apiRoot/storage/$value';
  }

  String _withImageRevision(String url) {
    if (url.isEmpty || _profilePhotoRevision == 0) return url;
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      'profile_revision': '$_profilePhotoRevision',
    }).toString();
  }

  String _connectionError(List<String> candidates) {
    final addresses = candidates.join(' or ');
    return 'Cannot reach the Tourism Portal API at $addresses. '
        'Check your internet connection and try again.';
  }

  Map<String, String> _headers({String? token}) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final dynamic decoded =
        response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    final data =
        decoded is Map
            ? Map<String, dynamic>.from(decoded)
            : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw ApiException(
      _errorMessage(data, response.statusCode),
      statusCode: response.statusCode,
    );
  }

  String _errorMessage(Map<String, dynamic> data, int statusCode) {
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

    final message = data['message']?.toString();
    if (message != null && message.isNotEmpty) {
      return message;
    }

    return 'Request failed (HTTP $statusCode).';
  }

  Future<void> _clearLocalSession() async {
    currentUser = null;
    _profilePhotoUrlFuture = null;
    await _storage.delete(key: _tokenKey);
  }
}

class RememberedLogin {
  const RememberedLogin({
    required this.enabled,
    required this.email,
    required this.password,
  });

  final bool enabled;
  final String email;
  final String password;
}
