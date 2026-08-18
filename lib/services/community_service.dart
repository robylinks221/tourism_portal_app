import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/community.dart';
import 'api_endpoint_resolver.dart';
import 'api_exception.dart';
import 'auth_service.dart';

class CommunityService {
  CommunityService._();

  static final CommunityService instance = CommunityService._();

  static const Duration _timeout = Duration(seconds: 20);

  // ==============================================================
  // LOGIN PAGE AVATARS
  // ==============================================================

  Future<List<LoginCommunityAvatar>> fetchLoginAvatars() async {
    final data = await _request(
      'GET',
      '/community/login-avatars',
      authenticated: false,
    );

    return _maps(data['avatars']).map(LoginCommunityAvatar.fromJson).toList();
  }

  // ==============================================================
  // GUEST PROVIDERS
  // ==============================================================
  //
  // Public guest-safe provider endpoint.
  //
  // Laravel does NOT return:
  // - phone
  // - email
  // - social links
  // - private address
  // - private gallery
  // - contact person
  //
  // Guests can therefore browse provider previews safely.
  //

  Future<FeaturedProviders> fetchGuestProviders() async {
    final data = await _request(
      'GET',
      '/community/guest-providers',
      authenticated: false,
    );

    return FeaturedProviders.fromJson(data);
  }

  // ==============================================================
  // AUTHENTICATED COMMUNITY MEMBERS
  // ==============================================================

  Future<List<CommunityMember>> fetchMembers() async {
    final data = await _request('GET', '/community/members');

    return _maps(data['members']).map(CommunityMember.fromJson).toList();
  }

  // ==============================================================
  // FEATURED PROVIDERS
  // ==============================================================

  Future<FeaturedProviders> fetchFeaturedProviders() async {
    final data = await _request('GET', '/community/featured-providers');

    return FeaturedProviders.fromJson(data);
  }

  // ==============================================================
  // INDIVIDUAL PROVIDER PROFILE
  // ==============================================================

  Future<CommunityMember> fetchMember(int memberId) async {
    final data = await _request(
      'GET',
      '/community/members/$memberId',
      authenticated: false,
    );

    final member = data['member'];

    if (member is! Map) {
      throw const ApiException('The provider profile could not be loaded.');
    }

    return CommunityMember.fromJson(Map<String, dynamic>.from(member));
  }

  // ==============================================================
  // SUBMIT / UPDATE RATING
  // ==============================================================

  // ==============================================================
  // PUBLIC TOURIST PROFILE
  // ==============================================================

  Future<CommunityMember> fetchTourist(int touristId) async {
    final data = await _request(
      'GET',
      '/community/tourists/$touristId',
      authenticated: false,
    );

    final member = data['member'];

    if (member is! Map) {
      throw const ApiException('The tourist profile could not be loaded.');
    }

    return CommunityMember.fromJson(Map<String, dynamic>.from(member));
  }

  Future<void> submitRating({
    required int memberId,
    required int stars,
    required String review,
  }) async {
    await _request(
      'POST',
      '/community/members/$memberId/rating',
      body: {'stars': stars, 'review': review.trim()},
    );
  }

  // ==============================================================
  // CURRENT USER RATINGS
  // ==============================================================

  Future<RatingSummary> fetchMyRatings() async {
    final data = await _request('GET', '/community/my-ratings');

    return RatingSummary.fromJson(data);
  }

  // ==============================================================
  // PROVIDER RATINGS
  // ==============================================================

  Future<RatingSummary> fetchMemberRatings(int memberId) async {
    final data = await _request(
      'GET',
      '/community/members/$memberId/ratings',
      authenticated: false,
    );

    return RatingSummary.fromJson(data);
  }

  // ==============================================================
  // CHAT CONVERSATIONS
  // ==============================================================

  Future<List<ChatConversation>> fetchConversations() async {
    final data = await _request('GET', '/chat/conversations');

    return _maps(data['conversations']).map(ChatConversation.fromJson).toList();
  }

  // ==============================================================
  // START CONVERSATION
  // ==============================================================

  Future<ChatConversation> startConversation(int participantId) async {
    final data = await _request(
      'POST',
      '/chat/conversations',
      body: {'participant_id': participantId},
    );

    final conversation = data['conversation'];

    if (conversation is! Map) {
      throw const ApiException('The conversation could not be opened.');
    }

    return ChatConversation.fromJson(Map<String, dynamic>.from(conversation));
  }

  // ==============================================================
  // FETCH CHAT MESSAGES
  // ==============================================================

  Future<ChatThread> fetchMessages(int conversationId) async {
    final data = await _request(
      'GET',
      '/chat/conversations/$conversationId/messages',
    );

    final conversation = data['conversation'];

    if (conversation is! Map) {
      throw const ApiException('The conversation response was unreadable.');
    }

    return ChatThread(
      conversation: ChatConversation.fromJson(
        Map<String, dynamic>.from(conversation),
      ),
      messages: _maps(data['messages']).map(ChatMessage.fromJson).toList(),
    );
  }

  // ==============================================================
  // SEND CHAT MESSAGE
  // ==============================================================

  Future<ChatMessage> sendMessage({
    required int conversationId,
    required String body,
  }) async {
    final data = await _request(
      'POST',
      '/chat/conversations/$conversationId/messages',
      body: {'body': body.trim()},
    );

    final message = data['message'];

    if (message is! Map) {
      throw const ApiException('The sent message response was unreadable.');
    }

    return ChatMessage.fromJson(Map<String, dynamic>.from(message));
  }

  // ==============================================================
  // CENTRAL REQUEST HANDLER
  // ==============================================================

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    String? requestBaseUrl;

    try {
      // Resolve the currently reachable Laravel API.
      requestBaseUrl = await AuthService.instance.resolveBaseUrl();

      final uri = Uri.parse('$requestBaseUrl$path');

      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      // Add Sanctum token only when required.
      if (authenticated) {
        final token = await AuthService.instance.requireToken();

        headers['Authorization'] = 'Bearer $token';
      }

      late http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(_timeout);

          break;

        case 'POST':
          response = await http
              .post(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(_timeout);

          break;

        case 'PUT':
          response = await http
              .put(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(_timeout);

          break;

        case 'DELETE':
          response = await http
              .delete(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(_timeout);

          break;

        default:
          throw ApiException('Unsupported request method: $method');
      }

      // ==========================================================
      // DECODE RESPONSE
      // ==========================================================

      final dynamic decoded;

      if (response.body.trim().isEmpty) {
        decoded = <String, dynamic>{};
      } else {
        decoded = jsonDecode(response.body);
      }

      final data =
          decoded is Map
              ? Map<String, dynamic>.from(decoded)
              : <String, dynamic>{};

      // ==========================================================
      // SUCCESS
      // ==========================================================

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }

      // ==========================================================
      // API ERROR
      // ==========================================================

      throw ApiException(
        _message(data, response.statusCode),
        statusCode: response.statusCode,
      );
    } on ApiException {
      rethrow;
    } on ApiEndpointUnavailable {
      throw const ApiException('Cannot reach the community service.');
    } on SocketException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);

      throw const ApiException('The community connection was interrupted.');
    } on TimeoutException {
      ApiEndpointResolver.instance.invalidate(requestBaseUrl);

      throw const ApiException('The community request timed out.');
    } on FormatException {
      throw const ApiException('The community response was unreadable.');
    } on http.ClientException {
      throw const ApiException('The community request failed.');
    } catch (_) {
      throw const ApiException(
        'Something went wrong while communicating with the community service.',
      );
    }
  }

  // ==============================================================
  // JSON LIST HELPER
  // ==============================================================

  static List<Map<String, dynamic>> _maps(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // ==============================================================
  // API ERROR MESSAGE HELPER
  // ==============================================================

  static String _message(Map<String, dynamic> data, int statusCode) {
    final errors = data['errors'];

    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }

        if (value != null) {
          return value.toString();
        }
      }
    }

    final message = data['message'];

    if (message != null && message.toString().trim().isNotEmpty) {
      return message.toString();
    }

    return 'Request failed (HTTP $statusCode).';
  }
}

// ==================================================================
// LOGIN COMMUNITY AVATAR
// ==================================================================

class LoginCommunityAvatar {
  const LoginCommunityAvatar({
    required this.id,
    required this.name,
    required this.role,
    required this.profilePhoto,
  });

  final int id;
  final String name;
  final String role;
  final String profilePhoto;

  // ==============================================================
  // FULL PHOTO URL
  // ==============================================================

  String get profilePhotoUrl {
    if (profilePhoto.trim().isEmpty) {
      return '';
    }

    return AuthService.storageUrl(profilePhoto);
  }

  // ==============================================================
  // JSON
  // ==============================================================

  factory LoginCommunityAvatar.fromJson(Map<String, dynamic> json) {
    return LoginCommunityAvatar(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,

      name: json['name']?.toString() ?? '',

      role: json['role']?.toString() ?? '',

      profilePhoto: json['profile_photo']?.toString() ?? '',
    );
  }
}
