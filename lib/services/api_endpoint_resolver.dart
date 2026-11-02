import 'dart:async';

typedef EndpointProbe = Future<bool> Function(String baseUrl);

class ApiEndpointUnavailable implements Exception {
  const ApiEndpointUnavailable(this.candidates);
  final List<String> candidates;
  @override
  String toString() => 'Cannot reach the Tourism Portal API.';
}

class ApiEndpointResolver {
  ApiEndpointResolver({
    List<String>? candidates,
    EndpointProbe? probe,
    Duration cacheDuration = const Duration(seconds: 15),
  }) : candidates = List.unmodifiable(
         candidates ?? const <String>[productionBaseUrl],
       );

  static const String productionBaseUrl =
      'https://touristguideapi.robylinks.com/api';
  // Retained for compatibility with existing references; now points to production.
  static const String localBaseUrl = productionBaseUrl;
  static final ApiEndpointResolver instance = ApiEndpointResolver();
  final List<String> candidates;
  String get preferredBaseUrl => productionBaseUrl;
  Future<String> resolve() async => productionBaseUrl;
  void invalidate([String? failedBaseUrl]) {}
}
