import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'auth_service.dart';

class BookingService {
  BookingService._();

  static final BookingService instance = BookingService._();

  static const Duration _timeout = Duration(seconds: 20);

  // ============================================================
  // TOURIST BOOKINGS
  // ============================================================

  Future<List<BookingItem>> fetchTouristBookings() async {
    final data = await _request('GET', '/bookings');

    return _maps(data['bookings']).map(BookingItem.fromJson).toList();
  }

  // ============================================================
  // SAFARI PROVIDER BOOKINGS
  // ============================================================
  //
  // This endpoint still has /operator/ in its path for backwards
  // compatibility, but Laravel now allows both:
  //
  // - tourist_guide
  // - tour_operator
  //
  // ============================================================

  Future<List<BookingItem>> fetchProviderBookings() async {
    final data = await _request('GET', '/operator/bookings');

    return _maps(data['bookings']).map(BookingItem.fromJson).toList();
  }

  // ============================================================
  // LEGACY OPERATOR METHOD
  // ============================================================

  Future<List<BookingItem>> fetchOperatorBookings() async {
    return fetchProviderBookings();
  }

  // ============================================================
  // BOOKING DETAILS
  // ============================================================

  Future<BookingItem> fetchBooking(int bookingId) async {
    final data = await _request('GET', '/bookings/$bookingId');

    return _bookingFromResponse(data);
  }

  // ============================================================
  // SAFARI PROVIDER SUMMARY
  // ============================================================

  Future<ProviderBookingSummary> fetchProviderSummary() async {
    final data = await _request('GET', '/operator/booking-summary');

    final summary = data['summary'];

    if (summary is! Map) {
      return const ProviderBookingSummary();
    }

    return ProviderBookingSummary.fromJson(Map<String, dynamic>.from(summary));
  }

  // ============================================================
  // LEGACY OPERATOR SUMMARY
  // ============================================================

  Future<OperatorBookingSummary> fetchOperatorSummary() async {
    final summary = await fetchProviderSummary();

    return OperatorBookingSummary(
      totalBookings: summary.totalBookings,
      pendingBookings: summary.pendingBookings,
      confirmedBookings: summary.confirmedBookings,
      completedBookings: summary.completedBookings,
      cancelledBookings: summary.cancelledBookings,
      travellers: summary.travellers,
      bookingValue: summary.bookingValue,
      currency: summary.currency,
    );
  }

  // ============================================================
  // PROVIDER CONFIRM BOOKING
  // ============================================================

  Future<BookingItem> confirmBooking(int bookingId) async {
    final data = await _request(
      'POST',
      '/operator/bookings/$bookingId/confirm',
    );

    return _bookingFromResponse(data);
  }

  // ============================================================
  // PROVIDER COMPLETE BOOKING
  // ============================================================

  Future<BookingItem> completeBooking(int bookingId) async {
    final data = await _request(
      'POST',
      '/operator/bookings/$bookingId/complete',
    );

    return _bookingFromResponse(data);
  }

  // ============================================================
  // PROVIDER CANCEL BOOKING
  // ============================================================

  Future<BookingItem> cancelProviderBooking(int bookingId) async {
    final data = await _request('POST', '/operator/bookings/$bookingId/cancel');

    return _bookingFromResponse(data);
  }

  // ============================================================
  // LEGACY OPERATOR CANCEL
  // ============================================================

  Future<BookingItem> cancelOperatorBooking(int bookingId) async {
    return cancelProviderBooking(bookingId);
  }

  // ============================================================
  // TOURIST CANCEL BOOKING
  // ============================================================

  Future<BookingItem> cancelTouristBooking(int bookingId) async {
    final data = await _request('POST', '/bookings/$bookingId/cancel');

    return _bookingFromResponse(data);
  }

  // ============================================================
  // PROVIDER NOTES
  // ============================================================

  Future<BookingItem> updateProviderNotes({
    required int bookingId,
    required String notes,
  }) async {
    final data = await _request(
      'POST',
      '/operator/bookings/$bookingId/notes',
      body: {'provider_notes': notes},
    );

    return _bookingFromResponse(data);
  }

  // ============================================================
  // LEGACY OPERATOR NOTES
  // ============================================================

  Future<BookingItem> updateOperatorNotes({
    required int bookingId,
    required String notes,
  }) async {
    return updateProviderNotes(bookingId: bookingId, notes: notes);
  }

  // ============================================================
  // TOURIST NOTES
  // ============================================================

  Future<BookingItem> updateTouristNotes({
    required int bookingId,
    required String notes,
  }) async {
    final data = await _request(
      'POST',
      '/bookings/$bookingId/notes',
      body: {'tourist_notes': notes},
    );

    return _bookingFromResponse(data);
  }

  // ============================================================
  // OPERATOR -> TEAM GUIDE ASSIGNMENTS
  // ============================================================

  Future<List<EligibleTeamGuide>> fetchEligibleTeamGuides({
    required int bookingId,
    String query = '',
  }) async {
    final trimmed = query.trim();
    final path =
        trimmed.isEmpty
            ? '/operator/bookings/$bookingId/eligible-guides'
            : '/operator/bookings/$bookingId/eligible-guides?q=${Uri.encodeQueryComponent(trimmed)}';

    final data = await _request('GET', path);

    return _maps(data['guides']).map(EligibleTeamGuide.fromJson).toList();
  }

  Future<BookingGuideAssignmentItem?> fetchBookingGuideAssignment(
    int bookingId,
  ) async {
    final data = await _request(
      'GET',
      '/operator/bookings/$bookingId/guide-assignment',
    );

    final assignment = data['assignment'];

    if (assignment is! Map) {
      return null;
    }

    return BookingGuideAssignmentItem.fromJson(
      Map<String, dynamic>.from(assignment),
    );
  }

  Future<BookingGuideAssignmentItem> assignGuideToBooking({
    required int bookingId,
    required int guideUserId,
    String? assignmentNotes,
  }) async {
    final notes = assignmentNotes?.trim();

    final data = await _request(
      'POST',
      '/operator/bookings/$bookingId/guide-assignment',
      body: {
        'guide_user_id': guideUserId,
        if (notes != null && notes.isNotEmpty) 'assignment_notes': notes,
      },
    );

    return _assignmentFromResponse(data);
  }

  Future<BookingGuideAssignmentItem> cancelBookingGuideAssignment({
    required int bookingId,
    required int assignmentId,
  }) async {
    final data = await _request(
      'POST',
      '/operator/bookings/$bookingId/guide-assignment/$assignmentId/cancel',
    );

    return _assignmentFromResponse(data);
  }

  // ============================================================
  // GUIDE -> TEAM ASSIGNMENTS
  // ============================================================

  Future<List<BookingGuideAssignmentItem>> fetchGuideTeamAssignments() async {
    final data = await _request('GET', '/guide/team-assignments');

    return _maps(
      data['assignments'],
    ).map(BookingGuideAssignmentItem.fromJson).toList();
  }

  Future<BookingGuideAssignmentItem> fetchGuideTeamAssignment(
    int assignmentId,
  ) async {
    final data = await _request('GET', '/guide/team-assignments/$assignmentId');

    return _assignmentFromResponse(data);
  }

  Future<BookingGuideAssignmentItem> acceptGuideTeamAssignment(
    int assignmentId,
  ) async {
    final data = await _request(
      'POST',
      '/guide/team-assignments/$assignmentId/accept',
    );

    return _assignmentFromResponse(data);
  }

  Future<BookingGuideAssignmentItem> declineGuideTeamAssignment(
    int assignmentId,
  ) async {
    final data = await _request(
      'POST',
      '/guide/team-assignments/$assignmentId/decline',
    );

    return _assignmentFromResponse(data);
  }

  // ============================================================
  // RESPONSE PARSER
  // ============================================================

  BookingItem _bookingFromResponse(Map<String, dynamic> data) {
    final booking = data['booking'];

    if (booking is! Map) {
      throw const ApiException('Booking response was incomplete.');
    }

    return BookingItem.fromJson(Map<String, dynamic>.from(booking));
  }

  BookingGuideAssignmentItem _assignmentFromResponse(
    Map<String, dynamic> data,
  ) {
    final assignment = data['assignment'];

    if (assignment is! Map) {
      throw const ApiException('Guide assignment response was incomplete.');
    }

    return BookingGuideAssignmentItem.fromJson(
      Map<String, dynamic>.from(assignment),
    );
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
      final baseUrl = await AuthService.instance.resolveBaseUrl();

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
        'The booking service connection was interrupted.',
      );
    } on TimeoutException {
      throw const ApiException('The booking request timed out.');
    } on FormatException {
      throw const ApiException(
        'The booking service returned an unreadable response.',
      );
    } on http.ClientException {
      throw const ApiException('The booking request failed.');
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

// ==================================================================
// BOOKING ITEM
// ==================================================================

class BookingItem {
  const BookingItem({
    required this.id,
    required this.reference,
    required this.touristId,
    required this.providerId,
    required this.providerRole,
    required this.providerType,
    required this.title,
    required this.travellers,
    required this.totalAmount,
    required this.currency,
    required this.status,
    required this.paymentStatus,
    required this.tourist,
    required this.provider,
    required this.activities,
    required this.destinations,
    required this.moods,
    required this.inclusions,
    required this.exclusions,
    required this.proposedItinerary,
    this.safariRequestId,
    this.safariProposalId,
    this.startDate,
    this.endDate,
    this.providerNotes,
    this.touristNotes,
    this.vehicle,
    this.accommodationNotes,
    this.proposalMessage,
    this.days,
    this.accommodationLevel,
    this.transportPreference,
    this.confirmedAt,
    this.cancelledAt,
    this.completedAt,
    this.createdAt,
  });

  final int id;

  final String reference;

  final int touristId;

  final int providerId;

  final String providerRole;

  final String providerType;

  final int? safariRequestId;

  final int? safariProposalId;

  final String title;

  final String? startDate;

  final String? endDate;

  final int travellers;

  final double totalAmount;

  final String currency;

  final String status;

  final String paymentStatus;

  final String? providerNotes;

  final String? touristNotes;

  final BookingPerson tourist;

  final BookingPerson provider;

  final int? days;

  final String? accommodationLevel;

  final String? transportPreference;

  final List<BookingReferenceItem> activities;

  final List<BookingReferenceItem> destinations;

  final List<BookingReferenceItem> moods;

  final String? vehicle;

  final String? accommodationNotes;

  final String? proposalMessage;

  final List<String> inclusions;

  final List<String> exclusions;

  final List<Map<String, dynamic>> proposedItinerary;

  final String? confirmedAt;

  final String? cancelledAt;

  final String? completedAt;

  final String? createdAt;

  // ============================================================
  // BOOKING STATUS
  // ============================================================

  bool get isPending => status == 'pending';

  bool get isConfirmed => status == 'confirmed';

  bool get isCompleted => status == 'completed';

  bool get isCancelled => status == 'cancelled';

  // ============================================================
  // PROVIDER TYPE
  // ============================================================

  bool get isTouristGuide => providerRole == 'tourist_guide';

  bool get isTourOperator => providerRole == 'tour_operator';

  // ============================================================
  // LEGACY OPERATOR GETTERS
  // ============================================================
  //
  // Existing operator pages can continue using:
  //
  // booking.operatorId
  // booking.operator
  // booking.operatorNotes
  //
  // ============================================================

  int get operatorId => providerId;

  BookingPerson get operator => provider;

  String? get operatorNotes => providerNotes;

  factory BookingItem.fromJson(Map<String, dynamic> json) {
    final touristData = json['tourist'];

    final providerData = json['provider'];

    final operatorData = json['operator'];

    final safariRequestData = json['safari_request'];

    final proposalData = json['proposal'];

    final safariRequest =
        safariRequestData is Map
            ? Map<String, dynamic>.from(safariRequestData)
            : <String, dynamic>{};

    final proposal =
        proposalData is Map
            ? Map<String, dynamic>.from(proposalData)
            : <String, dynamic>{};

    final rawProvider =
        providerData is Map
            ? Map<String, dynamic>.from(providerData)
            : operatorData is Map
            ? Map<String, dynamic>.from(operatorData)
            : <String, dynamic>{};

    final role =
        json['provider_role']?.toString() ??
        rawProvider['role']?.toString() ??
        '';

    final providerType =
        json['provider_type']?.toString() ??
        rawProvider['type']?.toString() ??
        (role == 'tourist_guide' ? 'Tourist Guide' : 'Tour Operator');

    return BookingItem(
      id: _int(json['id']),

      reference: json['reference']?.toString() ?? '',

      touristId: _int(json['tourist_id']),

      providerId: _int(json['provider_id'] ?? json['operator_id']),

      providerRole: role,

      providerType: providerType,

      safariRequestId:
          json['safari_request_id'] == null
              ? null
              : _int(json['safari_request_id']),

      safariProposalId:
          json['safari_proposal_id'] == null
              ? null
              : _int(json['safari_proposal_id']),

      title: json['title']?.toString() ?? '',

      startDate: json['start_date']?.toString(),

      endDate: json['end_date']?.toString(),

      travellers: _int(json['travellers'], fallback: 1),

      totalAmount: _double(json['total_amount']),

      currency: json['currency']?.toString() ?? 'USD',

      status: json['status']?.toString() ?? 'pending',

      paymentStatus: json['payment_status']?.toString() ?? 'unpaid',

      providerNotes:
          json['provider_notes']?.toString() ??
          json['operator_notes']?.toString(),

      touristNotes: json['tourist_notes']?.toString(),

      tourist:
          touristData is Map
              ? BookingPerson.fromJson(Map<String, dynamic>.from(touristData))
              : const BookingPerson(),

      provider:
          rawProvider.isNotEmpty
              ? BookingPerson.fromJson(rawProvider)
              : BookingPerson(
                id: _int(json['provider_id'] ?? json['operator_id']),
                name:
                    json['provider_name']?.toString() ??
                    json['operator_name']?.toString() ??
                    '',
                role: role,
                type: providerType,
                profilePhoto: json['provider_photo']?.toString() ?? '',
              ),

      days: safariRequest['days'] == null ? null : _int(safariRequest['days']),

      accommodationLevel: safariRequest['accommodation_level']?.toString(),

      transportPreference: safariRequest['transport_preference']?.toString(),

      activities:
          _mapList(
            safariRequest['activities'],
          ).map(BookingReferenceItem.fromJson).toList(),

      destinations:
          _mapList(
            safariRequest['destinations'],
          ).map(BookingReferenceItem.fromJson).toList(),

      moods:
          _mapList(
            safariRequest['moods'],
          ).map(BookingReferenceItem.fromJson).toList(),

      vehicle: proposal['vehicle']?.toString(),

      accommodationNotes: proposal['accommodation_notes']?.toString(),

      proposalMessage: proposal['message']?.toString(),

      inclusions: _stringList(proposal['inclusions']),

      exclusions: _stringList(proposal['exclusions']),

      proposedItinerary: _mapList(proposal['proposed_itinerary']),

      confirmedAt: json['confirmed_at']?.toString(),

      cancelledAt: json['cancelled_at']?.toString(),

      completedAt: json['completed_at']?.toString(),

      createdAt: json['created_at']?.toString(),
    );
  }
}

// ==================================================================
// BOOKING PERSON / PROVIDER
// ==================================================================

class BookingPerson {
  const BookingPerson({
    this.id = 0,
    this.name = '',
    this.profilePhoto = '',
    this.role = '',
    this.type = '',
  });

  final int id;

  final String name;

  final String profilePhoto;

  final String role;

  final String type;

  bool get isTouristGuide => role == 'tourist_guide';

  bool get isTourOperator => role == 'tour_operator';

  factory BookingPerson.fromJson(Map<String, dynamic> json) {
    return BookingPerson(
      id: _int(json['id']),

      name: json['name']?.toString() ?? '',

      profilePhoto: json['profile_photo']?.toString() ?? '',

      role: json['role']?.toString() ?? '',

      type: json['type']?.toString() ?? '',
    );
  }
}

// ==================================================================
// BOOKING REFERENCE ITEM
// ==================================================================

class BookingReferenceItem {
  const BookingReferenceItem({
    required this.id,
    required this.name,
    required this.slug,
  });

  final int id;

  final String name;

  final String slug;

  factory BookingReferenceItem.fromJson(Map<String, dynamic> json) {
    return BookingReferenceItem(
      id: _int(json['id']),

      name: json['name']?.toString() ?? '',

      slug: json['slug']?.toString() ?? '',
    );
  }
}

// ==================================================================
// PROVIDER BOOKING SUMMARY
// ==================================================================

class ProviderBookingSummary {
  const ProviderBookingSummary({
    this.totalBookings = 0,
    this.pendingBookings = 0,
    this.confirmedBookings = 0,
    this.completedBookings = 0,
    this.cancelledBookings = 0,
    this.travellers = 0,
    this.bookingValue = 0,
    this.currency = 'USD',
  });

  final int totalBookings;

  final int pendingBookings;

  final int confirmedBookings;

  final int completedBookings;

  final int cancelledBookings;

  final int travellers;

  final double bookingValue;

  final String currency;

  factory ProviderBookingSummary.fromJson(Map<String, dynamic> json) {
    return ProviderBookingSummary(
      totalBookings: _int(json['total_bookings']),

      pendingBookings: _int(json['pending_bookings']),

      confirmedBookings: _int(json['confirmed_bookings']),

      completedBookings: _int(json['completed_bookings']),

      cancelledBookings: _int(json['cancelled_bookings']),

      travellers: _int(json['travellers']),

      bookingValue: _double(json['booking_value']),

      currency: json['currency']?.toString() ?? 'USD',
    );
  }
}

// ==================================================================
// LEGACY OPERATOR SUMMARY
// ==================================================================
//
// Existing TourOperatorHomePage currently uses this class.
// Keep it while we introduce ProviderBookingSummary.
//
// ==================================================================

class OperatorBookingSummary extends ProviderBookingSummary {
  const OperatorBookingSummary({
    super.totalBookings = 0,
    super.pendingBookings = 0,
    super.confirmedBookings = 0,
    super.completedBookings = 0,
    super.cancelledBookings = 0,
    super.travellers = 0,
    super.bookingValue = 0,
    super.currency = 'USD',
  });

  factory OperatorBookingSummary.fromJson(Map<String, dynamic> json) {
    final summary = ProviderBookingSummary.fromJson(json);

    return OperatorBookingSummary(
      totalBookings: summary.totalBookings,
      pendingBookings: summary.pendingBookings,
      confirmedBookings: summary.confirmedBookings,
      completedBookings: summary.completedBookings,
      cancelledBookings: summary.cancelledBookings,
      travellers: summary.travellers,
      bookingValue: summary.bookingValue,
      currency: summary.currency,
    );
  }
}

// ==================================================================
// TEAM ASSIGNMENT MODELS
// ==================================================================

class EligibleTeamGuide {
  const EligibleTeamGuide({
    required this.id,
    required this.name,
    required this.role,
    required this.profilePhoto,
    required this.country,
    required this.languages,
    required this.yearsExperience,
    required this.verificationStatus,
  });

  final int id;
  final String name;
  final String role;
  final String profilePhoto;
  final String country;
  final List<String> languages;
  final int yearsExperience;
  final String verificationStatus;

  bool get isVerified => verificationStatus == 'verified';

  factory EligibleTeamGuide.fromJson(Map<String, dynamic> json) {
    return EligibleTeamGuide(
      id: _int(json['id']),
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      profilePhoto: json['profile_photo']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      languages: _stringList(json['languages']),
      yearsExperience: _int(json['years_experience']),
      verificationStatus: json['verification_status']?.toString() ?? 'pending',
    );
  }
}

class BookingGuideAssignmentItem {
  const BookingGuideAssignmentItem({
    required this.id,
    required this.bookingId,
    required this.operatorUserId,
    required this.guideUserId,
    required this.status,
    this.assignmentNotes,
    this.assignedAt,
    this.respondedAt,
    this.cancelledAt,
    this.operator,
    this.guide,
    this.booking,
  });

  final int id;
  final int bookingId;
  final int operatorUserId;
  final int guideUserId;
  final String status;
  final String? assignmentNotes;
  final String? assignedAt;
  final String? respondedAt;
  final String? cancelledAt;
  final TeamAssignmentOperator? operator;
  final EligibleTeamGuide? guide;
  final TeamAssignmentBooking? booking;

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
  bool get isCancelled => status == 'cancelled';
  bool get isOpen => isPending || isAccepted;

  factory BookingGuideAssignmentItem.fromJson(Map<String, dynamic> json) {
    final operatorData = json['operator'];
    final guideData = json['guide'];
    final bookingData = json['booking'];

    return BookingGuideAssignmentItem(
      id: _int(json['id']),
      bookingId: _int(json['booking_id']),
      operatorUserId: _int(json['operator_user_id']),
      guideUserId: _int(json['guide_user_id']),
      status: json['status']?.toString() ?? 'pending',
      assignmentNotes: json['assignment_notes']?.toString(),
      assignedAt: json['assigned_at']?.toString(),
      respondedAt: json['responded_at']?.toString(),
      cancelledAt: json['cancelled_at']?.toString(),
      operator:
          operatorData is Map
              ? TeamAssignmentOperator.fromJson(
                Map<String, dynamic>.from(operatorData),
              )
              : null,
      guide:
          guideData is Map
              ? EligibleTeamGuide.fromJson(Map<String, dynamic>.from(guideData))
              : null,
      booking:
          bookingData is Map
              ? TeamAssignmentBooking.fromJson(
                Map<String, dynamic>.from(bookingData),
              )
              : null,
    );
  }
}

class TeamAssignmentOperator {
  const TeamAssignmentOperator({
    required this.id,
    required this.name,
    required this.profilePhoto,
    required this.country,
  });

  final int id;
  final String name;
  final String profilePhoto;
  final String country;

  factory TeamAssignmentOperator.fromJson(Map<String, dynamic> json) {
    return TeamAssignmentOperator(
      id: _int(json['id']),
      name: json['name']?.toString() ?? '',
      profilePhoto: json['profile_photo']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
    );
  }
}

class TeamAssignmentBooking {
  const TeamAssignmentBooking({
    required this.id,
    required this.reference,
    required this.title,
    required this.travellers,
    required this.status,
    required this.paymentStatus,
    required this.currency,
    this.startDate,
    this.endDate,
    this.tourist,
    this.safariRequest,
  });

  final int id;
  final String reference;
  final String title;
  final String? startDate;
  final String? endDate;
  final int travellers;
  final String status;
  final String paymentStatus;
  final String currency;
  final TeamAssignmentTourist? tourist;
  final TeamAssignmentSafariRequest? safariRequest;

  factory TeamAssignmentBooking.fromJson(Map<String, dynamic> json) {
    final touristData = json['tourist'];
    final safariRequestData = json['safari_request'];

    return TeamAssignmentBooking(
      id: _int(json['id']),
      reference: json['reference']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      travellers: _int(json['travellers'], fallback: 1),
      status: json['status']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'USD',
      tourist:
          touristData is Map
              ? TeamAssignmentTourist.fromJson(
                Map<String, dynamic>.from(touristData),
              )
              : null,
      safariRequest:
          safariRequestData is Map
              ? TeamAssignmentSafariRequest.fromJson(
                Map<String, dynamic>.from(safariRequestData),
              )
              : null,
    );
  }
}

class TeamAssignmentTourist {
  const TeamAssignmentTourist({
    required this.id,
    required this.name,
    required this.profilePhoto,
  });

  final int id;
  final String name;
  final String profilePhoto;

  factory TeamAssignmentTourist.fromJson(Map<String, dynamic> json) {
    return TeamAssignmentTourist(
      id: _int(json['id']),
      name: json['name']?.toString() ?? '',
      profilePhoto: json['profile_photo']?.toString() ?? '',
    );
  }
}

class TeamAssignmentSafariRequest {
  const TeamAssignmentSafariRequest({
    required this.id,
    required this.days,
    required this.activities,
    required this.destinations,
  });

  final int id;
  final int? days;
  final List<BookingReferenceItem> activities;
  final List<BookingReferenceItem> destinations;

  factory TeamAssignmentSafariRequest.fromJson(Map<String, dynamic> json) {
    return TeamAssignmentSafariRequest(
      id: _int(json['id']),
      days: json['days'] == null ? null : _int(json['days']),
      activities:
          _mapList(
            json['activities'],
          ).map(BookingReferenceItem.fromJson).toList(),
      destinations:
          _mapList(
            json['destinations'],
          ).map(BookingReferenceItem.fromJson).toList(),
    );
  }
}

// ==================================================================
// HELPERS
// ==================================================================

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
