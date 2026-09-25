import '../services/auth_service.dart';

class GuideAffiliationSummary {
  const GuideAffiliationSummary({
    required this.workStatus,
    required this.affiliations,
  });

  final String workStatus;
  final List<GuideOperatorAffiliation> affiliations;

  String get workStatusLabel {
    switch (workStatus) {
      case 'operator_affiliated':
        return 'Operator affiliated';
      case 'operator_affiliated_freelance':
        return 'Operator affiliated';
      default:
        return 'Independent guide';
    }
  }

  bool get isIndependent => workStatus == 'independent';

  factory GuideAffiliationSummary.fromJson(Map<String, dynamic> json) {
    return GuideAffiliationSummary(
      workStatus: json['work_status']?.toString() ?? 'independent',
      affiliations:
          _maps(
            json['affiliations'],
          ).map(GuideOperatorAffiliation.fromJson).toList(),
    );
  }
}

class OperatorGuideTeamSummary {
  const OperatorGuideTeamSummary({
    required this.affiliations,
    required this.activeTeam,
    required this.pending,
  });

  final List<GuideOperatorAffiliation> affiliations;
  final List<GuideOperatorAffiliation> activeTeam;
  final List<GuideOperatorAffiliation> pending;

  factory OperatorGuideTeamSummary.fromJson(Map<String, dynamic> json) {
    return OperatorGuideTeamSummary(
      affiliations:
          _maps(
            json['affiliations'],
          ).map(GuideOperatorAffiliation.fromJson).toList(),
      activeTeam:
          _maps(
            json['active_team'],
          ).map(GuideOperatorAffiliation.fromJson).toList(),
      pending:
          _maps(
            json['pending'],
          ).map(GuideOperatorAffiliation.fromJson).toList(),
    );
  }
}

class GuideOperatorAffiliation {
  const GuideOperatorAffiliation({
    required this.id,
    required this.guideUserId,
    required this.operatorUserId,
    required this.relationshipType,
    required this.status,
    required this.publicVisibility,
    required this.canAcceptIndependentWork,
    required this.canPublishIndependentTours,
    required this.requestedBy,
    required this.guide,
    required this.operator,
    this.startedAt,
    this.endedAt,
    this.respondedAt,
    this.createdAt,
  });

  final int id;
  final int guideUserId;
  final int operatorUserId;
  final String relationshipType;
  final String status;
  final String publicVisibility;
  final bool canAcceptIndependentWork;
  final bool canPublishIndependentTours;
  final String requestedBy;
  final AffiliationPerson? guide;
  final AffiliationPerson? operator;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? respondedAt;
  final DateTime? createdAt;

  bool get isPending => status == 'pending';
  bool get isActive => status == 'active';
  bool get isEnded => status == 'ended';
  bool get isDeclined => status == 'declined';
  bool get isPublic => publicVisibility == 'public';
  bool get requestedByGuide => requestedBy == 'guide';
  bool get requestedByOperator => requestedBy == 'operator';

  String get relationshipLabel {
    switch (relationshipType) {
      case 'employee':
        return 'Employee';
      case 'contractor':
        return 'Contractor';
      case 'partner':
        return 'Partner';
      case 'associate':
        return 'Associate';
      default:
        return relationshipType;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Active';
      case 'declined':
        return 'Declined';
      case 'ended':
        return 'Ended';
      default:
        return 'Pending';
    }
  }

  factory GuideOperatorAffiliation.fromJson(Map<String, dynamic> json) {
    return GuideOperatorAffiliation(
      id: _int(json['id']),
      guideUserId: _int(json['guide_user_id']),
      operatorUserId: _int(json['operator_user_id']),
      relationshipType: json['relationship_type']?.toString() ?? 'employee',
      status: json['status']?.toString() ?? 'pending',
      publicVisibility: json['public_visibility']?.toString() ?? 'private',
      canAcceptIndependentWork:
          json['can_accept_independent_work'] == true ||
          json['can_accept_independent_work'] == 1,
      canPublishIndependentTours:
          json['can_publish_independent_tours'] == true ||
          json['can_publish_independent_tours'] == 1,
      requestedBy: json['requested_by']?.toString() ?? '',
      guide: _person(json['guide']),
      operator: _person(json['operator']),
      startedAt: _date(json['started_at']),
      endedAt: _date(json['ended_at']),
      respondedAt: _date(json['responded_at']),
      createdAt: _date(json['created_at']),
    );
  }

  static AffiliationPerson? _person(dynamic value) {
    if (value is! Map) return null;
    return AffiliationPerson.fromJson(Map<String, dynamic>.from(value));
  }
}

class AffiliationPerson {
  const AffiliationPerson({
    required this.id,
    required this.name,
    required this.role,
    required this.profilePhoto,
    required this.country,
    required this.companyName,
    required this.fullName,
  });

  final int id;
  final String name;
  final String role;
  final String profilePhoto;
  final String country;
  final String companyName;
  final String fullName;

  String get displayName {
    if (role == 'tour_operator' && companyName.trim().isNotEmpty) {
      return companyName.trim();
    }

    if (fullName.trim().isNotEmpty) {
      return fullName.trim();
    }

    return name.trim().isEmpty ? 'Tourism professional' : name.trim();
  }

  String get profilePhotoUrl => AuthService.storageUrl(profilePhoto);

  factory AffiliationPerson.fromJson(Map<String, dynamic> json) {
    final profileRaw = json['profile'];
    final profile =
        profileRaw is Map
            ? Map<String, dynamic>.from(profileRaw)
            : const <String, dynamic>{};

    return AffiliationPerson(
      id: _int(json['id']),
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      profilePhoto:
          profile['company_logo']?.toString() ??
          profile['profile_photo']?.toString() ??
          '',
      country: profile['country']?.toString() ?? '',
      companyName: profile['company_name']?.toString() ?? '',
      fullName: profile['full_name']?.toString() ?? '',
    );
  }
}

List<Map<String, dynamic>> _maps(dynamic value) {
  if (value is! List) return const [];

  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

int _int(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

DateTime? _date(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : DateTime.tryParse(text);
}
