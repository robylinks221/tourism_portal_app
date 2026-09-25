class AdminAwardNomination {
  const AdminAwardNomination({
    required this.id,
    required this.year,
    required this.categoryName,
    required this.guideName,
    required this.profilePhoto,
    required this.verifiedGuide,
    required this.company,
    required this.country,
    required this.yearsExperience,
    required this.status,
    required this.ratings,
    required this.supportingComment,
    required this.adminNotes,
  });

  final int id;
  final int year;
  final String categoryName;
  final String guideName;
  final String? profilePhoto;
  final bool verifiedGuide;
  final String? company;
  final String? country;
  final int yearsExperience;
  final String status;
  final List<AdminNominationRating> ratings;
  final String? supportingComment;
  final String? adminNotes;

  factory AdminAwardNomination.fromJson(Map<String, dynamic> json) {
    final cycle = _map(json['cycle']);
    final category = _map(json['category']);
    final guide = _map(json['guide']);
    final profile = _map(guide['profile']);
    final rawRatings = json['nomination_ratings'];

    return AdminAwardNomination(
      id: _int(json['id']),
      year: _int(cycle['year']),
      categoryName: category['name']?.toString() ?? 'Award category',
      guideName:
          (profile['full_name'] ?? guide['name'] ?? 'Tourist Guide').toString(),
      profilePhoto: profile['profile_photo']?.toString(),
      verifiedGuide:
          (guide['provider_verification_status']?.toString() ?? '') ==
              'verified',
      company: profile['company_name']?.toString(),
      country: profile['country']?.toString(),
      yearsExperience: _int(profile['years_experience']),
      status: json['status']?.toString() ?? 'pending',
      ratings: rawRatings is List
          ? rawRatings
              .whereType<Map>()
              .map((e) => AdminNominationRating.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const [],
      supportingComment:
          (json['supporting_comment'] ?? json['nomination_statement'])
              ?.toString(),
      adminNotes: json['admin_notes']?.toString(),
    );
  }
}

class AdminNominationRating {
  const AdminNominationRating({
    required this.name,
    required this.rating,
  });

  final String name;
  final int rating;

  factory AdminNominationRating.fromJson(Map<String, dynamic> json) {
    return AdminNominationRating(
      name: (json['criterion_name'] ??
              json['name'] ??
              json['criterion_key'] ??
              'Criterion')
          .toString(),
      rating: _int(json['rating']),
    );
  }
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

int _int(dynamic value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
