import '../services/auth_service.dart';
import 'operator_management.dart';

class ExistingRating {
  const ExistingRating({required this.stars, required this.review});

  final int stars;
  final String review;

  factory ExistingRating.fromJson(Map<String, dynamic> json) {
    return ExistingRating(
      stars: _integer(json['stars']),
      review: json['review']?.toString() ?? '',
    );
  }
}

class ProviderCatalogLink {
  const ProviderCatalogLink({
    required this.id,
    required this.name,
    required this.slug,
    required this.type,
  });

  final int id;
  final String name;
  final String slug;
  final String type;

  bool get isActivity => type == 'activity';

  factory ProviderCatalogLink.fromJson(Map<String, dynamic> json, String type) {
    return ProviderCatalogLink(
      id: _integer(json['id']),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      type: type,
    );
  }
}

class PublicProviderAffiliation {
  const PublicProviderAffiliation({
    required this.id,
    required this.relationshipType,
    required this.operator,
  });

  final int id;
  final String relationshipType;
  final CommunityMember operator;

  String get relationshipLabel {
    switch (relationshipType) {
      case 'employee':
        return 'Team member';
      case 'freelance':
        return 'Freelance guide';
      case 'partner':
        return 'Safari partner';
      case 'contractor':
        return 'Contract guide';
      default:
        return relationshipType
            .replaceAll('_', ' ')
            .split(' ')
            .where((part) => part.isNotEmpty)
            .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' ');
    }
  }

  factory PublicProviderAffiliation.fromJson(Map<String, dynamic> json) {
    final operator = json['operator'];
    return PublicProviderAffiliation(
      id: _integer(json['id']),
      relationshipType: json['relationship_type']?.toString() ?? '',
      operator: CommunityMember.fromJson(
        operator is Map
            ? Map<String, dynamic>.from(operator)
            : const <String, dynamic>{},
      ),
    );
  }
}

class SafariTeamMember {
  const SafariTeamMember({
    required this.affiliationId,
    required this.relationshipType,
    required this.guide,
  });

  final int affiliationId;
  final String relationshipType;
  final CommunityMember guide;

  String get relationshipLabel {
    switch (relationshipType) {
      case 'employee':
        return 'Team member';
      case 'freelance':
        return 'Freelance guide';
      case 'partner':
        return 'Safari partner';
      case 'contractor':
        return 'Contract guide';
      default:
        return relationshipType
            .replaceAll('_', ' ')
            .split(' ')
            .where((part) => part.isNotEmpty)
            .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' ');
    }
  }

  factory SafariTeamMember.fromJson(Map<String, dynamic> json) {
    return SafariTeamMember(
      affiliationId: _integer(json['affiliation_id']),
      relationshipType: json['relationship_type']?.toString() ?? '',
      guide: CommunityMember.fromJson(json),
    );
  }
}

class CommunityMember {
  const CommunityMember({
    required this.id,
    required this.name,
    required this.role,
    required this.profilePhoto,
    required this.location,
    required this.biography,
    required this.ratingAverage,
    required this.ratingCount,
    required this.joinedAt,
    this.viewCount = 0,
    this.languages = const [],
    this.yearsExperience = 0,
    this.responseTimeMinutes,
    this.publishedToursCount = 0,
    this.verificationStatus = 'pending',
    this.verifiedAt,
    this.travellerRatingAverage = 0,
    this.travellerRatingCount = 0,
    this.operatorRatingAverage = 0,
    this.operatorRatingCount = 0,
    this.fullName = '',
    this.companyName = '',
    this.email = '',
    this.gender = '',
    this.country = '',
    this.operatingCountries = const [],
    this.phone = '',
    this.coverImage = '',
    this.gallery = const [],
    this.contactPerson = '',
    this.address = '',
    this.socialLinks = const {},
    this.activityLinks = const [],
    this.destinationLinks = const [],
    this.tours = const [],
    this.carHireEnabled = false,
    this.publicAffiliations = const [],
    this.safariTeam = const [],
    this.myRating,
  });

  final int id;
  final String name;
  final String role;
  final String profilePhoto;
  final String location;
  final String biography;
  final double ratingAverage;
  final int ratingCount;
  final int viewCount;
  final List<String> languages;
  final int yearsExperience;
  final int? responseTimeMinutes;
  final int publishedToursCount;
  final String verificationStatus;
  final DateTime? verifiedAt;
  final double travellerRatingAverage;
  final int travellerRatingCount;
  final double operatorRatingAverage;
  final int operatorRatingCount;
  final DateTime? joinedAt;
  final String fullName;
  final String companyName;
  final String email;
  final String gender;
  final String country;
  final List<String> operatingCountries;
  final String phone;
  final String coverImage;
  final List<String> gallery;
  final String contactPerson;
  final String address;
  final Map<String, String> socialLinks;
  final List<ProviderCatalogLink> activityLinks;
  final List<ProviderCatalogLink> destinationLinks;
  final List<OperatorTour> tours;
  final bool carHireEnabled;
  final List<PublicProviderAffiliation> publicAffiliations;
  final List<SafariTeamMember> safariTeam;
  final ExistingRating? myRating;

  String get profilePhotoUrl => AuthService.storageUrl(profilePhoto);
  String get coverImageUrl => AuthService.storageUrl(coverImage);
  List<String> get galleryUrls =>
      gallery
          .map(AuthService.storageUrl)
          .where((url) => url.isNotEmpty)
          .toList();
  List<String> get activityNames =>
      activityLinks.map((item) => item.name).toList();
  List<String> get destinationNames =>
      destinationLinks.map((item) => item.name).toList();

  List<String> get countriesServed {
    final values =
        operatingCountries
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList();

    if (values.isNotEmpty) return values;

    final baseCountry = country.trim();
    return baseCountry.isEmpty ? const [] : [baseCountry];
  }

  bool operatesIn(String countryName) {
    final normalized = countryName.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return countriesServed.any(
      (country) => country.toLowerCase() == normalized,
    );
  }

  bool get isGuide => role == 'tourist_guide';
  bool get isOperator => role == 'tour_operator';
  bool get isVerified => verificationStatus == 'verified' && verifiedAt != null;

  String get responseTimeLabel {
    final minutes = responseTimeMinutes;
    if (minutes == null || minutes <= 0) return 'No reply data yet';
    if (minutes < 60) return 'About $minutes min';
    final hours = (minutes / 60).round();
    if (hours < 24) return 'About $hours hr${hours == 1 ? '' : 's'}';
    final days = (hours / 24).round();
    return 'About $days day${days == 1 ? '' : 's'}';
  }

  String get roleLabel {
    switch (role) {
      case 'tourist_guide':
        return 'Tour guide';
      case 'tour_operator':
        return 'Tour operator';
      default:
        return 'Tourist';
    }
  }

  factory CommunityMember.fromJson(Map<String, dynamic> json) {
    final rating = json['my_rating'];
    final activities =
        _mapList(json['activities'])
            .map((item) => ProviderCatalogLink.fromJson(item, 'activity'))
            .where((item) => item.name.isNotEmpty)
            .toList();
    final destinations =
        _mapList(json['destinations'])
            .map((item) => ProviderCatalogLink.fromJson(item, 'destination'))
            .where((item) => item.name.isNotEmpty)
            .toList();

    return CommunityMember(
      id: _integer(json['id']),
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      profilePhoto: json['profile_photo']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      biography: json['biography']?.toString() ?? '',
      ratingAverage: _number(json['rating_average']),
      ratingCount: _integer(json['rating_count']),
      viewCount: _integer(json['profile_views']),
      languages: _stringList(json['languages']),
      yearsExperience: _integer(json['years_experience']),
      responseTimeMinutes: _nullableInteger(json['response_time_minutes']),
      publishedToursCount: _integer(json['published_tours_count']),
      verificationStatus: json['verification_status']?.toString() ?? 'pending',
      verifiedAt: DateTime.tryParse(json['verified_at']?.toString() ?? ''),
      travellerRatingAverage: _number(json['traveller_rating_average']),
      travellerRatingCount: _integer(json['traveller_rating_count']),
      operatorRatingAverage: _number(json['operator_rating_average']),
      operatorRatingCount: _integer(json['operator_rating_count']),
      joinedAt: DateTime.tryParse(json['joined_at']?.toString() ?? ''),
      fullName: json['full_name']?.toString() ?? '',
      companyName: json['company_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      operatingCountries: _stringList(json['operating_countries']),
      phone: json['phone']?.toString() ?? '',
      coverImage: json['cover_image']?.toString() ?? '',
      gallery: _stringList(json['gallery']),
      contactPerson: json['contact_person']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      socialLinks: _stringMap(json['social_links']),
      activityLinks: activities,
      destinationLinks: destinations,
      tours: _mapList(json['tours']).map(OperatorTour.fromJson).toList(),
      carHireEnabled:
          json['car_hire_enabled'] == true || json['car_hire_enabled'] == 1,
      publicAffiliations:
          _mapList(json['public_affiliations'])
              .map(PublicProviderAffiliation.fromJson)
              .where((item) => item.operator.id > 0)
              .toList(),
      safariTeam:
          _mapList(json['safari_team'])
              .map(SafariTeamMember.fromJson)
              .where((item) => item.guide.id > 0)
              .toList(),
      myRating:
          rating is Map
              ? ExistingRating.fromJson(Map<String, dynamic>.from(rating))
              : null,
    );
  }
}

class FeaturedProviders {
  const FeaturedProviders({required this.guides, required this.operators});

  final List<CommunityMember> guides;
  final List<CommunityMember> operators;

  factory FeaturedProviders.fromJson(Map<String, dynamic> json) {
    return FeaturedProviders(
      guides: _mapList(json['guides']).map(CommunityMember.fromJson).toList(),
      operators:
          _mapList(json['operators']).map(CommunityMember.fromJson).toList(),
    );
  }
}

class ChatParticipant {
  const ChatParticipant({
    required this.id,
    required this.name,
    required this.role,
    required this.profilePhoto,
  });

  final int id;
  final String name;
  final String role;
  final String profilePhoto;

  String get profilePhotoUrl => AuthService.storageUrl(profilePhoto);

  String get roleLabel {
    switch (role) {
      case 'tourist_guide':
        return 'Tour guide';
      case 'tour_operator':
        return 'Tour operator';
      default:
        return 'Tourist';
    }
  }

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: _integer(json['id']),
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      profilePhoto: json['profile_photo']?.toString() ?? '',
    );
  }
}

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.participant,
    required this.latestMessage,
    required this.latestMessageAt,
    required this.unreadCount,
  });

  final int id;
  final ChatParticipant participant;
  final String latestMessage;
  final DateTime? latestMessageAt;
  final int unreadCount;

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final participant = json['participant'];
    return ChatConversation(
      id: _integer(json['id']),
      participant: ChatParticipant.fromJson(
        participant is Map
            ? Map<String, dynamic>.from(participant)
            : const <String, dynamic>{},
      ),
      latestMessage: json['latest_message']?.toString() ?? '',
      latestMessageAt: DateTime.tryParse(
        json['latest_message_at']?.toString() ?? '',
      ),
      unreadCount: _integer(json['unread_count']),
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.createdAt,
    required this.readAt,
  });

  final int id;
  final int conversationId;
  final int senderId;
  final String body;
  final DateTime? createdAt;
  final DateTime? readAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: _integer(json['id']),
      conversationId: _integer(json['conversation_id']),
      senderId: _integer(json['sender_id']),
      body: json['body']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      readAt: DateTime.tryParse(json['read_at']?.toString() ?? ''),
    );
  }
}

class ChatThread {
  const ChatThread({required this.conversation, required this.messages});

  final ChatConversation conversation;
  final List<ChatMessage> messages;
}

class ReceivedRating {
  const ReceivedRating({
    required this.id,
    required this.stars,
    required this.review,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerPhoto = '',
    required this.reviewerRole,
    required this.createdAt,
  });

  final int id;
  final int stars;
  final String review;
  final int reviewerId;
  final String reviewerName;
  final String reviewerPhoto;
  final String reviewerRole;
  final DateTime? createdAt;

  bool get isOperatorReview => reviewerRole == 'tour_operator';

  String get reviewerPhotoUrl => AuthService.storageUrl(reviewerPhoto);

  String get reviewerTypeLabel =>
      isOperatorReview ? 'Rated by a tour operator' : 'Traveller review';

  factory ReceivedRating.fromJson(Map<String, dynamic> json) {
    return ReceivedRating(
      id: _integer(json['id']),
      stars: _integer(json['stars']),
      review: json['review']?.toString() ?? '',
      reviewerId: _integer(json['reviewer_id']),
      reviewerName:
          json['reviewer_name']?.toString() ??
          json['tourist_name']?.toString() ??
          'Traveller',
      reviewerPhoto:
          json['reviewer_photo']?.toString() ??
          json['tourist_photo']?.toString() ??
          '',
      reviewerRole: json['reviewer_role']?.toString() ?? 'tourist',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class RatingSummary {
  const RatingSummary({
    required this.average,
    required this.count,
    required this.travellerAverage,
    required this.travellerCount,
    required this.operatorAverage,
    required this.operatorCount,
    required this.breakdown,
    required this.ratings,
  });

  final double average;
  final int count;
  final double travellerAverage;
  final int travellerCount;
  final double operatorAverage;
  final int operatorCount;
  final Map<int, int> breakdown;
  final List<ReceivedRating> ratings;

  factory RatingSummary.fromJson(Map<String, dynamic> json) {
    final rawBreakdown = json['breakdown'];
    return RatingSummary(
      average: _number(json['rating_average']),
      count: _integer(json['rating_count']),
      travellerAverage: _number(json['traveller_rating_average']),
      travellerCount: _integer(json['traveller_rating_count']),
      operatorAverage: _number(json['operator_rating_average']),
      operatorCount: _integer(json['operator_rating_count']),
      breakdown:
          rawBreakdown is Map
              ? rawBreakdown.map(
                (key, value) => MapEntry(_integer(key), _integer(value)),
              )
              : const {},
      ratings: _mapList(json['ratings']).map(ReceivedRating.fromJson).toList(),
    );
  }
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

Map<String, String> _stringMap(dynamic value) {
  if (value is! Map) return const {};
  return Map<String, dynamic>.from(value).map(
    (key, item) => MapEntry(key, item?.toString().trim() ?? ''),
  )..removeWhere((_, item) => item.isEmpty);
}

int _integer(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

int? _nullableInteger(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : int.tryParse(text);
}

double _number(dynamic value) => double.tryParse(value?.toString() ?? '') ?? 0;
