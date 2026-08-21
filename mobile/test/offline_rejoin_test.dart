import 'package:aetherride_mobile/data/routing/routing_client.dart';
import 'package:aetherride_mobile/domain/routing/offline_rejoin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('canOfflineRejoin', () {
    test('close enough splices without a graph', () {
      expect(
        canOfflineRejoin(
          needApproach: false,
          graphReady: false,
          routeCovered: false,
        ),
        isTrue,
      );
    });

    test('far off-route needs a covering graph', () {
      expect(
        canOfflineRejoin(
          needApproach: true,
          graphReady: true,
          routeCovered: true,
        ),
        isTrue,
      );
      expect(
        canOfflineRejoin(
          needApproach: true,
          graphReady: false,
          routeCovered: true,
        ),
        isFalse,
      );
      expect(
        canOfflineRejoin(
          needApproach: true,
          graphReady: true,
          routeCovered: false,
        ),
        isFalse,
      );
    });
  });

  test('skipLiveCacheWhenOffline ignores live engines only', () {
    expect(
      skipLiveCacheWhenOffline(
        allowOnline: false,
        cachedEngine: 'graphhopper',
      ),
      isTrue,
    );
    expect(
      skipLiveCacheWhenOffline(
        allowOnline: false,
        cachedEngine: 'offline_graph',
      ),
      isFalse,
    );
    expect(
      skipLiveCacheWhenOffline(
        allowOnline: true,
        cachedEngine: 'graphhopper',
      ),
      isFalse,
    );
  });
}
