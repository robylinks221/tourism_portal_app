class TourismCountry {
  const TourismCountry({
    required this.id,
    required this.name,
    required this.code,
    required this.tagline,
    required this.introduction,
    required this.cardImageUrl,
    required this.heroImageUrl,
    required this.sortOrder,
    required this.isActive,
    required this.tourCount,
    required this.moodIds,
    required this.activityIds,
    required this.destinationIds,
  });

  final int id;
  final String name;
  final String code;
  final String tagline;
  final String introduction;
  final String cardImageUrl;
  final String heroImageUrl;
  final int sortOrder;
  final bool isActive;
  final int tourCount;
  final List<int> moodIds;
  final List<int> activityIds;
  final List<int> destinationIds;

  factory TourismCountry.fromJson(Map<String, dynamic> json) {
    return TourismCountry(
      id: _int(json['id']),
      name: (json['name'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      tagline: (json['tagline'] ?? '').toString(),
      introduction: (json['introduction'] ?? '').toString(),
      cardImageUrl: (json['card_image_url'] ?? '').toString(),
      heroImageUrl: (json['hero_image_url'] ?? '').toString(),
      sortOrder: _int(json['sort_order']),
      isActive: _bool(json['is_active']),
      tourCount: _int(json['tour_count']),
      moodIds: _intList(json['mood_ids']),
      activityIds: _intList(json['activity_ids']),
      destinationIds: _intList(json['destination_ids']),
    );
  }

  static int _int(dynamic value) =>
      value is int ? value : int.tryParse('$value') ?? 0;

  static List<int> _intList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => _int(item))
        .where((item) => item > 0)
        .toList();
  }

  static bool _bool(dynamic value) {
    if (value is bool) return value;
    return value == 1 || value == '1' || '$value'.toLowerCase() == 'true';
  }
}
