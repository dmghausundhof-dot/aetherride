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
      expect(shouldPaintDiscoverRibbon(ab), isFalse);
    });

    test('heading overlay and separate approach never paint as tour-green', () {
      final loop = syntheticLoopLngLat(
        lat: 49.4,
        lng: 8.7,
        distanceKm: 12,
        points: 28,
      );
      expect(
        shouldPaintActiveComputedRibbon(
          trackLngLat: loop,
          isHeadingOrDemoOverlay: true,
          approachPaintedSeparately: false,
        ),
        isFalse,
      );
      expect(
        shouldPaintActiveComputedRibbon(
          trackLngLat: loop,
          isHeadingOrDemoOverlay: false,
          approachPaintedSeparately: true,
        ),
        isFalse,
      );
      expect(
        shouldPaintActiveComputedRibbon(
          trackLngLat: loop,
          isHeadingOrDemoOverlay: false,
          approachPaintedSeparately: false,
        ),
        isTrue,
      );
    });

    test('Trailforks TF pin without track stays off the map', () {
      expect(shouldDrawTrailforksMapPin(), isFalse);
      expect(shouldDrawTrailforksMapPin(trackLngLat: const []), isFalse);
      expect(
        shouldDrawTrailforksMapPin(
          trackLngLat: [
            [8.70, 49.40],
            [8.76, 49.43],
          ],
        ),
        isFalse,
      );
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

    test('tourNeedsApproachFromGps at 200 m', () {
      expect(tourNeedsApproachFromGps(199), isFalse);
      expect(tourNeedsApproachFromGps(200.1), isTrue);
      expect(tourNeedsApproachFromGps(double.infinity), isFalse);
    });

    test('mergeApproachAndTour prepends approach and keeps remaining length',
        () {
      final tour = <List<double>>[
        [8.70, 49.40],
        [8.71, 49.41],
        [8.72, 49.42],
        [8.70, 49.40],
      ];
      final approach = <List<double>>[
        [8.67, 49.28],
        [8.68, 49.34],
        [8.70, 49.40],
      ];
      final merged = mergeApproachAndTour(
        approachLngLat: approach,
        tourLngLat: tour,
        joinIndex: 0,
      );
      expect(merged.coordinates.first, approach.first);
      expect(merged.coordinates.length, approach.length + tour.length);
      expect(merged.remainM, greaterThan(1000));
      expect(navGeometryIsLoop(merged.coordinates), isFalse);
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

    test('catalog Baden-Baden matches Lichtental seed even from Freiburg pin',
        () {
      expect(
        catalogMatchesBundledSeed(
          catalogName: 'Baden-Baden Lichtental Loop',
          catalogLat: 47.99,
          catalogLng: 7.85,
          catalogDistanceKm: 16,
          seedTitle: 'Baden-Baden — Lichtentaler Allee',
          seedLat: 48.761,
          seedLng: 8.24,
          seedDistanceKm: 16,
        ),
        isTrue,
      );
      expect(
        alignedPlaceTokenCount(
          'Baden-Baden Lichtental Loop',
          'Baden-Baden — Lichtentaler Allee',
        ),
        greaterThanOrEqualTo(2),
      );
    });

    test('Wiesbaden seed does not steal Baden-Baden catalog', () {
      expect(
        catalogMatchesBundledSeed(
          catalogName: 'Baden-Baden Lichtental Loop',
          catalogLat: 47.99,
          catalogLng: 7.85,
          catalogDistanceKm: 16,
          seedTitle: 'Wiesbaden — Neroberg & Kurpark',
          seedLat: 50.085,
          seedLng: 8.224,
          seedDistanceKm: 14,
        ),
        isFalse,
      );
    });

    test('nearby unnamed pin matches by distance + km', () {
      expect(
        catalogMatchesBundledSeed(
          catalogName: 'Feierabend Runde',
          catalogLat: 49.295,
          catalogLng: 8.698,
          catalogDistanceKm: 18,
          seedTitle: 'Wiesloch Ortsrunde',
          seedLat: 49.297,
          seedLng: 8.701,
          seedDistanceKm: 17,
        ),
        isTrue,
      );
    });

    test('pickBundledSeedForCatalog prefers name match over nearer other seed',
        () {
      final closed = syntheticLoopLngLat(
        lat: 48.761,
        lng: 8.24,
        distanceKm: 16,
        points: 28,
      );
      final other = syntheticLoopLngLat(
        lat: 47.99,
        lng: 7.85,
        distanceKm: 16,
        points: 28,
      );
      final hit = pickBundledSeedForCatalog(
        catalogName: 'Baden-Baden Lichtental Loop',
        catalogLat: 47.99,
        catalogLng: 7.85,
        catalogDistanceKm: 16,
        seeds: [
          (
            title: 'Freiburg Dreisam',
            lat: 47.99,
            lng: 7.85,
            distanceKm: 16,
            trackLngLat: other,
          ),
          (
            title: 'Baden-Baden — Lichtentaler Allee',
            lat: 48.761,
            lng: 8.24,
            distanceKm: 16,
            trackLngLat: closed,
          ),
        ],
      );
      expect(hit, isNotNull);
      expect(hit!.lat, closeTo(48.761, 0.001));
      expect(hit.trackLngLat, closed);
    });

    test('map tap does not steal B while typing or after A+B', () {
      expect(
        mapTapMaySetAbPoint(
          addressFieldFocused: true,
          startSet: true,
          endSet: true,
          explicitlyPicking: false,
        ),
        isFalse,
      );
      expect(
        mapTapMaySetAbPoint(
          addressFieldFocused: false,
          startSet: true,
          endSet: true,
          explicitlyPicking: false,
        ),
        isFalse,
      );
      expect(
        mapTapMaySetAbPoint(
          addressFieldFocused: false,
          startSet: true,
          endSet: false,
          explicitlyPicking: false,
        ),
        isTrue,
      );
      expect(
        mapTapMaySetAbPoint(
          addressFieldFocused: false,
          startSet: true,
          endSet: true,
          explicitlyPicking: true,
        ),
        isTrue,
      );
    });

    test('Frauenweiler→Wiesloch 16 km triangle is an implausible A→B', () {
      expect(
        isImplausibleAbDetour(
          distanceM: 16000,
          fromLat: 49.27967,
          fromLng: 8.67013,
          toLat: 49.29426,
          toLng: 8.69871,
        ),
        isTrue,
      );
      expect(
        isImplausibleAbDetour(
          distanceM: 3400,
          fromLat: 49.27967,
          fromLng: 8.67013,
          toLat: 49.29426,
          toLng: 8.69871,
        ),
        isFalse,
        reason: 'GraphHopper bike 3.4 km for 2.6 km crow is efficient',
      );
    });

    test('start≈end loop is not judged as A→B detour', () {
      expect(
        isImplausibleAbDetour(
          distanceM: 16000,
          fromLat: 49.294,
          fromLng: 8.699,
          toLat: 49.294,
          toLng: 8.699,
        ),
        isFalse,
      );
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

  group('plannedRouteHudLabel', () {
    test('uses destination name, not generic Geplante Route', () {
      expect(
        plannedRouteHudLabel(
          destinationField: 'Wiesloch',
          plannedFallback: 'Geplante Route',
          suggestEndPlaceholder: 'Ziel-Vorschlag (anpassbar)',
        ),
        'Wiesloch',
      );
    });

    test('falls back for empty, placeholder, or raw coords', () {
      expect(
        plannedRouteHudLabel(
          destinationField: '',
          plannedFallback: 'Geplante Route',
          suggestEndPlaceholder: 'Ziel-Vorschlag (anpassbar)',
        ),
        'Geplante Route',
      );
      expect(
        plannedRouteHudLabel(
          destinationField: 'Ziel-Vorschlag (anpassbar)',
          plannedFallback: 'Geplante Route',
          suggestEndPlaceholder: 'Ziel-Vorschlag (anpassbar)',
        ),
        'Geplante Route',
      );
      expect(
        plannedRouteHudLabel(
          destinationField: '49.29, 8.69',
          plannedFallback: 'Geplante Route',
          suggestEndPlaceholder: 'Ziel-Vorschlag (anpassbar)',
        ),
        'Geplante Route',
      );
    });
  });
}
