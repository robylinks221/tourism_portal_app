import '../services/auth_service.dart';
import 'community.dart';
import 'safari_mood.dart';

class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.type,
    required this.name,
    required this.slug,
    required this.description,
    required this.isActive,
    this.tagline,
    this.image,
    this.location,
    this.country,
    this.latitude,
    this.longitude,
    this.accessRoute,
    this.moods = const [],
    this.moodIds = const [],
    this.bestMonthsToVisit,
    this.recommendedTripLength,
    this.weatherSummary,
    this.difficulty,
    this.accommodations = const [],
    this.destinations = const [],
    this.activities = const [],
    this.guides = const [],
    this.operators = const [],
  });

  final int id;
  final String type;
  final String name;
  final String slug;
  final String description;
  final bool isActive;
  final String? tagline;
  final String? image;
  final String? location;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? accessRoute;
  final List<String> moods;
  final List<int> moodIds;
  final String? bestMonthsToVisit;
  final String? recommendedTripLength;
  final String? weatherSummary;
  final String? difficulty;
  final List<Accommodation> accommodations;
  final List<CatalogItem> destinations;
  final List<CatalogItem> activities;
  final List<CommunityMember> guides;
  final List<CommunityMember> operators;

  bool get isActivity => type == 'activity';
  String get imageUrl => AuthService.storageUrl(image);
  List<int> get destinationIds =>
      destinations.map((destination) => destination.id).toList();

  factory CatalogItem.fromJson(Map<String, dynamic> json, String type) {
    return CatalogItem(
      id: int.parse(json['id'].toString()),
      type: type,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      tagline: json['tagline']?.toString(),
      description: json['description']?.toString() ?? '',
      image: json['image']?.toString(),
      location: json['location']?.toString(),
      country: json['country']?.toString(),
      latitude: _nullableNumber(json['latitude']),
      longitude: _nullableNumber(json['longitude']),
      accessRoute: json['access_route']?.toString(),
      moods: _strings(json['moods']),
      moodIds: _integers(json['mood_ids']),
      bestMonthsToVisit: json['best_months_to_visit']?.toString(),
      recommendedTripLength: json['recommended_trip_length']?.toString(),
      weatherSummary: json['weather_summary']?.toString(),
      difficulty: json['difficulty']?.toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      accommodations: _accommodations(json['accommodations']),
      destinations: _relatedItems(json['destinations'], 'destination'),
      activities: _relatedItems(json['activities'], 'activity'),
      guides: _providers(json['guides']),
      operators: _providers(json['operators']),
    );
  }

  static List<Accommodation> _accommodations(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Accommodation.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static List<CatalogItem> _relatedItems(dynamic value, String type) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (item) => CatalogItem.fromJson(Map<String, dynamic>.from(item), type),
        )
        .toList();
  }

  static List<CommunityMember> _providers(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (item) => CommunityMember.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  static List<String> _strings(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static List<int> _integers(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => int.tryParse(item.toString()))
        .whereType<int>()
        .toList();
  }

  static double? _nullableNumber(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : double.tryParse(text);
  }
}

class Accommodation {
  const Accommodation({
    required this.id,
    required this.destinationId,
    required this.name,
    required this.location,
    required this.description,
    required this.pricePerNight,
    required this.currency,
    required this.amenities,
    required this.isActive,
    this.image,
    this.gallery = const [],
    this.contactPhone,
    this.contactEmail,
    this.website,
  });

  final int id;
  final int destinationId;
  final String name;
  final String location;
  final String description;
  final double pricePerNight;
  final String currency;
  final List<String> amenities;
  final bool isActive;
  final String? image;
  final List<String> gallery;
  final String? contactPhone;
  final String? contactEmail;
  final String? website;

  String get imageUrl => AuthService.storageUrl(image);
  List<String> get galleryUrls {
    final paths = <String>{
      if (image?.trim().isNotEmpty == true) image!.trim(),
      ...gallery
          .where((path) => path.trim().isNotEmpty)
          .map((path) => path.trim()),
    };
    return paths
        .map(AuthService.storageUrl)
        .where((url) => url.isNotEmpty)
        .toList();
  }

  String get formattedPrice =>
      '\$${pricePerNight.toStringAsFixed(pricePerNight.truncateToDouble() == pricePerNight ? 0 : 2)} / night';

  factory Accommodation.fromJson(Map<String, dynamic> json) {
    final amenities = json['amenities'];
    return Accommodation(
      id: int.parse(json['id'].toString()),
      destinationId: int.parse(json['destination_id'].toString()),
      name: json['name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      image: json['image']?.toString(),
      gallery: _strings(json['gallery']),
      pricePerNight:
          double.tryParse(json['price_per_night']?.toString() ?? '') ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
      amenities:
          amenities is List
              ? amenities.map((item) => item.toString()).toList()
              : const [],
      contactPhone: json['contact_phone']?.toString(),
      contactEmail: json['contact_email']?.toString(),
      website: json['website']?.toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }

  static List<String> _strings(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}

class TourismCatalog {
  const TourismCatalog({
    required this.moods,
    required this.activities,
    required this.destinations,
  });

  final List<SafariMood> moods;
  final List<CatalogItem> activities;
  final List<CatalogItem> destinations;
}
