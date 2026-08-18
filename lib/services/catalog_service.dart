import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/catalog_item.dart';
import '../models/safari_mood.dart';
import 'api_endpoint_resolver.dart';
import 'api_exception.dart';
import 'auth_service.dart';

class CatalogService {
  CatalogService._();

  static final CatalogService instance = CatalogService._();

  Future<TourismCatalog> fetchCatalog({bool admin = false}) async {
    String? requestBaseUrl;
    try {
      final token = admin ? await AuthService.instance.requireToken() : null;
      requestBaseUrl = await AuthService.instance.resolveBaseUrl();
      final response = await http
          .get(
            Uri.parse(
              '$requestBaseUrl${admin ? '/admin/catalog' : '/catalog'}',
            ),
            headers: {
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));
      final data = _decode(response);
      final moodData = data['moods'];
      return TourismCatalog(
        moods:
            moodData is List
                ? moodData
                    .whereType<Map>()
                    .map(
                      (item) =>
                          SafariMood.fromJson(Map<String, dynamic>.from(item)),
                    )
                    .toList()
                : fallbackSafariMoods,
        activities: _items(data['activities'], 'activity'),
        destinations: _items(data['destinations'], 'destination'),
      );
    } on ApiEndpointUnavailable {
      throw const ApiException(
        'Cannot load activities and destinations. Keep Docker running and connect the phone and Mac to the same Wi-Fi.',
      );
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException(
        'Cannot load activities and destinations. Check the API connection.',
      );
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException(
        'Loading activities and destinations timed out.',
      );
    } on FormatException {
      throw const ApiException('The catalog response was unreadable.');
    } on http.ClientException {
      throw const ApiException('The catalog request failed.');
    }
  }

  Future<CatalogItem> fetchDestination(String slug) async {
    String? requestBaseUrl;
    try {
      requestBaseUrl = await AuthService.instance.resolveBaseUrl();
      final response = await http
          .get(
            Uri.parse('$requestBaseUrl/destinations/$slug'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));
      final data = _decode(response);
      final destination = data['destination'];
      if (destination is! Map) throw const FormatException();
      return CatalogItem.fromJson(
        Map<String, dynamic>.from(destination),
        'destination',
      );
    } on ApiEndpointUnavailable {
      throw const ApiException(
        'Cannot load this destination. Keep Docker running and check Wi-Fi.',
      );
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException(
        'Cannot load this destination. Check the API connection.',
      );
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException('Loading the destination timed out.');
    } on FormatException {
      throw const ApiException('The destination response was unreadable.');
    } on http.ClientException {
      throw const ApiException('The destination request failed.');
    }
  }

  Future<CatalogItem> fetchActivity(String slug) async {
    String? requestBaseUrl;
    try {
      requestBaseUrl = await AuthService.instance.resolveBaseUrl();
      final response = await http
          .get(
            Uri.parse('$requestBaseUrl/activities/$slug'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));
      final data = _decode(response);
      final activity = data['activity'];
      if (activity is! Map) throw const FormatException();
      return CatalogItem.fromJson(
        Map<String, dynamic>.from(activity),
        'activity',
      );
    } on ApiEndpointUnavailable {
      throw const ApiException(
        'Cannot load this activity. Keep Docker running and check Wi-Fi.',
      );
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException(
        'Cannot load this activity. Check the API connection.',
      );
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException('Loading the activity timed out.');
    } on FormatException {
      throw const ApiException('The activity response was unreadable.');
    } on http.ClientException {
      throw const ApiException('The activity request failed.');
    }
  }

  Future<List<Accommodation>> fetchAccommodations(
    CatalogItem destination,
  ) async {
    String? requestBaseUrl;
    try {
      final token = await AuthService.instance.requireToken();
      requestBaseUrl = await AuthService.instance.resolveBaseUrl();
      final response = await http
          .get(
            Uri.parse(
              '$requestBaseUrl/admin/destinations/${destination.id}/accommodations',
            ),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));
      final data = _decode(response);
      final items = data['accommodations'];
      if (items is! List) return const [];
      return items
          .whereType<Map>()
          .map(
            (item) => Accommodation.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on ApiEndpointUnavailable {
      throw const ApiException(
        'Cannot load accommodations. Keep Docker running and check Wi-Fi.',
      );
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException(
        'Cannot load accommodations. Check the API connection.',
      );
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException('Loading accommodations timed out.');
    } on FormatException {
      throw const ApiException('The accommodation response was unreadable.');
    } on http.ClientException {
      throw const ApiException('The accommodation request failed.');
    }
  }

  Future<void> saveAccommodation({
    required CatalogItem destination,
    Accommodation? accommodation,
    required Map<String, String> fields,
    required List<String> amenities,
    List<String> imagePaths = const [],
  }) async {
    String? requestBaseUrl;
    try {
      final token = await AuthService.instance.requireToken();
      requestBaseUrl = await AuthService.instance.resolveBaseUrl();
      final path =
          accommodation == null
              ? '/admin/destinations/${destination.id}/accommodations'
              : '/admin/accommodations/${accommodation.id}';
      final request =
          http.MultipartRequest('POST', Uri.parse('$requestBaseUrl$path'))
            ..headers.addAll({
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            })
            ..fields.addAll(fields);
      if (amenities.isEmpty) {
        request.fields['amenities'] = '';
      } else {
        for (var index = 0; index < amenities.length; index++) {
          request.fields['amenities[$index]'] = amenities[index];
        }
      }
      for (var index = 0; index < imagePaths.length && index < 3; index++) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'gallery[$index]',
            imagePaths[index],
          ),
        );
      }
      final streamed = await request.send().timeout(
        const Duration(seconds: 90),
      );
      _decode(await http.Response.fromStream(streamed));
    } on ApiEndpointUnavailable {
      throw const ApiException(
        'Cannot save this accommodation. Keep Docker running and check Wi-Fi.',
      );
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException(
        'Cannot save this accommodation. Check the API connection.',
      );
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException('Saving the accommodation timed out.');
    } on FileSystemException {
      throw const ApiException('The selected image is no longer available.');
    } on FormatException {
      throw const ApiException('The accommodation response was unreadable.');
    } on http.ClientException {
      throw const ApiException('The accommodation request failed.');
    }
  }

  Future<void> deleteAccommodation(Accommodation accommodation) async {
    String? requestBaseUrl;
    try {
      final token = await AuthService.instance.requireToken();
      requestBaseUrl = await AuthService.instance.resolveBaseUrl();
      final response = await http
          .delete(
            Uri.parse(
              '$requestBaseUrl/admin/accommodations/${accommodation.id}',
            ),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));
      _decode(response);
    } on ApiEndpointUnavailable {
      throw const ApiException(
        'Cannot delete this accommodation. Keep Docker running and check Wi-Fi.',
      );
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException(
        'Cannot delete this accommodation. Check the API connection.',
      );
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException('Deleting the accommodation timed out.');
    } on FormatException {
      throw const ApiException('The accommodation response was unreadable.');
    } on http.ClientException {
      throw const ApiException('The accommodation request failed.');
    }
  }

  Future<void> save({
    CatalogItem? item,
    required String type,
    required Map<String, String> fields,
    String? imagePath,
    List<int> destinationIds = const [],
    List<int> activityIds = const [],
    List<int> moodIds = const [],
  }) async {
    final token = await AuthService.instance.requireToken();
    final plural = type == 'activity' ? 'activities' : 'destinations';
    final path = item == null ? '/admin/$plural' : '/admin/$plural/${item.id}';
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
      if (type == 'activity') {
        for (var index = 0; index < destinationIds.length; index++) {
          request.fields['destination_ids[$index]'] =
              destinationIds[index].toString();
        }
      } else {
        for (var index = 0; index < activityIds.length; index++) {
          request.fields['activity_ids[$index]'] =
              activityIds[index].toString();
        }
      }
      if (moodIds.isEmpty) {
        request.fields['mood_ids'] = '';
      } else {
        for (var index = 0; index < moodIds.length; index++) {
          request.fields['mood_ids[$index]'] = moodIds[index].toString();
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
        'Cannot save this catalog item. Keep Docker running and check Wi-Fi.',
      );
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException(
        'Cannot save this catalog item. Check the API connection.',
      );
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException('The image upload timed out.');
    } on FileSystemException {
      throw const ApiException('The selected image is no longer available.');
    }
  }

  Future<void> saveMood({
    SafariMood? mood,
    required Map<String, String> fields,
    String? imagePath,
  }) async {
    final token = await AuthService.instance.requireToken();
    final path = mood == null ? '/admin/moods' : '/admin/moods/${mood.id}';
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
        'Cannot save this safari mood. Keep Docker running and check the connection.',
      );
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException(
        'Cannot save this safari mood. Check the API connection.',
      );
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException('Saving the safari mood timed out.');
    } on FileSystemException {
      throw const ApiException(
        'The selected mood image is no longer available.',
      );
    }
  }

  Future<void> reorderMoods(List<int> moodIds) async {
    final token = await AuthService.instance.requireToken();
    String? requestBaseUrl;
    try {
      requestBaseUrl = await AuthService.instance.resolveBaseUrl();
      final response = await http
          .post(
            Uri.parse('$requestBaseUrl/admin/moods/reorder'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'mood_ids': moodIds}),
          )
          .timeout(const Duration(seconds: 20));
      _decode(response);
    } on ApiEndpointUnavailable {
      throw const ApiException(
        'Cannot reorder safari moods. Keep Docker running and check the connection.',
      );
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException(
        'Cannot reorder safari moods. Check the API connection.',
      );
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException('Reordering safari moods timed out.');
    }
  }

  Future<void> syncMoodActivities({
    required SafariMood mood,
    required List<int> activityIds,
  }) async {
    final token = await AuthService.instance.requireToken();

    String? requestBaseUrl;

    try {
      requestBaseUrl = await AuthService.instance.resolveBaseUrl();

      final response = await http
          .post(
            Uri.parse(
              '$requestBaseUrl/admin/safari-moods/${mood.id}/activities',
            ),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'activity_ids': activityIds}),
          )
          .timeout(const Duration(seconds: 20));

      _decode(response);
    } on ApiEndpointUnavailable {
      throw const ApiException(
        'Cannot update Safari Mood activities. Keep Docker running and check the connection.',
      );
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);

      throw const ApiException(
        'Cannot update Safari Mood activities. Check the API connection.',
      );
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);

      throw const ApiException('Updating Safari Mood activities timed out.');
    } on FormatException {
      throw const ApiException(
        'The Safari Mood activities response was unreadable.',
      );
    } on http.ClientException {
      throw const ApiException('The Safari Mood activities request failed.');
    }
  }

  Future<void> syncMoodDestinations({
    required SafariMood mood,
    required List<int> destinationIds,
  }) async {
    final token = await AuthService.instance.requireToken();

    String? requestBaseUrl;

    try {
      requestBaseUrl = await AuthService.instance.resolveBaseUrl();

      final response = await http
          .post(
            Uri.parse(
              '$requestBaseUrl/admin/safari-moods/${mood.id}/destinations',
            ),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'destination_ids': destinationIds}),
          )
          .timeout(const Duration(seconds: 20));

      _decode(response);
    } on ApiEndpointUnavailable {
      throw const ApiException(
        'Cannot update Safari Mood destinations. Keep Docker running and check the connection.',
      );
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);

      throw const ApiException(
        'Cannot update Safari Mood destinations. Check the API connection.',
      );
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);

      throw const ApiException('Updating Safari Mood destinations timed out.');
    } on FormatException {
      throw const ApiException(
        'The Safari Mood destinations response was unreadable.',
      );
    } on http.ClientException {
      throw const ApiException('The Safari Mood destinations request failed.');
    }
  }

  Future<void> deleteMood(SafariMood mood) async {
    final token = await AuthService.instance.requireToken();
    String? requestBaseUrl;
    try {
      requestBaseUrl = await AuthService.instance.resolveBaseUrl();
      final response = await http
          .delete(
            Uri.parse('$requestBaseUrl/admin/moods/${mood.id}'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));
      _decode(response);
    } on ApiEndpointUnavailable {
      throw const ApiException(
        'Cannot delete this safari mood. Keep Docker running and check the connection.',
      );
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException(
        'Cannot delete this safari mood. Check the API connection.',
      );
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException('Deleting the safari mood timed out.');
    }
  }

  Future<void> delete(CatalogItem item) async {
    final token = await AuthService.instance.requireToken();
    final plural = item.isActivity ? 'activities' : 'destinations';
    String? requestBaseUrl;
    try {
      requestBaseUrl = await AuthService.instance.resolveBaseUrl();
      final response = await http
          .delete(
            Uri.parse('$requestBaseUrl/admin/$plural/${item.id}'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));
      _decode(response);
    } on ApiEndpointUnavailable {
      throw const ApiException(
        'Cannot delete this catalog item. Keep Docker running and check Wi-Fi.',
      );
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException(
        'Cannot delete this catalog item. Check the API connection.',
      );
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);
      throw const ApiException('Deleting the catalog item timed out.');
    }
  }

  List<CatalogItem> _items(dynamic value, String type) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (item) => CatalogItem.fromJson(Map<String, dynamic>.from(item), type),
        )
        .toList();
  }

  Map<String, dynamic> _decode(http.Response response) {
    dynamic decoded;
    try {
      decoded =
          response.body.isEmpty
              ? <String, dynamic>{}
              : jsonDecode(response.body);
    } on FormatException {
      if (response.statusCode == 413) {
        throw const ApiException(
          'The selected photos are too large. Choose smaller photos and try again.',
        );
      }
      if (response.statusCode >= 400) {
        throw ApiException(
          'The server could not complete this request (HTTP ${response.statusCode}).',
        );
      }
      rethrow;
    }
    final data =
        decoded is Map
            ? Map<String, dynamic>.from(decoded)
            : <String, dynamic>{};
    if (response.statusCode >= 200 && response.statusCode < 300) return data;
    final errors = data['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty)
          throw ApiException(value.first.toString());
      }
    }
    throw ApiException(
      data['message']?.toString() ?? 'Catalog request failed.',
    );
  }
}
