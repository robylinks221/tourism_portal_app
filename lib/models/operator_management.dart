import '../services/auth_service.dart';

class TourItineraryStop {
  const TourItineraryStop({
    required this.day,
    required this.title,
    required this.description,
  });

  final int day;
  final String title;
  final String description;

  factory TourItineraryStop.fromJson(Map<String, dynamic> json) {
    return TourItineraryStop(
      day: _integer(json['day']),
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
    this.moods = const [],
    this.moodIds = const [],
    this.itinerary = const [],
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
  final List<String> moods;
  final List<int> moodIds;
  final List<TourItineraryStop> itinerary;
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
      destinationIds: destinations
          .map((item) => _integer(item['id']))
          .toList(),
      activityNames: activities
          .map((item) => item['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList(),
      destinationNames: destinations
          .map((item) => item['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList(),
      moods: _strings(json['moods']),
      moodIds: _integers(json['mood_ids']),
      itinerary: _mapList(json['itinerary'])
          .map(TourItineraryStop.fromJson)
          .toList()
        ..sort((first, second) => first.day.compareTo(second.day)),
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
      operatorResponseTimeMinutes:
          _nullableInteger(json['operator_response_time_minutes']),
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
    this.operatorName = '',
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
  final String operatorName;

  String get imageUrl => AuthService.storageUrl(image);

  factory CarHireVehicle.fromJson(Map<String, dynamic> json) {
    return CarHireVehicle(
      id: _integer(json['id']),
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      pricePerDay: _number(json['price_per_day']),
      currency: json['currency']?.toString() ?? 'USD',
      seats: json['seats'] == null ? null : _integer(json['seats']),
      transmission: json['transmission']?.toString(),
      fuelType: json['fuel_type']?.toString(),
      amenities: json['amenities'] is List
          ? (json['amenities'] as List).map((item) => item.toString()).toList()
          : const [],
      description: json['description']?.toString(),
      isAvailable: _boolean(json['is_available']),
      operatorName: json['operator_name']?.toString() ?? '',
    );
  }
}

class OperatorManagementData {
  const OperatorManagementData({
    required this.carHireEnabled,
    required this.tours,
    required this.vehicles,
  });

  final bool carHireEnabled;
  final List<OperatorTour> tours;
  final List<CarHireVehicle> vehicles;

  factory OperatorManagementData.fromJson(Map<String, dynamic> json) {
    return OperatorManagementData(
      carHireEnabled: _boolean(json['car_hire_enabled']),
      tours: _mapList(json['tours']).map(OperatorTour.fromJson).toList(),
      vehicles: _mapList(json['vehicles'])
          .map(CarHireVehicle.fromJson)
          .toList(),
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

double _number(dynamic value) =>
    double.tryParse(value?.toString() ?? '') ?? 0;

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
