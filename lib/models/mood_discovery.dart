import 'catalog_item.dart';
import 'operator_management.dart';
import 'safari_mood.dart';

class MoodDiscoveryData {
  const MoodDiscoveryData({
    required this.mood,
    required this.activities,
    required this.destinations,
    required this.tours,
  });

  final SafariMood mood;
  final List<CatalogItem> activities;
  final List<CatalogItem> destinations;
  final List<OperatorTour> tours;

  int get totalResults =>
      activities.length + destinations.length + tours.length;

  factory MoodDiscoveryData.fromJson(Map<String, dynamic> json) {
    final moodData = json['mood'];
    if (moodData is! Map) {
      throw const FormatException('Missing Safari Mood.');
    }

    return MoodDiscoveryData(
      mood: SafariMood.fromJson(Map<String, dynamic>.from(moodData)),
      activities:
          _maps(
            json['activities'],
          ).map((item) => CatalogItem.fromJson(item, 'activity')).toList(),
      destinations:
          _maps(
            json['destinations'],
          ).map((item) => CatalogItem.fromJson(item, 'destination')).toList(),
      tours: _maps(json['tours']).map(OperatorTour.fromJson).toList(),
    );
  }

  static List<Map<String, dynamic>> _maps(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
