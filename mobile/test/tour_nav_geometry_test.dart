import 'package:aetherride_mobile/data/routing/naehe_seeds.dart';
import 'package:aetherride_mobile/domain/routing/route_shape.dart';
import 'package:aetherride_mobile/domain/routing/tour_nav_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('chooseTourNavGeometry', () {
    test('cache wins over track and live', () {
      expect(
        chooseTourNavGeometry(hasCache: true, hasTrack: true, isLoop: true),
        TourNavGeometrySource.cache,
      );
    });

    test('selected track preferred over live for loops', () {
      expect(
        chooseTourNavGeometry(hasCache: false, hasTrack: true, isLoop: true),
        TourNavGeometrySource.track,
        reason: 'Losfahren must keep curated/baked seed geometry',
      );
    });

    test('live only when no cache and no track', () {
      expect(
        chooseTourNavGeometry(hasCache: false, hasTrack: false, isLoop: true),
        TourNavGeometrySource.liveClosed,
      );
    });

    test('degenerate track skips to liveClosed', () {
      expect(
        chooseTourNavGeometry(
          hasCache: false,
          hasTrack: true,
          isLoop: true,
          trackUsable: false,
        ),
        TourNavGeometrySource.liveClosed,
      );
    });
  });

  group('isDegenerateTrack / isUsableMapTrack', () {
    test('two-point A→B is a ruler', () {
      final ab = <List<double>>[
        [8.70, 49.40],
        [8.76, 49.43],
      ];
      expect(isDegenerateTrack(ab), isTrue);
      expect(isUsableMapTrack(ab), isFalse);
    });

    test('open near-colinear polyline is degenerate', () {
      final line = <List<double>>[
        [8.70, 49.40],
        [8.72, 49.405],
        [8.74, 49.41],
        [8.76, 49.415],
        [8.78, 49.42],
      ];
      expect(isDegenerateTrack(line), isTrue);
    });

    test('baked-density closed loop is usable', () {
      final closed = syntheticLoopLngLat(
        lat: 49.4,
        lng: 8.7,
        distanceKm: 12,
        points: 28,
      );
      expect(isDegenerateTrack(closed), isFalse);
      expect(isUsableMapTrack(closed), isTrue);
    });

    test('coarse closed pentagon is degenerate', () {
      final coarse = <List<double>>[
        [8.70, 49.40],
        [8.75, 49.42],
        [8.72, 49.45],
        [8.68, 49.43],
        [8.70, 49.40],
      ];
      expect(isDegenerateTrack(coarse), isTrue);
    });
  });

  group('isAcceptableLiveLoop / navGeometryIsLoop', () {
    test('closed ring accepted; open A→B rejected', () {
      final closed = syntheticLoopLngLat(
        lat: 49.4,
        lng: 8.7,
        distanceKm: 12,
      );
      expect(routeShapeOf(closed), RouteShape.loop);
      expect(
        isAcceptableLiveLoop(trackLngLat: closed, expectedDistanceKm: 12),
        isTrue,
      );
      expect(navGeometryIsLoop(closed), isTrue);

      final open = <List<double>>[
        [8.70, 49.40],
        [8.72, 49.41],
        [8.74, 49.42],
        [8.76, 49.43],
      ];
      expect(routeShapeOf(open), RouteShape.pointToPoint);
      expect(
        isAcceptableLiveLoop(trackLngLat: open, expectedDistanceKm: 12),
        isFalse,
      );
      expect(navGeometryIsLoop(open), isFalse);
    });

    test('hybrid approach+loop polyline is not a loop label', () {
      final loop = syntheticLoopLngLat(
        lat: 49.4,
        lng: 8.7,
        distanceKm: 10,
      );
      // Home → loop entry prepended (Discover hybrid snap).
      final hybrid = <List<double>>[
        [8.65, 49.35],
        [8.67, 49.37],
        ...loop,
      ];
      expect(
        navGeometryIsLoop(hybrid),
        isFalse,
        reason: 'Anfahrt+Runde must not keep Rundkurs on the open merge',
      );
      // Selected tour track alone stays a loop for Navigation.
      expect(navGeometryIsLoop(loop), isTrue);
    });

    test('seed toActiveRoute keeps closed loop + isLoop', () {
      final seed = NaeheSeedRoute.fromJson({
        'id': 'seed-loop-nav-keep',
        'type': 'route',
        'title': 'Nav Keep Loop',
        'distance_km': 14,
        'ascent_m': 120,
        'duration_min': 55,
        'effort_label': 'Mittel',
        'sport_tags': ['gravel'],
        'center': {'lat': 49.41, 'lng': 8.69},
        'is_loop': true,
        'duration_band': '60',
      });
      expect(seed.isLoop, isTrue);
      final track = seed.trackLngLat;
      expect(track, isNotNull);
      expect(routeShapeOf(track), RouteShape.loop);

      final active = seed.toActiveRoute();
      expect(active.isLoop, isTrue);
      expect(navGeometryIsLoop(active.coordinates), isTrue);
      expect(active.id, seed.id);
    });
  });
}
