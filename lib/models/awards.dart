class AwardCycle {
  const AwardCycle({
    required this.id,
    required this.year,
    required this.title,
    required this.introduction,
    required this.stage,
    required this.votingIsOpen,
    required this.resultsVisibility,
    required this.votingRule,
    required this.categoryCount,
    required this.finalistCount,
    this.votingOpensAt,
    this.votingClosesAt,
  });
  final int id, year, categoryCount, finalistCount;
  final String title, introduction, stage, resultsVisibility, votingRule;
  final bool votingIsOpen;
  final DateTime? votingOpensAt, votingClosesAt;
  factory AwardCycle.fromJson(Map<String, dynamic> j) => AwardCycle(
    id: _i(j['id']),
    year: _i(j['year']),
    title: _s(j['title']),
    introduction: _s(j['introduction']),
    stage: _s(j['stage']),
    votingIsOpen: _b(j['voting_is_open']),
    resultsVisibility: _s(j['results_visibility']),
    votingRule: _s(j['voting_rule']),
    categoryCount: _i(j['category_count']),
    finalistCount: _i(j['finalist_count']),
    votingOpensAt: _dt(j['voting_opens_at']),
    votingClosesAt: _dt(j['voting_closes_at']),
  );
}

class AwardCategory {
  const AwardCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.finalistCount,
    required this.publicVotingEnabled,
    required this.votingStatus,
  });
  final int id, finalistCount;
  final String name, slug, description, votingStatus;
  final bool publicVotingEnabled;
  factory AwardCategory.fromJson(Map<String, dynamic> j) => AwardCategory(
    id: _i(j['id']),
    name: _s(j['name']),
    slug: _s(j['slug']),
    description: _s(j['description']),
    finalistCount: _i(j['finalist_count']),
    publicVotingEnabled: _b(j['public_voting_enabled']),
    votingStatus: _s(j['voting_status']),
  );
}

class AwardFinalist {
  const AwardFinalist({
    required this.id,
    required this.guideUserId,
    required this.categoryId,
    required this.name,
    required this.categoryName,
    required this.profilePhoto,
    required this.verified,
    required this.company,
    required this.region,
    required this.yearsExperience,
    required this.specialities,
    required this.introduction,
    required this.biography,
    required this.languages,
    required this.achievements,
    required this.canVote,
    required this.hasVoted,
    required this.votedForThisFinalist,
  });
  final int id, guideUserId, categoryId, yearsExperience;
  final String name,
      categoryName,
      profilePhoto,
      company,
      region,
      introduction,
      biography,
      achievements;
  final bool verified, canVote, hasVoted, votedForThisFinalist;
  final List<String> specialities, languages;
  factory AwardFinalist.fromJson(Map<String, dynamic> j) {
    final guide = _map(j['guide']);
    final profile = _map(guide['profile']);
    final category = _map(j['category']);
    return AwardFinalist(
      id: _i(j['id']),
      guideUserId: _i(guide['id']),
      categoryId: _i(category['id']),
      name: _first([j['name'], guide['name'], profile['full_name']]),
      categoryName: _first([j['category_name'], category['name']]),
      profilePhoto: _first([
        j['profile_photo'],
        guide['profile_photo'],
        profile['profile_photo'],
      ]),
      verified: _b(j['verified'] ?? guide['verified'] ?? guide['is_verified']),
      company: _first([
        j['company'],
        j['organisation'],
        profile['company_name'],
      ]),
      region: _first([j['region'], j['district'], profile['country']]),
      yearsExperience: _i(j['years_experience'] ?? profile['years_experience']),
      specialities: _strings(
        j['specialities'] ?? j['activities'] ?? profile['safari_activities'],
      ),
      introduction: _first([
        j['introduction'],
        j['short_intro'],
        j['finalist_intro'],
      ]),
      biography: _first([j['biography'], j['bio'], profile['biography']]),
      languages: _strings(j['languages'] ?? profile['languages']),
      achievements: _first([j['achievements'], j['recognition']]),
      canVote: _b(
        _map(j['voting'])['is_open'] ?? j['can_vote'] ?? j['voting_allowed'],
      ),
      hasVoted: _b(
        _map(j['voting'])['has_voted_in_category'] ??
            j['has_voted'] ??
            j['voted'],
      ),
      votedForThisFinalist: _b(
        _map(j['voting'])['voted_for_this_finalist'] ??
            j['voted_for_this_finalist'],
      ),
    );
  }
}

class AwardFinalistResult {
  const AwardFinalistResult({
    required this.finalistId,
    required this.percentage,
    this.votes,
  });
  final int finalistId;
  final double percentage;
  final int? votes;
  factory AwardFinalistResult.fromJson(Map<String, dynamic> j) =>
      AwardFinalistResult(
        finalistId: _i(j['finalist_id']),
        percentage: double.tryParse(j['percentage']?.toString() ?? '') ?? 0,
        votes: j['votes'] == null ? null : _i(j['votes']),
      );
}

class AwardCategoryResult {
  const AwardCategoryResult({
    required this.id,
    required this.name,
    required this.finalists,
  });
  final int id;
  final String name;
  final List<AwardFinalistResult> finalists;
  factory AwardCategoryResult.fromJson(Map<String, dynamic> j) =>
      AwardCategoryResult(
        id: _i(j['id']),
        name: _s(j['name']),
        finalists:
            _maps(j['finalists']).map(AwardFinalistResult.fromJson).toList(),
      );
}

class AwardResultsData {
  const AwardResultsData({
    required this.mode,
    required this.message,
    required this.categories,
  });
  final String mode, message;
  final List<AwardCategoryResult> categories;
  bool get isHidden => mode == 'hidden';
  factory AwardResultsData.fromJson(Map<String, dynamic> j) => AwardResultsData(
    mode: _s(j['mode']).isEmpty ? 'hidden' : _s(j['mode']),
    message: _s(j['message']),
    categories:
        _maps(j['categories']).map(AwardCategoryResult.fromJson).toList(),
  );
}

class AwardsHomeData {
  const AwardsHomeData({
    required this.award,
    required this.featuredFinalists,
    required this.categories,
    required this.previousWinners,
  });
  final AwardCycle award;
  final List<AwardFinalist> featuredFinalists;
  final List<AwardCategory> categories;
  final List<AwardWinner> previousWinners;
  factory AwardsHomeData.fromJson(Map<String, dynamic> j) => AwardsHomeData(
    award: AwardCycle.fromJson(_map(j['award'])),
    featuredFinalists:
        _maps(j['featured_finalists']).map(AwardFinalist.fromJson).toList(),
    categories: _maps(j['categories']).map(AwardCategory.fromJson).toList(),
    previousWinners:
        _maps(j['previous_winners']).map(AwardWinner.fromJson).toList(),
  );
}

class AwardWinner {
  const AwardWinner({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.profilePhoto,
    required this.year,
    required this.statement,
  });
  final int id, year;
  final String name, categoryName, profilePhoto, statement;
  factory AwardWinner.fromJson(Map<String, dynamic> j) {
    final f = _map(j['finalist']);
    final g = _map(f['guide']);
    final p = _map(g['profile']);
    final c = _map(j['category']);
    return AwardWinner(
      id: _i(j['id']),
      name: _first([j['name'], f['name'], g['name'], p['full_name']]),
      categoryName: _first([j['category_name'], c['name'], f['category_name']]),
      profilePhoto: _first([
        j['profile_photo'],
        f['profile_photo'],
        p['profile_photo'],
      ]),
      year: _i(j['year'] ?? _map(j['cycle'])['year']),
      statement: _first([j['recognition_statement'], j['statement']]),
    );
  }
}

class AwardVoteRecord {
  const AwardVoteRecord({
    required this.id,
    required this.categoryName,
    required this.guideName,
    required this.profilePhoto,
    required this.votedAt,
    required this.status,
  });
  final int id;
  final String categoryName, guideName, profilePhoto, status;
  final DateTime? votedAt;
  factory AwardVoteRecord.fromJson(Map<String, dynamic> j) {
    final f = _map(j['finalist']);
    final g = _map(f['guide']);
    final p = _map(g['profile']);
    final c = _map(j['category']);
    return AwardVoteRecord(
      id: _i(j['id']),
      categoryName: _first([j['category_name'], c['name']]),
      guideName: _first([
        j['guide_name'],
        f['name'],
        g['name'],
        p['full_name'],
      ]),
      profilePhoto: _first([
        j['profile_photo'],
        f['profile_photo'],
        p['profile_photo'],
      ]),
      votedAt: _dt(j['voted_at'] ?? j['created_at']),
      status: _first([j['status'], 'Recorded']),
    );
  }
}

class AwardNominationGuide {
  const AwardNominationGuide({
    required this.id,
    required this.name,
    required this.profilePhoto,
    required this.verified,
    required this.company,
    required this.country,
    required this.region,
    required this.yearsExperience,
    required this.specialities,
    required this.alreadyNominatedInCategory,
  });
  final int id, yearsExperience;
  final String name, profilePhoto, company, country, region;
  final bool verified, alreadyNominatedInCategory;
  final List<String> specialities;
  factory AwardNominationGuide.fromJson(Map<String, dynamic> j) =>
      AwardNominationGuide(
        id: _i(j['id']),
        name: _s(j['name']),
        profilePhoto: _s(j['profile_photo']),
        verified: _b(j['verified']),
        company: _s(j['company']),
        country: _s(j['country']),
        region: _s(j['region']),
        yearsExperience: _i(j['years_experience']),
        specialities: _strings(j['specialities']),
        alreadyNominatedInCategory: _b(j['already_nominated_in_category']),
      );
}

class AwardNominationCriterion {
  const AwardNominationCriterion({
    required this.key,
    required this.name,
    required this.description,
    required this.assessmentWeight,
  });
  final String key, name, description;
  final int assessmentWeight;
  factory AwardNominationCriterion.fromJson(Map<String, dynamic> j) =>
      AwardNominationCriterion(
        key: _s(j['key']),
        name: _s(j['name']),
        description: _s(j['description']),
        assessmentWeight: _i(j['assessment_weight']),
      );
}

class AwardNominationOptions {
  const AwardNominationOptions({
    required this.award,
    required this.nominationsAreOpen,
    required this.categories,
    required this.criteria,
    required this.guides,
  });
  final AwardCycle award;
  final bool nominationsAreOpen;
  final List<AwardCategory> categories;
  final List<AwardNominationCriterion> criteria;
  final List<AwardNominationGuide> guides;
  factory AwardNominationOptions.fromJson(Map<String, dynamic> j) =>
      AwardNominationOptions(
        award: AwardCycle.fromJson(_map(j['award'])),
        nominationsAreOpen: _b(j['nominations_are_open']),
        categories:
            _maps(j['categories'])
                .map(
                  (x) => AwardCategory(
                    id: _i(x['id']),
                    name: _s(x['name']),
                    slug: _s(x['slug']),
                    description: _s(x['description']),
                    finalistCount: 0,
                    publicVotingEnabled: false,
                    votingStatus: 'closed',
                  ),
                )
                .toList(),
        criteria:
            _maps(
              j['nomination_criteria'],
            ).map(AwardNominationCriterion.fromJson).toList(),
        guides: _maps(j['guides']).map(AwardNominationGuide.fromJson).toList(),
      );
}

class AwardNominationRecord {
  const AwardNominationRecord({
    required this.id,
    required this.awardYear,
    required this.categoryName,
    required this.guideName,
    required this.profilePhoto,
    required this.statement,
    required this.status,
    required this.submittedAt,
    required this.reviewedAt,
  });
  final int id, awardYear;
  final String categoryName, guideName, profilePhoto, statement, status;
  final DateTime? submittedAt, reviewedAt;
  factory AwardNominationRecord.fromJson(Map<String, dynamic> j) {
    final c = _map(j['category']), g = _map(j['guide']);
    return AwardNominationRecord(
      id: _i(j['id']),
      awardYear: _i(j['award_year']),
      categoryName: _s(c['name']),
      guideName: _s(g['name']),
      profilePhoto: _s(g['profile_photo']),
      statement: _s(j['nomination_statement']),
      status: _s(j['status']),
      submittedAt: _dt(j['submitted_at']),
      reviewedAt: _dt(j['reviewed_at']),
    );
  }
}

int _i(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
String _s(dynamic v) => v?.toString() ?? '';
bool _b(dynamic v) =>
    v == true ||
    v == 1 ||
    v?.toString() == '1' ||
    v?.toString().toLowerCase() == 'true';
DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());
Map<String, dynamic> _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
List<Map<String, dynamic>> _maps(dynamic v) =>
    v is List
        ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : [];
List<String> _strings(dynamic v) =>
    v is List
        ? v
            .map(
              (e) => e is Map ? _first([e['name'], e['title']]) : e.toString(),
            )
            .where((e) => e.isNotEmpty)
            .toList()
        : [];
String _first(List<dynamic> v) {
  for (final x in v) {
    final s = x?.toString().trim() ?? '';
    if (s.isNotEmpty) return s;
  }
  return '';
}
