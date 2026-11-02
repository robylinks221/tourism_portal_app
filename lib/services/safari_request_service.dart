import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../services/api_exception.dart';
import '../services/auth_service.dart';

class SafariRequestService {
  SafariRequestService._();

  static final SafariRequestService instance = SafariRequestService._();

  static const Duration _timeout = Duration(seconds: 20);

  // ============================================================
  // TOURIST: LIST OWN REQUESTS
  // ============================================================

  Future<List<SafariRequestItem>> fetchMyRequests() async {
    final data = await _request('GET', '/safari-requests');

    return _maps(data['requests']).map(SafariRequestItem.fromJson).toList();
  }

  // ============================================================
  // TOURIST: FETCH SINGLE REQUEST
  // ============================================================

  Future<SafariRequestItem> fetchRequest(int requestId) async {
    final data = await _request('GET', '/safari-requests/$requestId');

    final item = data['request'];

    if (item is! Map) {
      throw const ApiException('Safari request could not be loaded.');
    }

    return SafariRequestItem.fromJson(Map<String, dynamic>.from(item));
  }

  // ============================================================
  // TOURIST: CREATE SAFARI DRAFT
  // ============================================================

  Future<SafariRequestItem> createRequest({
    required String title,
    required int travellers,
    String requestType = 'build',
    int? originalTourId,
    String? startDate,
    String? endDate,
    int? days,
    double? budgetMin,
    double? budgetMax,
    String currency = 'USD',
    String? accommodationLevel,
    String? transportPreference,
    String? notes,
    List<Map<String, dynamic>>? generatedItinerary,
    List<int> activityIds = const [],
    List<int> destinationIds = const [],
    List<int> moodIds = const [],
  }) async {
    final data = await _request(
      'POST',
      '/safari-requests',
      body: {
        'request_type': requestType,
        'original_tour_id': originalTourId,
        'title': title,
        'start_date': startDate,
        'end_date': endDate,
        'days': days,
        'travellers': travellers,
        'budget_min': budgetMin,
        'budget_max': budgetMax,
        'currency': currency,
        'accommodation_level': accommodationLevel,
        'transport_preference': transportPreference,
        'notes': notes,
        'generated_itinerary': generatedItinerary,
        'activity_ids': activityIds,
        'destination_ids': destinationIds,
        'mood_ids': moodIds,
      },
    );

    final item = data['request'];

    if (item is! Map) {
      throw const ApiException('Safari draft could not be created.');
    }

    return SafariRequestItem.fromJson(Map<String, dynamic>.from(item));
  }

  // ============================================================
  // TOURIST: SUBMIT FOR QUOTES
  // ============================================================

  Future<SafariRequestSubmissionResult> submitRequest(int requestId) async {
    final data = await _request('POST', '/safari-requests/$requestId/submit');

    final requestData = data['request'];

    if (requestData is! Map) {
      throw const ApiException('Safari request could not be submitted.');
    }

    /*
    |--------------------------------------------------------------------------
    | New Laravel response
    |--------------------------------------------------------------------------
    |
    | matching_providers contains:
    |
    | - tourist guides
    | - tour operators
    |
    | We still fall back to matching_operators for older API responses.
    |
    */

    final rawMatches = data['matching_providers'] ?? data['matching_operators'];

    final matches =
        _maps(rawMatches).map(SafariProviderMatch.fromJson).toList();

    return SafariRequestSubmissionResult(
      request: SafariRequestItem.fromJson(
        Map<String, dynamic>.from(requestData),
      ),
      matchingProviders: matches,
    );
  }

  // ============================================================
  // TOURIST: MATCHING PROVIDERS
  // ============================================================

  Future<List<SafariProviderMatch>> fetchMatches(int requestId) async {
    final data = await _request('GET', '/safari-requests/$requestId/matches');

    final rawProviders = data['providers'] ?? data['operators'];

    return _maps(rawProviders).map(SafariProviderMatch.fromJson).toList();
  }

  // ============================================================
  // TOURIST: ACCEPT PROPOSAL
  // ============================================================

  Future<SafariProposalItem> acceptProposal({
    required int requestId,
    required int proposalId,
  }) async {
    final data = await _request(
      'POST',
      '/safari-requests/$requestId/proposals/$proposalId/accept',
    );

    final proposal = data['proposal'];

    if (proposal is! Map) {
      throw const ApiException('Proposal could not be accepted.');
    }

    return SafariProposalItem.fromJson(Map<String, dynamic>.from(proposal));
  }

  // ============================================================
  // TOURIST: CANCEL REQUEST
  // ============================================================

  Future<void> cancelRequest(int requestId) async {
    await _request('POST', '/safari-requests/$requestId/cancel');
  }

  // ============================================================
  // SAFARI PROVIDER: MATCHING REQUESTS
  // ============================================================
  //
  // This endpoint still uses /operator/... for backward
  // compatibility in Laravel, but it now works for:
  //
  // - tourist_guide
  // - tour_operator
  //
  // ============================================================

  Future<List<SafariRequestItem>> fetchProviderRequests() async {
    final data = await _request('GET', '/operator/safari-requests');

    return _maps(data['requests']).map(SafariRequestItem.fromJson).toList();
  }

  // ============================================================
  // LEGACY NAME
  // ============================================================
  //
  // Existing Flutter pages may already call this.
  //
  // Keep it so nothing breaks.
  //
  // ============================================================

  Future<List<SafariRequestItem>> fetchOperatorRequests() async {
    return fetchProviderRequests();
  }

  // ============================================================
  // SAFARI PROVIDER: SUBMIT PROPOSAL
  // ============================================================

  Future<SafariProposalItem> submitProposal({
    required int requestId,
    required double price,
    String currency = 'USD',
    String? message,
    String? vehicle,
    String? accommodationNotes,
    List<String> inclusions = const [],
    List<String> exclusions = const [],
    List<Map<String, dynamic>> proposedItinerary = const [],
  }) async {
    final data = await _request(
      'POST',
      '/operator/safari-requests/$requestId/proposal',
      body: {
        'price': price,
        'currency': currency,
        'message': message,
        'vehicle': vehicle,
        'accommodation_notes': accommodationNotes,
        'inclusions': inclusions,
        'exclusions': exclusions,
        'proposed_itinerary': proposedItinerary,
      },
    );

    final proposal = data['proposal'];

    if (proposal is! Map) {
      throw const ApiException('Proposal could not be submitted.');
    }

    return SafariProposalItem.fromJson(Map<String, dynamic>.from(proposal));
  }

  // ============================================================
  // REQUEST HANDLER
  // ============================================================

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final baseUrl = await AuthService.instance.resolveFeatureBaseUrl();

      final token = await AuthService.instance.requireToken();

      final uri = Uri.parse('$baseUrl$path');

      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      late http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(_timeout);

          break;

        case 'POST':
          response = await http
              .post(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(_timeout);

          break;

        case 'PUT':
          response = await http
              .put(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(_timeout);

          break;

        default:
          throw ApiException('Unsupported request method: $method');
      }

      final decoded =
          response.body.trim().isEmpty
              ? <String, dynamic>{}
              : jsonDecode(response.body);

      final data =
          decoded is Map
              ? Map<String, dynamic>.from(decoded)
              : <String, dynamic>{};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }

      throw ApiException(
        _message(data, response.statusCode),
        statusCode: response.statusCode,
      );
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException(
        'The safari service connection was interrupted.',
      );
    } on TimeoutException {
      throw const ApiException('The safari request timed out.');
    } on FormatException {
      throw const ApiException(
        'The safari service returned an unreadable response.',
      );
    } on http.ClientException {
      throw const ApiException('The safari service request failed.');
    }
  }

  static List<Map<String, dynamic>> _maps(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
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

    return data['message']?.toString() ?? 'Request failed (HTTP $statusCode).';
  }
}

// ================================================================
// SAFARI REQUEST
// ================================================================

class SafariRequestItem {
  const SafariRequestItem({
    required this.id,
    required this.touristId,
    required this.requestType,
    required this.title,
    required this.status,
    required this.travellers,
    required this.currency,
    required this.activities,
    required this.destinations,
    required this.moods,
    required this.proposals,
    required this.proposalCount,
    required this.matchPercentage,
    this.originalTourId,
    this.startDate,
    this.endDate,
    this.days,
    this.budgetMin,
    this.budgetMax,
    this.accommodationLevel,
    this.transportPreference,
    this.notes,
    this.generatedItinerary = const [],
    this.acceptedProposal,
    this.myProposal,
  });

  final int id;
  final int touristId;

  final int? originalTourId;

  final String requestType;
  final String title;
  final String status;

  final String? startDate;
  final String? endDate;

  final int? days;
  final int travellers;

  final double? budgetMin;
  final double? budgetMax;

  final String currency;

  final String? accommodationLevel;
  final String? transportPreference;

  final String? notes;

  final List<Map<String, dynamic>> generatedItinerary;

  final List<SafariReferenceItem> activities;

  final List<SafariReferenceItem> destinations;

  final List<SafariReferenceItem> moods;

  final List<SafariProposalItem> proposals;

  final SafariProposalItem? acceptedProposal;

  final SafariProposalItem? myProposal;

  final int proposalCount;

  final int matchPercentage;

  factory SafariRequestItem.fromJson(Map<String, dynamic> json) {
    final accepted = json['accepted_proposal'];

    final myProposal = json['my_proposal'];

    return SafariRequestItem(
      id: _int(json['id']),

      touristId: _int(json['tourist_id']),

      originalTourId:
          json['original_tour_id'] == null
              ? null
              : _int(json['original_tour_id']),

      requestType: json['request_type']?.toString() ?? 'build',

      title: json['title']?.toString() ?? '',

      status: json['status']?.toString() ?? '',

      startDate: json['start_date']?.toString(),

      endDate: json['end_date']?.toString(),

      days: json['days'] == null ? null : _int(json['days']),

      travellers: _int(json['travellers'], fallback: 1),

      budgetMin: _doubleNullable(json['budget_min']),

      budgetMax: _doubleNullable(json['budget_max']),

      currency: json['currency']?.toString() ?? 'USD',

      accommodationLevel: json['accommodation_level']?.toString(),

      transportPreference: json['transport_preference']?.toString(),

      notes: json['notes']?.toString(),

      generatedItinerary: _mapList(json['generated_itinerary']),

      activities:
          _mapList(
            json['activities'],
          ).map(SafariReferenceItem.fromJson).toList(),

      destinations:
          _mapList(
            json['destinations'],
          ).map(SafariReferenceItem.fromJson).toList(),

      moods: _mapList(json['moods']).map(SafariReferenceItem.fromJson).toList(),

      proposals:
          _mapList(json['proposals']).map(SafariProposalItem.fromJson).toList(),

      acceptedProposal:
          accepted is Map
              ? SafariProposalItem.fromJson(Map<String, dynamic>.from(accepted))
              : null,

      myProposal:
          myProposal is Map
              ? SafariProposalItem.fromJson(
                Map<String, dynamic>.from(myProposal),
              )
              : null,

      proposalCount: _int(json['proposal_count']),

      matchPercentage: _int(json['match_percentage']),
    );
  }
}

// ================================================================
// SAFARI PROPOSAL
// ================================================================

class SafariProposalItem {
  const SafariProposalItem({
    required this.id,
    required this.requestId,
    required this.providerId,
    required this.providerRole,
    required this.providerType,
    required this.providerName,
    required this.providerLogo,
    required this.price,
    required this.currency,
    required this.status,
    required this.inclusions,
    required this.exclusions,
    required this.proposedItinerary,
    this.message,
    this.vehicle,
    this.accommodationNotes,
  });

  final int id;

  final int requestId;

  final int providerId;

  final String providerRole;

  final String providerType;

  final String providerName;

  final String providerLogo;

  final double price;

  final String currency;

  final String status;

  final String? message;

  final String? vehicle;

  final String? accommodationNotes;

  final List<String> inclusions;

  final List<String> exclusions;

  final List<Map<String, dynamic>> proposedItinerary;

  // ============================================================
  // PROVIDER TYPE HELPERS
  // ============================================================

  bool get isTouristGuide => providerRole == 'tourist_guide';

  bool get isTourOperator => providerRole == 'tour_operator';

  // ============================================================
  // LEGACY GETTERS
  // ============================================================
  //
  // Existing pages may still refer to operatorId,
  // operatorName and operatorLogo.
  //
  // These aliases prevent those pages from breaking.
  //
  // ============================================================

  int get operatorId => providerId;

  String get operatorName => providerName;

  String get operatorLogo => providerLogo;

  factory SafariProposalItem.fromJson(Map<String, dynamic> json) {
    final providerId = _int(json['provider_id'] ?? json['operator_id']);

    final providerRole = json['provider_role']?.toString() ?? '';

    final providerType =
        json['provider_type']?.toString() ??
        (providerRole == 'tourist_guide' ? 'Tourist Guide' : 'Tour Operator');

    return SafariProposalItem(
      id: _int(json['id']),

      requestId: _int(json['safari_request_id']),

      providerId: providerId,

      providerRole: providerRole,

      providerType: providerType,

      providerName:
          json['provider_name']?.toString() ??
          json['operator_name']?.toString() ??
          '',

      providerLogo:
          json['provider_logo']?.toString() ??
          json['operator_logo']?.toString() ??
          '',

      price: _double(json['price']),

      currency: json['currency']?.toString() ?? 'USD',

      status: json['status']?.toString() ?? 'pending',

      message: json['message']?.toString(),

      vehicle: json['vehicle']?.toString(),

      accommodationNotes: json['accommodation_notes']?.toString(),

      inclusions: _stringList(json['inclusions']),

      exclusions: _stringList(json['exclusions']),

      proposedItinerary: _mapList(json['proposed_itinerary']),
    );
  }
}

// ================================================================
// SAFARI PROVIDER MATCH
// ================================================================

class SafariProviderMatch {
  const SafariProviderMatch({
    required this.id,
    required this.providerId,
    required this.providerRole,
    required this.providerType,
    required this.name,
    required this.profilePhoto,
    required this.country,
    required this.location,
    required this.ratingAverage,
    required this.ratingCount,
    required this.publishedToursCount,
    required this.verificationStatus,
    required this.matchPercentage,
  });

  final int id;

  final int providerId;

  final String providerRole;

  final String providerType;

  final String name;

  final String profilePhoto;

  final String country;

  final String location;

  final double ratingAverage;

  final int ratingCount;

  final int publishedToursCount;

  final String verificationStatus;

  final int matchPercentage;

  bool get isTouristGuide => providerRole == 'tourist_guide';

  bool get isTourOperator => providerRole == 'tour_operator';

  factory SafariProviderMatch.fromJson(Map<String, dynamic> json) {
    final role = json['provider_role']?.toString() ?? '';

    return SafariProviderMatch(
      id: _int(json['id']),

      providerId: _int(json['provider_id'] ?? json['id']),

      providerRole: role,

      providerType:
          json['provider_type']?.toString() ??
          (role == 'tourist_guide' ? 'Tourist Guide' : 'Tour Operator'),

      name: json['name']?.toString() ?? '',

      profilePhoto: json['profile_photo']?.toString() ?? '',

      country: json['country']?.toString() ?? '',

      location: json['location']?.toString() ?? '',

      ratingAverage: _double(json['rating_average']),

      ratingCount: _int(json['rating_count']),

      publishedToursCount: _int(json['published_tours_count']),

      verificationStatus: json['verification_status']?.toString() ?? 'pending',

      matchPercentage: _int(json['match_percentage']),
    );
  }
}

// ================================================================
// LEGACY TYPE ALIAS
// ================================================================
//
// Existing pages may still use SafariOperatorMatch.
// They will continue compiling while we migrate the UI.
//
// ================================================================

typedef SafariOperatorMatch = SafariProviderMatch;

// ================================================================
// REFERENCE ITEM
// ================================================================

class SafariReferenceItem {
  const SafariReferenceItem({
    required this.id,
    required this.name,
    required this.slug,
  });

  final int id;

  final String name;

  final String slug;

  factory SafariReferenceItem.fromJson(Map<String, dynamic> json) {
    return SafariReferenceItem(
      id: _int(json['id']),

      name: json['name']?.toString() ?? '',

      slug: json['slug']?.toString() ?? '',
    );
  }
}

// ================================================================
// SUBMISSION RESULT
// ================================================================

class SafariRequestSubmissionResult {
  const SafariRequestSubmissionResult({
    required this.request,
    required this.matchingProviders,
  });

  final SafariRequestItem request;

  final List<SafariProviderMatch> matchingProviders;

  /*
  |--------------------------------------------------------------------------
  | Legacy getter
  |--------------------------------------------------------------------------
  |
  | Existing pages using matchingOperators continue working.
  |
  */

  List<SafariProviderMatch> get matchingOperators => matchingProviders;
}

// ================================================================
// HELPERS
// ================================================================

int _int(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _double(dynamic value, {double fallback = 0}) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

double? _doubleNullable(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

List<String> _stringList(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value.map((item) => item.toString()).toList();
}
