import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/data/routing/routing_client.dart';

void main() {
  test('isOfflineRoutingEngine recognizes native engines only', () {
    expect(isOfflineRoutingEngine('offline_graph'), isTrue);
    expect(isOfflineRoutingEngine('valhalla'), isTrue);
    expect(isOfflineRoutingEngine('OFFLINE_GRAPH'), isTrue);
    expect(isOfflineRoutingEngine('graphhopper'), isFalse);
    expect(isOfflineRoutingEngine('openrouteservice'), isFalse);
    expect(isOfflineRoutingEngine('fallback-line'), isFalse);
    expect(isOfflineRoutingEngine(null), isFalse);
    expect(isOfflineRoutingEngine(''), isFalse);
  });

  test('skipLiveCacheForOfflinePack only after a newer pack stamp', () {
    final cached = DateTime.utc(2026, 8, 19, 0, 0);
    final activated = DateTime.utc(2026, 8, 19, 1, 0);
    expect(
      skipLiveCacheForOfflinePack(
        cacheFetchedAt: cached,
        packActivatedAt: activated,
        cachedEngine: 'graphhopper',
        ffiAvailable: true,
        viasEmpty: true,
      ),
      isTrue,
    );
    expect(
      skipLiveCacheForOfflinePack(
        cacheFetchedAt: cached,
        packActivatedAt: activated,
        cachedEngine: 'offline_graph',
        ffiAvailable: true,
        viasEmpty: true,
      ),
      isFalse,
    );
    expect(
      skipLiveCacheForOfflinePack(
        cacheFetchedAt: DateTime.utc(2026, 8, 19, 2, 0),
        packActivatedAt: activated,
        cachedEngine: 'graphhopper',
        ffiAvailable: true,
        viasEmpty: true,
      ),
      isFalse,
    );
    expect(
      skipLiveCacheForOfflinePack(
        cacheFetchedAt: cached,
        packActivatedAt: activated,
        cachedEngine: 'graphhopper',
        ffiAvailable: false,
        viasEmpty: true,
      ),
      isFalse,
    );
    expect(
      skipLiveCacheForOfflinePack(
        cacheFetchedAt: cached,
        packActivatedAt: activated,
        cachedEngine: 'graphhopper',
        ffiAvailable: true,
        viasEmpty: false,
      ),
      isFalse,
    );
  });

  test('shouldAttemptOfflineGraphFirst needs coverage or a switch', () {
    expect(
      shouldAttemptOfflineGraphFirst(
        planned: true,
        viasEmpty: true,
        activePackCovers: false,
        switchedToCoveringPack: false,
      ),
      isFalse,
    );
    expect(
      shouldAttemptOfflineGraphFirst(
        planned: true,
        viasEmpty: true,
        activePackCovers: true,
        switchedToCoveringPack: false,
      ),
      isTrue,
    );
    expect(
      shouldAttemptOfflineGraphFirst(
        planned: true,
        viasEmpty: true,
        activePackCovers: false,
        switchedToCoveringPack: true,
      ),
      isTrue,
    );
    expect(
      shouldAttemptOfflineGraphFirst(
        planned: true,
        viasEmpty: false,
        activePackCovers: true,
        switchedToCoveringPack: false,
      ),
      isTrue,
    );
    expect(
      shouldAttemptOfflineGraphFirst(
        planned: false,
        viasEmpty: true,
        activePackCovers: true,
        switchedToCoveringPack: false,
      ),
      isFalse,
    );
    expect(
      shouldAttemptOfflineGraphFirst(
        planned: true,
        viasEmpty: true,
        activePackCovers: true,
        switchedToCoveringPack: false,
        allowOfflineFirst: false,
      ),
      isFalse,
    );
  });

  test('shouldFallbackOfflineAfterOnlineFail needs coverage, not vias', () {
    expect(
      shouldFallbackOfflineAfterOnlineFail(
        planned: true,
        viasEmpty: true,
        packCoversOrSwitched: true,
      ),
      isTrue,
    );
    expect(
      shouldFallbackOfflineAfterOnlineFail(
        planned: true,
        viasEmpty: true,
        packCoversOrSwitched: true,
        allowOfflineFallback: false,
      ),
      isFalse,
    );
    expect(
      shouldFallbackOfflineAfterOnlineFail(
        planned: true,
        viasEmpty: true,
        packCoversOrSwitched: false,
      ),
      isFalse,
    );
    expect(
      shouldFallbackOfflineAfterOnlineFail(
        planned: true,
        viasEmpty: false,
        packCoversOrSwitched: true,
      ),
      isTrue,
    );
    expect(
      shouldFallbackOfflineAfterOnlineFail(
        planned: false,
        viasEmpty: true,
        packCoversOrSwitched: true,
      ),
      isFalse,
    );
  });

  test('isOfflineNoRouteError matches the client sentinel', () {
    expect(isOfflineNoRouteError(StateError('offline-no-route')), isTrue);
    expect(isOfflineNoRouteError(StateError('timeout')), isFalse);
    expect(
      isOfflineNoRouteError(StateError('offline-vias-need-network')),
      isFalse,
    );
  });

  test('isOfflineViasNeedNetworkError matches the vias sentinel', () {
    expect(
      isOfflineViasNeedNetworkError(StateError('offline-vias-need-network')),
      isTrue,
    );
    expect(
      isOfflineViasNeedNetworkError(StateError('offline-no-route')),
      isFalse,
    );
  });

  test('onlineRouteTimeout shortens only when Dijkstra can take over', () {
    expect(
      onlineRouteTimeout(
        planned: true,
        viasEmpty: true,
        allowOfflineFallback: true,
        packMayCover: true,
      ),
      kOnlineRouteTimeoutWithOfflineFallback,
    );
    expect(
      onlineRouteTimeout(
        planned: true,
        viasEmpty: true,
        allowOfflineFallback: true,
      ),
      kOnlineRouteTimeout,
    );
    expect(
      onlineRouteTimeout(
        planned: true,
        viasEmpty: false,
        allowOfflineFallback: true,
        packMayCover: true,
      ),
      kOnlineRouteTimeoutWithOfflineFallback,
    );
    expect(
      onlineRouteTimeout(
        planned: false,
        viasEmpty: true,
        allowOfflineFallback: true,
        packMayCover: true,
      ),
      kOnlineRouteTimeout,
    );
    expect(
      onlineRouteTimeout(
        planned: true,
        viasEmpty: true,
        allowOfflineFallback: false,
        packMayCover: true,
      ),
      kBrowseLiveRouteTimeout,
    );
  });

  test('joinOfflineRouteLegs stitches via legs without duplicating the join',
      () {
    const a = GeoPoint(49.0, 8.0);
    const b = GeoPoint(49.1, 8.1);
    const c = GeoPoint(49.2, 8.2);
    final joined = joinOfflineRouteLegs([
      const RouteResult(
        coordinates: [a, b],
        distanceM: 100,
        durationS: 20,
        engine: 'offline_graph',
      ),
      const RouteResult(
        coordinates: [b, c],
        distanceM: 80,
        durationS: 16,
        engine: 'offline_graph',
      ),
    ]);
    expect(joined.coordinates.length, 3);
    expect(joined.coordinates.first.lat, a.lat);
    expect(joined.coordinates.last.lng, c.lng);
    expect(joined.distanceM, 180);
    expect(joined.durationS, 36);
    expect(joined.engine, 'offline_graph');
  });
}
