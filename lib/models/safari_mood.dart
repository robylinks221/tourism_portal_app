import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class SafariMood {
  const SafariMood({
    required this.id,
    required this.key,
    required this.title,
    required this.subtitle,
    required this.iconKey,
    required this.primaryColorHex,
    required this.secondaryColorHex,
    required this.isActive,
    required this.sortOrder,
    this.image,
    this.activityCount = 0,
    this.destinationCount = 0,
    this.tourCount = 0,
  });

  final int id;
  final String key;
  final String title;
  final String subtitle;
  final String? image;
  final String iconKey;
  final String primaryColorHex;
  final String secondaryColorHex;
  final bool isActive;
  final int sortOrder;
  final int activityCount;
  final int destinationCount;
  final int tourCount;

  String get imageUrl => AuthService.storageUrl(image);
  Color get primaryColor => _color(primaryColorHex, const Color(0xFF1F6B5C));
  Color get secondaryColor => _color(secondaryColorHex, const Color(0xFF123F38));
  int get assignmentCount => activityCount + destinationCount + tourCount;

  IconData get icon {
    switch (iconKey) {
      case 'forest':
        return Icons.forest_rounded;
      case 'wildlife':
        return Icons.pets_rounded;
      case 'bird':
        return Icons.flutter_dash_rounded;
      case 'culture':
        return Icons.diversity_3_rounded;
      case 'route':
        return Icons.route_rounded;
      case 'luxury':
        return Icons.diamond_outlined;
      case 'water':
        return Icons.water_rounded;
      case 'mountain':
        return Icons.terrain_rounded;
      case 'camera':
        return Icons.photo_camera_outlined;
      default:
        return Icons.explore_rounded;
    }
  }

  factory SafariMood.fromJson(Map<String, dynamic> json) {
    return SafariMood(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      key: json['slug']?.toString() ?? '',
      title: json['name']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      image: json['image']?.toString(),
      iconKey: json['icon_key']?.toString() ?? 'compass',
      primaryColorHex: json['primary_color']?.toString() ?? '#1F6B5C',
      secondaryColorHex: json['secondary_color']?.toString() ?? '#123F38',
      isActive: json['is_active'] == true || json['is_active'] == 1,
      sortOrder: int.tryParse(json['sort_order']?.toString() ?? '') ?? 0,
      activityCount:
          int.tryParse(json['activities_count']?.toString() ?? '') ?? 0,
      destinationCount:
          int.tryParse(json['destinations_count']?.toString() ?? '') ?? 0,
      tourCount:
          int.tryParse(json['operator_tours_count']?.toString() ?? '') ?? 0,
    );
  }

  static Color _color(String value, Color fallback) {
    final normalized = value.trim().replaceFirst('#', '');
    final parsed = int.tryParse(normalized, radix: 16);
    return parsed == null || normalized.length != 6
        ? fallback
        : Color(0xFF000000 | parsed);
  }
}

const fallbackSafariMoods = <SafariMood>[
  SafariMood(id: -1, key: 'primates', title: 'Meet the primates', subtitle: 'Gorillas, chimpanzees and forest encounters', iconKey: 'forest', primaryColorHex: '#2A6A4F', secondaryColorHex: '#123B32', isActive: true, sortOrder: 0),
  SafariMood(id: -2, key: 'big-five', title: 'Find the Big Five', subtitle: 'Iconic wildlife across savannah landscapes', iconKey: 'wildlife', primaryColorHex: '#B56B36', secondaryColorHex: '#5E351F', isActive: true, sortOrder: 1),
  SafariMood(id: -3, key: 'birding', title: 'Birding escapes', subtitle: 'Rare species, wetlands and forest trails', iconKey: 'bird', primaryColorHex: '#3C8F9B', secondaryColorHex: '#174854', isActive: true, sortOrder: 2),
  SafariMood(id: -4, key: 'culture', title: 'Cultural journeys', subtitle: 'Community stories, heritage and local life', iconKey: 'culture', primaryColorHex: '#B8573C', secondaryColorHex: '#6B2F2B', isActive: true, sortOrder: 3),
  SafariMood(id: -5, key: 'weekend', title: 'Weekend adventures', subtitle: 'Short, exciting escapes close to home', iconKey: 'route', primaryColorHex: '#567F3A', secondaryColorHex: '#2E4A25', isActive: true, sortOrder: 4),
  SafariMood(id: -6, key: 'luxury', title: 'Luxury in the wild', subtitle: 'Private journeys and exceptional stays', iconKey: 'luxury', primaryColorHex: '#9A7652', secondaryColorHex: '#4E3827', isActive: true, sortOrder: 5),
];

SafariMood? safariMoodByKey(Iterable<SafariMood> moods, String? key) {
  for (final mood in moods) {
    if (mood.key == key) return mood;
  }
  return null;
}

class SafariMoodController extends ValueNotifier<String?> {
  SafariMoodController._() : super(null);

  static final instance = SafariMoodController._();

  void select(String key) => value = value == key ? null : key;

  void clear() => value = null;
}
