import '../services/auth_service.dart';

class TourItineraryStop {
  const TourItineraryStop({
    required this.day,
    this.endDay,
    required this.title,
    required this.description,
  });

  final int day;
  final int? endDay;
  final String title;
  final String description;

  factory TourItineraryStop.fromJson(Map<String, dynamic> json) {
    return TourItineraryStop(
      day: _integer(json['day']),
      endDay: _integer(json['end_day'] ?? json['day']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

class OperatorTour {
  const OperatorTour({
    required this.id,
    required this.name,
    required this.image,
    required this.days,
    required this.overview,
    required this.price,
    required this.currency,
    required this.isActive,
    required this.activityIds,
    required this.destinationIds,
    required this.activityNames,
    required this.destinationNames,
    this.countryNames = const [],
    this.countryCount = 0,
    this.isMultiCountry = false,
    this.moods = const [],
    this.moodIds = const [],
    this.itinerary = const [],
    this.gallery = const [],
    this.inclusions = const [],
    this.exclusions = const [],
    this.operatorId = 0,
    this.providerRole = 'tour_operator',
    this.operatorName = '',
    this.operatorLogo = '',
    this.operatorLocation = '',
    this.operatorBiography = '',
    this.operatorRatingAverage = 0,
    this.operatorRatingCount = 0,
    this.operatorJoinedAt,
    this.operatorVerificationStatus = 'pending',
    this.operatorVerifiedAt,
    this.operatorResponseTimeMinutes,
    this.operatorYearsExperience = 0,
  });

  final int id;
  final String name;
  final String image;
  final int days;
  final String overview;
  final double price;
  final String currency;
  final bool isActive;
  final List<int> activityIds;
  final List<int> destinationIds;
  final List<String> activityNames;
  final List<String> destinationNames;
  final List<String> countryNames;
  final int countryCount;
  final bool isMultiCountry;
  final List<String> moods;
  final List<int> moodIds;
  final List<TourItineraryStop> itinerary;
  final List<String> gallery;
  List<String> get galleryUrls {
    final values = <String>[image, ...gallery];
    final result = <String>[];
    for (final value in values) {
      final url = AuthService.storageUrl(value);
      if (url.isNotEmpty && !result.contains(url)) result.add(url);
    }
    return result.take(3).toList();
  }
  final List<String> inclusions;
  final List<String> exclusions;
  final int operatorId;
  final String providerRole;
  final String operatorName;
  final String operatorLogo;
  final String operatorLocation;
  final String operatorBiography;
  final double operatorRatingAverage;
  final int operatorRatingCount;
  final DateTime? operatorJoinedAt;
  final String operatorVerificationStatus;
  final DateTime? operatorVerifiedAt;
  final int? operatorResponseTimeMinutes;
  final int operatorYearsExperience;

  String get imageUrl => AuthService.storageUrl(image);
  String get operatorLogoUrl => AuthService.storageUrl(operatorLogo);
  bool get isGuideLed => providerRole == 'tourist_guide';

  String get countryLabel {
    if (countryNames.isEmpty) return '';
    return countryNames.join(' • ');
  }

  bool get isOperatorVerified =>
      operatorVerificationStatus == 'verified' && operatorVerifiedAt != null;

  factory OperatorTour.fromJson(Map<String, dynamic> json) {
    final activities = _mapList(json['activities']);
    final destinations = _mapList(json['destinations']);

    return OperatorTour(
      id: _integer(json['id']),
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      days: _integer(json['days']),
      overview: json['overview']?.toString() ?? '',
      price: _number(json['price']),
      currency: json['currency']?.toString() ?? 'USD',
      isActive: _boolean(json['is_active']),
      activityIds: activities.map((item) => _integer(item['id'])).toList(),
      destinationIds: destinations.map((item) => _integer(item['id'])).toList(),
      activityNames:
          activities
              .map((item) => item['name']?.toString() ?? '')
              .where((name) => name.isNotEmpty)
              .toList(),
      destinationNames:
          destinations
              .map((item) => item['name']?.toString() ?? '')
              .where((name) => name.isNotEmpty)
              .toList(),
      countryNames: _strings(json['country_names']),
      countryCount: _integer(json['country_count']),
      isMultiCountry: _boolean(json['is_multi_country']),
      moods: _strings(json['moods']),
      moodIds: _integers(json['mood_ids']),
      gallery: _galleryStrings(json['gallery'] ?? json['images'] ?? json['photos']),
      itinerary:
          _mapList(json['itinerary']).map(TourItineraryStop.fromJson).toList()
            ..sort((first, second) => first.day.compareTo(second.day)),
      inclusions: _strings(json['inclusions']),
      exclusions: _strings(json['exclusions']),
      operatorId: _integer(json['operator_id']),
      providerRole: json['provider_role']?.toString() ?? 'tour_operator',
      operatorName: json['operator_name']?.toString() ?? '',
      operatorLogo: json['operator_logo']?.toString() ?? '',
      operatorLocation: json['operator_location']?.toString() ?? '',
      operatorBiography: json['operator_biography']?.toString() ?? '',
      operatorRatingAverage: _number(json['operator_rating_average']),
      operatorRatingCount: _integer(json['operator_rating_count']),
      operatorJoinedAt: DateTime.tryParse(
        json['operator_joined_at']?.toString() ?? '',
      ),
      operatorVerificationStatus:
          json['operator_verification_status']?.toString() ?? 'pending',
      operatorVerifiedAt: DateTime.tryParse(
        json['operator_verified_at']?.toString() ?? '',
      ),
      operatorResponseTimeMinutes: _nullableInteger(
        json['operator_response_time_minutes'],
      ),
      operatorYearsExperience: _integer(json['operator_years_experience']),
    );
  }
}

class CarHireVehicle {
  const CarHireVehicle({
    required this.id,
    required this.name,
    required this.image,
    required this.pricePerDay,
    required this.currency,
    required this.amenities,
    required this.isAvailable,
    this.seats,
    this.transmission,
    this.fuelType,
    this.description,
    this.operatorId = 0,
    this.operatorName = '',
    this.operatorLogo = '',
    this.operatorJoinedAt,
    this.operatorVerificationStatus = 'pending',
  });

  final int id;
  final String name;
  final String image;
  final double pricePerDay;
  final String currency;
  final int? seats;
  final String? transmission;
  final String? fuelType;
  final List<String> amenities;
  final String? description;
  final bool isAvailable;

  final int operatorId;
  final String operatorName;
  final String operatorLogo;
  final DateTime? operatorJoinedAt;
  final String operatorVerificationStatus;

  String get imageUrl => AuthService.storageUrl(image);

  String get operatorLogoUrl =>
      AuthService.storageUrl(operatorLogo);

  bool get operatorIsVerified =>
      operatorVerificationStatus
          .trim()
          .toLowerCase() ==
      'verified';

  factory CarHireVehicle.fromJson(Map<String, dynamic> json) {
    return CarHireVehicle(
      id: _integer(json['id']),
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      pricePerDay: _number(json['price_per_day']),
      currency: json['currency']?.toString() ?? 'USD',
      seats:
          json['seats'] == null ? null : _integer(json['seats']),
      transmission: json['transmission']?.toString(),
      fuelType: json['fuel_type']?.toString(),
      amenities: json['amenities'] is List
          ? (json['amenities'] as List)
              .map((item) => item.toString())
              .toList()
          : const [],
      description: json['description']?.toString(),
      isAvailable: _boolean(json['is_available']),
      operatorId: _integer(json['operator_id']),
      operatorName: json['operator_name']?.toString() ?? '',
      operatorLogo: json['operator_logo']?.toString() ?? '',
      operatorJoinedAt: DateTime.tryParse(
        json['operator_joined_at']?.toString() ?? '',
      ),
      operatorVerificationStatus:
          json['operator_verification_status']?.toString() ??
              'pending',
    );
  }
}

class TourPublishingContext {
  const TourPublishingContext({
    required this.canCreate,
    required this.status,
    required this.title,
    required this.message,
    required this.activeAffiliationsCount,
    required this.publicAffiliationsCount,
    required this.privateAffiliationsCount,
  });

  final bool canCreate;
  final String status;
  final String title;
  final String message;
  final int activeAffiliationsCount;
  final int publicAffiliationsCount;
  final int privateAffiliationsCount;

  bool get isIndependent => status == 'independent';
  bool get hasPrivateAffiliation => privateAffiliationsCount > 0;
  bool get hasPublicAffiliation => publicAffiliationsCount > 0;

  factory TourPublishingContext.fromJson(Map<String, dynamic> json) {
    return TourPublishingContext(
      canCreate: _boolean(json['can_create']),
      status: json['status']?.toString() ?? 'independent',
      title: json['title']?.toString() ?? 'Independent guide publishing',
      message: json['message']?.toString() ?? '',
      activeAffiliationsCount: _integer(json['active_affiliations_count']),
      publicAffiliationsCount: _integer(json['public_affiliations_count']),
      privateAffiliationsCount: _integer(json['private_affiliations_count']),
    );
  }
}

class OperatorManagementData {
  const OperatorManagementData({
    required this.tourPublishing,
    required this.carHireEnabled,
    required this.tours,
    required this.vehicles,
  });

  final TourPublishingContext tourPublishing;
  final bool carHireEnabled;
  final List<OperatorTour> tours;
  final List<CarHireVehicle> vehicles;

  factory OperatorManagementData.fromJson(Map<String, dynamic> json) {
    final publishing = json['tour_publishing'];

    return OperatorManagementData(
      tourPublishing: TourPublishingContext.fromJson(
        publishing is Map
            ? Map<String, dynamic>.from(publishing)
            : const <String, dynamic>{
              'can_create': true,
              'status': 'independent',
              'title': 'Independent guide publishing',
              'message': '',
            },
      ),
      carHireEnabled: _boolean(json['car_hire_enabled']),
      tours: _mapList(json['tours']).map(OperatorTour.fromJson).toList(),
      vehicles:
          _mapList(json['vehicles']).map(CarHireVehicle.fromJson).toList(),
    );
  }
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

int _integer(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

int? _nullableInteger(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : int.tryParse(text);
}

double _number(dynamic value) => double.tryParse(value?.toString() ?? '') ?? 0;

bool _boolean(dynamic value) => value == true || value == 1 || value == '1';

List<String> _strings(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString())
      .where((item) => item.isNotEmpty)
      .toList();
}

List<int> _integers(dynamic value) {
  if (value is! List) return const [];
  return value.map(_integer).where((item) => item > 0).toList();
}

List<String> _galleryStrings(dynamic raw) {
  if (raw is! List) return const [];
  return raw.map((item) {
    if (item is Map) return (item['url'] ?? item['path'] ?? item['image'] ?? '').toString();
    return item?.toString() ?? '';
  }).where((s) => s.trim().isNotEmpty).toList();
}
