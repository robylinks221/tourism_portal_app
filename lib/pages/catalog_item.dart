import '../services/auth_service.dart';

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
    this.accommodations = const [],
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
  final List<Accommodation> accommodations;

  bool get isActivity => type == 'activity';
  String get imageUrl => AuthService.storageUrl(image);

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
      isActive: json['is_active'] == true || json['is_active'] == 1,
      accommodations: _accommodations(json['accommodations']),
    );
  }

  static List<Accommodation> _accommodations(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Accommodation.fromJson(Map<String, dynamic>.from(item)))
        .toList();
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
  final String? contactPhone;
  final String? contactEmail;
  final String? website;

  String get imageUrl => AuthService.storageUrl(image);
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
}

class TourismCatalog {
  const TourismCatalog({required this.activities, required this.destinations});

  final List<CatalogItem> activities;
  final List<CatalogItem> destinations;
}
