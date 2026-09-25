import 'catalog_item.dart';
import 'community.dart';
import 'operator_management.dart';

enum DiscoveryKind { guide, operator, tour, destination, activity }

class DiscoveryRecord {
  const DiscoveryRecord({
    required this.kind,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.location,
    required this.imageUrl,
    required this.activities,
    required this.rating,
    required this.available,
    this.price,
  });

  final DiscoveryKind kind;
  final int id;
  final String title;
  final String subtitle;
  final String location;
  final String imageUrl;
  final List<String> activities;
  final double rating;
  final double? price;
  final bool available;

  String get key => '${kind.name}:$id';

  String get kindLabel => switch (kind) {
    DiscoveryKind.guide => 'Tourist Guide',
    DiscoveryKind.operator => 'Tour Operator',
    DiscoveryKind.tour => 'Tour',
    DiscoveryKind.destination => 'Destination',
    DiscoveryKind.activity => 'Activity',
  };

  factory DiscoveryRecord.fromCatalog(CatalogItem item) {
    double? price;
    if (item.accommodations.isNotEmpty) {
      price = item.accommodations
          .map((accommodation) => accommodation.pricePerNight)
          .reduce((first, second) => first < second ? first : second);
    }
    return DiscoveryRecord(
      kind:
          item.isActivity ? DiscoveryKind.activity : DiscoveryKind.destination,
      id: item.id,
      title: item.name,
      subtitle:
          item.tagline?.trim().isNotEmpty == true
              ? item.tagline!.trim()
              : item.description,
      location: [item.location, item.country]
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .join(', '),
      imageUrl: item.imageUrl,
      activities:
          item.isActivity
              ? [item.name]
              : item.activities.map((activity) => activity.name).toList(),
      rating: 0,
      price: price,
      available: item.isActive,
    );
  }

  factory DiscoveryRecord.fromProvider(CommunityMember member) {
    return DiscoveryRecord(
      kind: member.isGuide ? DiscoveryKind.guide : DiscoveryKind.operator,
      id: member.id,
      title: member.name,
      subtitle:
          member.biography.trim().isEmpty
              ? (member.isGuide
                  ? 'Local tourist guide'
                  : 'Safari tour operator')
              : member.biography.trim(),
      location:
          member.location.trim().isNotEmpty
              ? member.location.trim()
              : member.country.trim(),
      imageUrl: member.profilePhotoUrl,
      activities: member.activityNames,
      rating: member.ratingAverage,
      available: member.isVerified,
    );
  }

  factory DiscoveryRecord.fromTour(OperatorTour tour) {
    return DiscoveryRecord(
      kind: DiscoveryKind.tour,
      id: tour.id,
      title: tour.name,
      subtitle:
          tour.overview.trim().isEmpty
              ? '${tour.days} day safari by ${tour.operatorName}'
              : tour.overview.trim(),
      location: [
        tour.operatorLocation,
        ...tour.destinationNames,
      ].where((value) => value.trim().isNotEmpty).join(', '),
      imageUrl: tour.imageUrl,
      activities: tour.activityNames,
      rating: tour.operatorRatingAverage,
      price: tour.price,
      available: tour.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'location': location,
    'image_url': imageUrl,
    'activities': activities,
    'rating': rating,
    'price': price,
    'available': available,
  };

  factory DiscoveryRecord.fromJson(Map<String, dynamic> json) {
    final kindName = json['kind']?.toString() ?? '';
    final kind = DiscoveryKind.values.firstWhere(
      (value) => value.name == kindName,
      orElse: () => DiscoveryKind.destination,
    );
    final rawActivities = json['activities'];
    return DiscoveryRecord(
      kind: kind,
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      activities:
          rawActivities is List
              ? rawActivities.map((value) => value.toString()).toList()
              : const [],
      rating: double.tryParse(json['rating']?.toString() ?? '') ?? 0,
      price:
          json['price'] == null
              ? null
              : double.tryParse(json['price'].toString()),
      available: json['available'] == true || json['available'] == 1,
    );
  }
}
