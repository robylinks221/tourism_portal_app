class AdminAwardShortlistingData {
  const AdminAwardShortlistingData({
    required this.award,
    required this.categories,
    required this.scores,
  });

  final AdminAwardCycleSummary award;
  final List<AdminAwardCategorySummary> categories;
  final List<AdminAwardShortlistingScore> scores;

  factory AdminAwardShortlistingData.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'];
    final rawScores = json['scores'];
    return AdminAwardShortlistingData(
      award: AdminAwardCycleSummary.fromJson(_map(json['award'])),
      categories:
          rawCategories is List
              ? rawCategories
                  .whereType<Map>()
                  .map(
                    (e) => AdminAwardCategorySummary.fromJson(
                      Map<String, dynamic>.from(e),
                    ),
                  )
                  .toList()
              : const [],
      scores:
          rawScores is List
              ? rawScores
                  .whereType<Map>()
                  .map(
                    (e) => AdminAwardShortlistingScore.fromJson(
                      Map<String, dynamic>.from(e),
                    ),
                  )
                  .toList()
              : const [],
    );
  }
}

class AdminAwardCycleSummary {
  const AdminAwardCycleSummary({
    required this.id,
    required this.year,
    required this.title,
    required this.stage,
  });
  final int id;
  final int year;
  final String title;
  final String stage;

  factory AdminAwardCycleSummary.fromJson(Map<String, dynamic> json) =>
      AdminAwardCycleSummary(
        id: _int(json['id']),
        year: _int(json['year']),
        title: json['title']?.toString() ?? 'Tourist Guide Awards',
        stage: json['stage']?.toString() ?? '',
      );
}

class AdminAwardCategorySummary {
  const AdminAwardCategorySummary({
    required this.id,
    required this.name,
    required this.description,
    required this.finalistLimit,
    required this.isActive,
  });
  final int id;
  final String name;
  final String description;
  final int finalistLimit;
  final bool isActive;

  factory AdminAwardCategorySummary.fromJson(Map<String, dynamic> json) =>
      AdminAwardCategorySummary(
        id: _int(json['id']),
        name: json['name']?.toString() ?? 'Award category',
        description: json['description']?.toString() ?? '',
        finalistLimit: _int(json['finalist_limit']),
        isActive: _bool(json['is_active']),
      );
}

class AdminAwardShortlistingScore {
  const AdminAwardShortlistingScore({
    required this.id,
    required this.categoryId,
    required this.nominationId,
    required this.guideName,
    required this.profilePhoto,
    required this.country,
    required this.providerVerificationStatus,
    required this.ranking,
    required this.profileScore,
    required this.experienceScore,
    required this.categoryRelevanceScore,
    required this.visitorReputationScore,
    required this.nominationAssessmentScore,
    required this.supportingEvidenceScore,
    required this.totalScore,
    required this.eligible,
    required this.eligibilityReason,
    required this.ratingCount,
    required this.averageStars,
    required this.yearsExperience,
  });

  final int id;
  final int categoryId;
  final int nominationId;
  final String guideName;
  final String? profilePhoto;
  final String? country;
  final String providerVerificationStatus;
  final int ranking;
  final double profileScore;
  final double experienceScore;
  final double categoryRelevanceScore;
  final double visitorReputationScore;
  final double nominationAssessmentScore;
  final double supportingEvidenceScore;
  final double totalScore;
  final bool eligible;
  final String eligibilityReason;
  final int ratingCount;
  final double averageStars;
  final int yearsExperience;

  factory AdminAwardShortlistingScore.fromJson(Map<String, dynamic> json) {
    final guide = _map(json['guide']);
    final profile = _map(guide['profile']);
    final breakdown = _map(json['breakdown']);
    final eligibility = _map(breakdown['eligibility']);
    final reputation = _map(breakdown['visitor_reputation']);
    final experience = _map(breakdown['professional_experience']);

    return AdminAwardShortlistingScore(
      id: _int(json['id']),
      categoryId: _int(json['award_category_id']),
      nominationId: _int(json['award_nomination_id']),
      guideName:
          (profile['full_name'] ?? guide['name'] ?? 'Tourist Guide').toString(),
      profilePhoto: profile['profile_photo']?.toString(),
      country: profile['country']?.toString(),
      providerVerificationStatus:
          guide['provider_verification_status']?.toString() ?? 'pending',
      ranking: _int(json['ranking']),
      profileScore: _double(json['profile_score']),
      experienceScore: _double(json['experience_score']),
      categoryRelevanceScore: _double(json['category_relevance_score']),
      visitorReputationScore: _double(json['visitor_reputation_score']),
      nominationAssessmentScore: _double(json['nomination_assessment_score']),
      supportingEvidenceScore: _double(json['supporting_evidence_score']),
      totalScore: _double(json['total_score']),
      eligible: _bool(eligibility['eligible']),
      eligibilityReason: eligibility['reason']?.toString() ?? '',
      ratingCount: _int(reputation['rating_count']),
      averageStars: _double(reputation['average_stars']),
      yearsExperience: _int(experience['years']),
    );
  }
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

int _int(dynamic value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

double _double(dynamic value) =>
    value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;

bool _bool(dynamic value) {
  if (value is bool) return value;
  final text = value?.toString().toLowerCase();
  return text == 'true' || text == '1';
}
