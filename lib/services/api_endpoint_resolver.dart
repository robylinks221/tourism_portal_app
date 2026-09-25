import 'dart:async';

typedef EndpointProbe = Future<bool> Function(String baseUrl);

class ApiEndpointUnavailable implements Exception {
  const ApiEndpointUnavailable(this.candidates);

  final List<String> candidates;

  @override
  String toString() {
    return 'Cannot reach the Tourism Portal API.';
  }
}

class ApiEndpointResolver {
  ApiEndpointResolver({
    List<String>? candidates,
    EndpointProbe? probe,
    Duration cacheDuration = const Duration(seconds: 15),
  }) : candidates = List.unmodifiable(
         candidates ?? const <String>['http://127.0.0.1:8000/api'],
       );

  static final ApiEndpointResolver instance = ApiEndpointResolver();

  static const String localBaseUrl = 'http://127.0.0.1:8000/api';

  final List<String> candidates;

  String get preferredBaseUrl => localBaseUrl;

  Future<String> resolve() async {
    return localBaseUrl;
  }

  void invalidate([String? failedBaseUrl]) {
    // Nothing to invalidate during USB development.
    //
    // The Android device reaches Laravel through:
    //
    // adb reverse tcp:8000 tcp:8000
  }
}
