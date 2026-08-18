import 'package:flutter_test/flutter_test.dart';
import 'package:tourism_portal_app/services/api_endpoint_resolver.dart';

void main() {
  test('uses the first healthy endpoint even if another probe hangs', () async {
    final resolver = ApiEndpointResolver(
      candidates: const [
        'http://mac.local:8000/api',
        'http://127.0.0.1:8000/api',
      ],
      probe: (baseUrl) async {
        if (baseUrl.contains('mac.local')) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return false;
        }
        return true;
      },
    );

    expect(await resolver.resolve(), 'http://127.0.0.1:8000/api');
  });

  test('caches a healthy endpoint and probes it again after invalidation', () async {
    var probes = 0;
    final resolver = ApiEndpointResolver(
      candidates: const ['http://mac.local:8000/api'],
      probe: (_) async {
        probes += 1;
        return true;
      },
    );

    expect(await resolver.resolve(), 'http://mac.local:8000/api');
    expect(await resolver.resolve(), 'http://mac.local:8000/api');
    expect(probes, 1);

    resolver.invalidate('http://mac.local:8000/api');
    expect(await resolver.resolve(), 'http://mac.local:8000/api');
    expect(probes, 2);
  });

  test('throws only after every candidate is unavailable', () async {
    final resolver = ApiEndpointResolver(
      candidates: const [
        'http://mac.local:8000/api',
        'http://127.0.0.1:8000/api',
      ],
      probe: (_) async => false,
    );

    await expectLater(
      resolver.resolve(),
      throwsA(isA<ApiEndpointUnavailable>()),
    );
  });
}
