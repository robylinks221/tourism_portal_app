import '../services/auth_service.dart';

class AdminProvider {
  const AdminProvider({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.profilePhoto,
    required this.country,
    required this.languages,
    required this.yearsExperience,
    required this.profileViews,
    required this.publishedToursCount,
    required this.travellerRatingAverage,
    required this.travellerRatingCount,
    required this.operatorRatingAverage,
    required this.operatorRatingCount,
    required this.verificationStatus,
    required this.verificationNotes,
    required this.verifiedByName,
    this.responseTimeMinutes,
    this.verifiedAt,
    this.reviewedAt,
    this.joinedAt,
  });

  final int id;
  final String name;
  final String role;
  final String email;
  final String profilePhoto;
  final String country;
  final List<String> languages;
  final int yearsExperience;
  final int? responseTimeMinutes;
  final int profileViews;
  final int publishedToursCount;
  final double travellerRatingAverage;
  final int travellerRatingCount;
  final double operatorRatingAverage;
  final int operatorRatingCount;
  final String verificationStatus;
  final DateTime? verifiedAt;
  final DateTime? reviewedAt;
  final String verificationNotes;
  final String verifiedByName;
  final DateTime? joinedAt;

  String get photoUrl => AuthService.storageUrl(profilePhoto);
  bool get isGuide => role == 'tourist_guide';
  String get roleLabel => isGuide ? 'Tour guide' : 'Tour operator';

  String get responseTimeLabel {
    final minutes = responseTimeMinutes;
    if (minutes == null || minutes <= 0) return 'No reply data';
    if (minutes < 60) return '$minutes min';
    final hours = (minutes / 60).round();
    return hours < 24 ? '$hours hr' : '${(hours / 24).round()} days';
  }

  factory AdminProvider.fromJson(Map<String, dynamic> json) {
    return AdminProvider(
      id: _integer(json['id']),
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      profilePhoto: json['profile_photo']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      languages: json['languages'] is List
          ? (json['languages'] as List)
              .map((item) => item.toString())
              .where((item) => item.isNotEmpty)
              .toList()
          : const [],
      yearsExperience: _integer(json['years_experience']),
      responseTimeMinutes: _nullableInteger(json['response_time_minutes']),
      profileViews: _integer(json['profile_views']),
      publishedToursCount: _integer(json['published_tours_count']),
      travellerRatingAverage: _number(json['traveller_rating_average']),
      travellerRatingCount: _integer(json['traveller_rating_count']),
      operatorRatingAverage: _number(json['operator_rating_average']),
      operatorRatingCount: _integer(json['operator_rating_count']),
      verificationStatus:
          json['verification_status']?.toString() ?? 'pending',
      verifiedAt: _date(json['verified_at']),
      reviewedAt: _date(json['verification_reviewed_at']),
      verificationNotes: json['verification_notes']?.toString() ?? '',
      verifiedByName: json['verified_by_name']?.toString() ?? '',
      joinedAt: _date(json['joined_at']),
    );
  }
}

class AdminProviderQueue {
  const AdminProviderQueue({
    required this.providers,
    required this.pending,
    required this.verified,
    required this.rejected,
  });

  final List<AdminProvider> providers;
  final int pending;
  final int verified;
  final int rejected;

  factory AdminProviderQueue.fromJson(Map<String, dynamic> json) {
    final raw = json['providers'];
    final counts = json['counts'] is Map
        ? Map<String, dynamic>.from(json['counts'] as Map)
        : <String, dynamic>{};
    return AdminProviderQueue(
      providers: raw is List
          ? raw
              .whereType<Map>()
              .map((item) => AdminProvider.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
      pending: _integer(counts['pending']),
      verified: _integer(counts['verified']),
      rejected: _integer(counts['rejected']),
    );
  }
}

int _integer(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
double _number(dynamic value) =>
    double.tryParse(value?.toString() ?? '') ?? 0;
int? _nullableInteger(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : int.tryParse(text);
}

DateTime? _date(dynamic value) =>
    DateTime.tryParse(value?.toString() ?? '');
