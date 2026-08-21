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

    test('pan-end and pin bounce do not place A/B', () {
      final t0 = DateTime.utc(2026, 8, 18, 22);
      expect(
        mapTapLooksLikeCameraGesture(
          now: t0,
          cameraMoving: true,
          cameraMovedAt: t0,
        ),
        isTrue,
      );
      expect(
        mapTapLooksLikeCameraGesture(
          now: t0.add(const Duration(milliseconds: 120)),
          cameraMoving: false,
          cameraMovedAt: t0,
        ),
        isTrue,
      );
      expect(
        mapTapLooksLikeCameraGesture(
          now: t0.add(const Duration(milliseconds: 400)),
          cameraMoving: false,
          cameraMovedAt: t0,
        ),
        isFalse,
      );
      expect(
        mapTapTooSoonAfterLastPin(
          now: t0.add(const Duration(milliseconds: 200)),
          lastPinAt: t0,
        ),
        isTrue,
      );
      expect(
        mapTapMayPlaceRoutePin(
          addressFieldFocused: false,
          startSet: true,
          endSet: false,
          explicitlyPicking: true,
          cameraMoving: false,
          cameraMovedAt: t0,
          lastPinAt: null,
          now: t0.add(const Duration(milliseconds: 80)),
        ),
        isFalse,
      );
      expect(
        mapTapMayPlaceRoutePin(
          addressFieldFocused: false,
          startSet: true,
          endSet: false,
          explicitlyPicking: true,
          cameraMoving: false,
          cameraMovedAt: t0.subtract(const Duration(seconds: 2)),
          lastPinAt: t0.subtract(const Duration(seconds: 2)),
          now: t0,
        ),
        isTrue,
      );
      expect(kMapPinRouteCommitDelay.inMilliseconds, 450);
    });

    test('short tap places a route pin only in explicit pick mode', () {
      final t0 = DateTime.utc(2026, 8, 19, 12);
      final quiet = t0.subtract(const Duration(seconds: 2));
      expect(
        mapShortTapPlacesRoutePin(
          explicitlyPicking: false,
          planSurface: true,
          addressFieldFocused: false,
          startSet: true,
          endSet: false,
          cameraMoving: false,
          cameraMovedAt: quiet,
          lastPinAt: quiet,
          now: t0,
        ),
        isFalse,
        reason: 'Open plan without pick mode is still browse',
      );
      expect(
        mapShortTapPlacesRoutePin(
          explicitlyPicking: true,
          planSurface: false,
          addressFieldFocused: false,
          startSet: false,
          endSet: false,
          cameraMoving: false,
          cameraMovedAt: quiet,
          lastPinAt: quiet,
          now: t0,
        ),
        isFalse,
        reason: 'Explore short tap never drops A/B',
      );
      expect(
        mapShortTapPlacesRoutePin(
          explicitlyPicking: true,
          planSurface: true,
          addressFieldFocused: false,
          startSet: true,
          endSet: true,
          cameraMoving: false,
          cameraMovedAt: quiet,
          lastPinAt: quiet,
          now: t0,
        ),
        isTrue,
        reason: 'Start/Ziel auf Karte may place that one point',
      );
      expect(
        mapTapMayPlaceRoutePin(
          addressFieldFocused: false,
          startSet: false,
          endSet: false,
          explicitlyPicking: false,
          cameraMoving: false,
          cameraMovedAt: quiet,
          lastPinAt: quiet,
          now: t0,
        ),
        isTrue,
        reason: 'Long-press may start A then B without pick mode',
      );
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

    test('tour preview line is seed/catalog, not live A→B', () {
      expect(isTourPreviewLine('seed-loop'), isTrue);
      expect(isTourPreviewLine('seed-loop-routed'), isTrue);
      expect(isTourPreviewLine('tour-adopt'), isTrue);
      expect(isTourPreviewLine('graphhopper'), isFalse);
      expect(isTourPreviewLine('openrouteservice'), isFalse);
    });

    test('new pin after a selected tour drops the leftover preview', () {
      expect(
        mapPinClearsTourPreview(
          computedEngine: 'seed-loop',
          selectedTourId: 'tour-1',
        ),
        isTrue,
      );
      expect(
        mapPinClearsTourPreview(
          computedEngine: 'graphhopper',
          selectedTourId: 'tour-1',
        ),
        isTrue,
        reason: 'even after GPS→tour, a new pin must drop the tour ribbon',
      );
      expect(
        mapPinClearsTourPreview(
          computedEngine: 'graphhopper',
          selectedTourId: null,
        ),
        isFalse,
      );
      expect(
        mapPinClearsLeftoverRoute(
          computedEngine: 'graphhopper',
          selectedTourId: null,
          hasComputedLine: true,
        ),
        isFalse,
        reason:
            'live A–B stays; far tap replaces dest, tap on the line inserts a via',
      );
      expect(
        mapPinClearsLeftoverRoute(
          computedEngine: null,
          selectedTourId: null,
          hasComputedLine: false,
        ),
        isFalse,
      );
      expect(
        shouldHideDiscoverTourRibbons(
          navigateMode: true,
          hasStart: true,
          hasEnd: false,
        ),
        isTrue,
      );
      expect(
        shouldHideDiscoverTourRibbons(
          navigateMode: true,
          hasStart: true,
          hasEnd: true,
        ),
        isTrue,
      );
      expect(
        shouldHideDiscoverTourRibbons(
          navigateMode: false,
          hasStart: true,
          hasEnd: true,
        ),
        isTrue,
        reason: 'A–B hides leftover catalog ribbons after leaving Navigieren',
      );
      expect(
        shouldHideDiscoverTourRibbons(
          navigateMode: false,
          hasStart: false,
          hasEnd: true,
        ),
        isTrue,
        reason: 'dest-only pin hides leftover catalog ribbons',
      );
      expect(
        shouldPaintPendingAbHint(
          hasFrom: true,
          hasEnd: true,
          hasLiveLine: false,
        ),
        isFalse,
        reason: 'crow-flies through fields is not a street line',
      );
      expect(
        waitingForLiveDiscoverAb(
          hasFrom: true,
          hasEnd: true,
          hasLiveLine: false,
        ),
        isTrue,
      );
      expect(
        shouldPaintPendingAbHint(
          hasFrom: true,
          hasEnd: true,
          hasLiveLine: true,
        ),
        isFalse,
      );
      expect(
        shouldHideFarmTracksOnBrowse(
          navigateMode: false,
          loading: false,
          hasPendingAbHint: false,
        ),
        isFalse,
        reason: 'leftover dest on Explore keeps OSM farm tracks',
      );
      expect(
        shouldHideFarmTracksOnBrowse(
          navigateMode: true,
          loading: false,
          hasPendingAbHint: false,
        ),
        isTrue,
      );
      expect(
        shouldHideFarmTracksOnBrowse(
          navigateMode: false,
          loading: true,
          hasPendingAbHint: false,
        ),
        isTrue,
      );
      expect(
        shouldHideFarmTracksOnBrowse(
          navigateMode: false,
          loading: false,
          hasPendingAbHint: true,
        ),
        isTrue,
      );
      expect(
        shouldShowLiveRouteStats(
          hasLiveLine: true,
          engine: 'graphhopper',
          coordinateCount: 12,
        ),
        isTrue,
      );
      expect(
        shouldShowLiveRouteStats(
          hasLiveLine: true,
          engine: 'graphhopper',
          coordinateCount: 2,
        ),
        isFalse,
        reason: 'crow-flies is not a street line',
      );
      expect(
        shouldShowLiveRouteStats(
          hasLiveLine: true,
          engine: 'fallback-line',
          coordinateCount: 8,
        ),
        isFalse,
      );
      expect(
        discoverBrowsePinCue(
          hasStart: false,
          hasEnd: true,
          hasGps: false,
        ),
        DiscoverBrowsePinCue.waitingGpsForStart,
      );
      expect(
        discoverBrowsePinCue(
          hasStart: true,
          hasEnd: true,
          hasGps: true,
        ),
        DiscoverBrowsePinCue.computing,
      );
      expect(
        shouldShowDiscoverTourPois(
          hideRibbons: true,
          hasSelectedTour: true,
          computedEngine: 'tour-adopt',
        ),
        isTrue,
        reason: 'tour preview keeps plates while A–B chrome is off',
      );
      expect(
        shouldShowDiscoverTourPois(
          hideRibbons: true,
          hasSelectedTour: true,
          computedEngine: 'graphhopper',
        ),
        isFalse,
        reason: 'live A–B does not inherit leftover seed plates',
      );
      expect(
        shouldShowDiscoverTourPois(
          hideRibbons: false,
          hasSelectedTour: true,
          computedEngine: null,
        ),
        isTrue,
      );
      expect(
        routingOriginPreferGps(
          userLat: 49.41,
          userLng: 8.69,
          startLat: 49.30,
          startLng: 8.60,
        ),
        (lat: 49.41, lng: 8.69),
      );
      expect(
        routingOriginPreferGps(startLat: 49.30, startLng: 8.60),
        (lat: 49.30, lng: 8.60),
      );
      expect(routingOriginPreferGps(), isNull);
      expect(
        mapPinAfterTourPreviewIsDestination(
          tourPreviewOnMap: true,
          hasGps: true,
        ),
        isTrue,
        reason: 'tour adopt must not keep the tour start after a new dest pin',
      );
      expect(
        mapPinAfterTourPreviewIsDestination(
          tourPreviewOnMap: false,
          hasGps: true,
        ),
        isFalse,
      );
      expect(
        mapPinIsGpsDestination(
          tourPreviewOnMap: false,
          hasGps: true,
          startSet: false,
          endSet: false,
          pickingStart: false,
        ),
        isTrue,
        reason: 'browse pin with GPS is dest, not a start in a field',
      );
      expect(
        mapPinIsGpsDestination(
          tourPreviewOnMap: false,
          hasGps: false,
          startSet: false,
          endSet: false,
          pickingStart: false,
        ),
        isTrue,
        reason: 'without GPS the pin is still dest, not a start in a field',
      );
      expect(
        mapPinIsGpsDestination(
          tourPreviewOnMap: false,
          hasGps: true,
          startSet: true,
          endSet: true,
          pickingStart: false,
        ),
        isTrue,
        reason: 'second pin after A–B replaces dest, not a via',
      );
      expect(
        mapPinIsGpsDestination(
          tourPreviewOnMap: false,
          hasGps: false,
          startSet: false,
          endSet: true,
          pickingStart: false,
        ),
        isTrue,
        reason: 'dest-only: another pin replaces dest, not a field start',
      );
      expect(
        mapPinIsGpsDestination(
          tourPreviewOnMap: false,
          hasGps: true,
          startSet: false,
          endSet: false,
          pickingStart: true,
        ),
        isFalse,
      );
      expect(
        mapPinIsGpsDestination(
          tourPreviewOnMap: false,
          leftoverRoute: true,
          hasGps: true,
          startSet: true,
          endSet: true,
          pickingStart: false,
        ),
        isTrue,
        reason: 'new pin after leftover A–B is GPS → pin, not a via',
      );
      expect(mapLongPressAddsVia(explicitlyPickingVia: false), isFalse);
      expect(mapLongPressAddsVia(explicitlyPickingVia: true), isTrue);
    });

    test('pin-only compute is GPS/start → pin, not a field offset', () {
      expect(
        pinOnlyAbEndpoints(
          pinLat: 49.40,
          pinLng: 8.70,
        ),
        isNull,
      );
      final fromGps = pinOnlyAbEndpoints(
        pinLat: 49.40,
        pinLng: 8.70,
        userLat: 49.41,
        userLng: 8.69,
      );
      expect(fromGps, isNotNull);
      expect(fromGps!.endLat, 49.40);
      expect(fromGps.endLng, 8.70);
      expect(fromGps.startLat, 49.41);
      expect(fromGps.startLng, 8.69);
      final fromStart = pinOnlyAbEndpoints(
        pinLat: 49.40,
        pinLng: 8.70,
        startLat: 49.38,
        startLng: 8.68,
        userLat: 49.41,
        userLng: 8.69,
      );
      expect(fromStart!.startLat, 49.38);
      expect(fromStart.endLat, 49.40);
      final preferGps = pinOnlyAbEndpoints(
        pinLat: 49.40,
        pinLng: 8.70,
        startLat: 49.38,
        startLng: 8.68,
        userLat: 49.41,
        userLng: 8.69,
        preferGps: true,
      );
      expect(preferGps!.startLat, 49.41);
      expect(preferGps.endLat, 49.40);
    });

    test('Discover A–B with net is live-first', () {
      final flags = discoverAbEngineChoice(online: true);
      expect(flags.preferOffline, isFalse);
      expect(flags.allowOfflineFirst, isFalse);
      expect(flags.allowOnline, isTrue);
      expect(flags.allowOfflineFallback, isTrue);
    });

    test('Discover A–B without net uses the pack graph', () {
      final flags = discoverAbEngineChoice(online: false);
      expect(flags.preferOffline, isTrue);
      expect(flags.allowOfflineFirst, isTrue);
      expect(flags.allowOnline, isFalse);
      expect(flags.allowOfflineFallback, isTrue);
    });

    test('Discover vias without net chain Dijkstra legs', () {
      final flags = discoverAbEngineChoice(online: false, viasEmpty: false);
      expect(flags.preferOffline, isTrue);
      expect(flags.allowOfflineFirst, isTrue);
      expect(flags.allowOnline, isFalse);
      expect(flags.allowOfflineFallback, isTrue);
    });

    test('browse pin A–B never uses pack Dijkstra', () {
      final online = discoverBrowseAbEngineChoice(online: true);
      expect(online.preferOffline, isFalse);
      expect(online.allowOfflineFirst, isFalse);
      expect(online.allowOnline, isTrue);
      expect(online.allowOfflineFallback, isFalse);
      final offline = discoverBrowseAbEngineChoice(online: false);
      expect(offline.preferOffline, isFalse);
      expect(offline.allowOfflineFirst, isFalse);
      expect(offline.allowOnline, isFalse);
      expect(offline.allowOfflineFallback, isFalse);
    });

    test('trustCachedOnlineProbe skips DNS only while recently online', () {
      final at = DateTime.utc(2026, 8, 19, 12, 0, 0);
      expect(
        trustCachedOnlineProbe(
          cachedOnline: true,
          cachedAt: at,
          now: at.add(const Duration(seconds: 5)),
        ),
        isTrue,
      );
      expect(
        trustCachedOnlineProbe(
          cachedOnline: true,
          cachedAt: at,
          now: at.add(const Duration(seconds: 13)),
        ),
        isFalse,
      );
      expect(
        trustCachedOnlineProbe(
          cachedOnline: true,
          cachedAt: at,
          now: at.add(const Duration(seconds: 5)),
          ttl: kPlanOnlineProbeTtl,
        ),
        isFalse,
      );
      expect(
        trustCachedOnlineProbe(
          cachedOnline: true,
          cachedAt: at,
          now: at.add(const Duration(seconds: 3)),
          ttl: kPlanOnlineProbeTtl,
        ),
        isTrue,
      );
      expect(
        trustCachedOnlineProbe(
          cachedOnline: false,
          cachedAt: at,
          now: at.add(const Duration(seconds: 1)),
        ),
        isFalse,
      );
      expect(
        trustCachedOnlineProbe(
          cachedOnline: true,
          cachedAt: null,
          now: at,
        ),
        isFalse,
      );
    });

    test('planLastDestShouldOffer only when dest empty, nearby, not dismissed',
        () {
      expect(
        planLastDestShouldOffer(
          hasEnd: true,
          nearby: true,
          dismissed: false,
        ),
        isFalse,
      );
      expect(
        planLastDestShouldOffer(
          hasEnd: false,
          nearby: false,
          dismissed: false,
        ),
        isFalse,
      );
      expect(
        planLastDestShouldOffer(
          hasEnd: false,
          nearby: true,
          dismissed: true,
        ),
        isFalse,
      );
      expect(
        planLastDestShouldOffer(
          hasEnd: false,
          nearby: true,
          dismissed: false,
        ),
        isTrue,
      );
    });
  });

  group('lastPlanDestIsNearby', () {
    test('restores dest within 80 km of GPS', () {
      expect(
        lastPlanDestIsNearby(
          destLat: 49.40,
          destLng: 8.65,
          gpsLat: 49.30,
          gpsLng: 8.64,
        ),
        isTrue,
      );
    });

    test('skips dest far from GPS', () {
      expect(
        lastPlanDestIsNearby(
          destLat: 47.37,
          destLng: 8.54,
          gpsLat: 49.30,
          gpsLng: 8.64,
        ),
        isFalse,
      );
    });

    test('skips dest on top of GPS', () {
      expect(
        lastPlanDestIsNearby(
          destLat: 49.30,
          destLng: 8.64,
          gpsLat: 49.30,
          gpsLng: 8.64,
        ),
        isFalse,
      );
      expect(
        lastPlanDestWorthRemembering(
          destLat: 49.30,
          destLng: 8.64,
          originLat: 49.30,
          originLng: 8.64,
        ),
        isFalse,
      );
    });

    test('falls back to viewport when GPS is missing', () {
      expect(
        lastPlanDestIsNearby(
          destLat: 49.40,
          destLng: 8.65,
          viewLat: 49.32,
          viewLng: 8.64,
        ),
        isTrue,
      );
    });

    test('panned map restores dest in view, not the home pin', () {
      expect(
        lastPlanDestIsNearby(
          destLat: 49.40,
          destLng: 8.65,
          gpsLat: 49.30,
          gpsLng: 8.64,
          viewLat: 47.37,
          viewLng: 8.54,
        ),
        isFalse,
      );
      expect(
        lastPlanDestIsNearby(
          destLat: 47.37,
          destLng: 8.54,
          gpsLat: 49.30,
          gpsLng: 8.64,
          viewLat: 47.38,
          viewLng: 8.55,
        ),
        isTrue,
      );
    });

    test('chip uses generic copy without a name, truncates long labels', () {
      expect(
        lastPlanDestChipLabel(savedLabel: null, generic: 'Letztes Ziel'),
        'Letztes Ziel',
      );
      expect(
        lastPlanDestChipLabel(savedLabel: 'Kino', generic: 'Letztes Ziel'),
        'Kino',
      );
      final long = lastPlanDestChipLabel(
        savedLabel: 'Ein sehr langer Ortsname mit vielen Zeichen',
        generic: 'x',
        maxNameChars: 12,
      );
      expect(long.length, 12);
      expect(long.endsWith('…'), isTrue);
      expect(
        lastPlanDestCoordsMatch(
          aLat: 49.294,
          aLng: 8.698,
          bLat: 49.294,
          bLng: 8.698,
        ),
        isTrue,
      );
      expect(
        lastPlanDestCoordsMatch(
          aLat: 49.294,
          aLng: 8.698,
          bLat: 49.4,
          bLng: 8.7,
        ),
        isFalse,
      );
    });

    test('plan line tap inserts a via only with a live A–B line', () {
      expect(
        planLineTapInsertsVia(
          editorActive: true,
          hasStart: true,
          hasEnd: true,
          hasLiveLine: true,
          pickingStartOrEnd: false,
        ),
        isTrue,
      );
      expect(
        planLineTapInsertsVia(
          editorActive: false,
          hasStart: true,
          hasEnd: true,
          hasLiveLine: true,
          pickingStartOrEnd: false,
        ),
        isFalse,
        reason: 'Explore leftover A–B stays inspect-only',
      );
      expect(
        planLineTapInsertsVia(
          editorActive: true,
          hasStart: true,
          hasEnd: true,
          hasLiveLine: true,
          pickingStartOrEnd: true,
        ),
        isFalse,
      );
      expect(
        planLineTapInsertsVia(
          editorActive: true,
          hasStart: true,
          hasEnd: true,
          hasLiveLine: false,
          pickingStartOrEnd: false,
        ),
        isFalse,
      );
      final line = <List<double>>[
        [8.67, 49.4],
        [8.69, 49.405],
        [8.71, 49.41],
      ];
      final hit = plannedRouteTapSnap(
        lineLngLat: line,
        tapLat: 49.405,
        tapLng: 8.69,
        maxOffsetM: 90,
      );
      expect(hit, isNotNull);
      final miss = plannedRouteTapSnap(
        lineLngLat: line,
        tapLat: 49.2,
        tapLng: 8.5,
        maxOffsetM: 90,
      );
      expect(miss, isNull);
    });
  });

  group('interactive plan map (Komoot / AllTrails)', () {
    test('browse pin stays live-streets-only; planned A–B does not', () {
      expect(
        planCalcUsesLiveStreetsOnly(fromBrowsePin: true, viasEmpty: true),
        isTrue,
      );
      expect(
        planCalcUsesLiveStreetsOnly(fromBrowsePin: true, viasEmpty: false),
        isFalse,
      );
      expect(
        planCalcUsesLiveStreetsOnly(fromBrowsePin: false, viasEmpty: true),
        isFalse,
      );
    });

    test('plan editor is Navigieren or plan surface', () {
      expect(
        planEditorIsActive(navigateMode: true, planSurface: false),
        isTrue,
      );
      expect(
        planEditorIsActive(navigateMode: false, planSurface: true),
        isTrue,
      );
      expect(
        planEditorIsActive(navigateMode: false, planSurface: false),
        isFalse,
      );
      expect(
        planEditorSheetHeightFraction(shaping: false, ideaPin: false),
        0.52,
      );
      expect(
        planEditorSheetHeightFraction(shaping: false, ideaPin: true),
        0.58,
      );
      expect(
        planEditorSheetHeightFraction(shaping: true, ideaPin: true),
        0,
      );
      expect(planEditorSheetMinPx(shaping: false), 220);
      expect(planEditorSheetMinPx(shaping: true), 0);
      expect(
        planEditorSheetRecedes(rubberBand: true, adapting: false),
        isTrue,
      );
      expect(
        planEditorSheetRecedes(rubberBand: false, adapting: true),
        isTrue,
      );
      expect(
        planEditorSheetRecedes(rubberBand: false, adapting: false),
        isFalse,
      );
      expect(
        planMapStopHintVisible(
          hasStopAt: true,
          waitHintOnMap: false,
          rubberBand: false,
        ),
        isTrue,
      );
      expect(
        planMapStopHintVisible(
          hasStopAt: true,
          waitHintOnMap: true,
          rubberBand: false,
        ),
        isFalse,
      );
      expect(
        planMapStopHintVisible(
          hasStopAt: true,
          waitHintOnMap: false,
          rubberBand: true,
        ),
        isFalse,
      );
      expect(kPlanStopHint.inMilliseconds, 3200);
      final mid = planFingerHintPlacement(
        fingerX: 180,
        fingerY: 200,
        mapW: 360,
        mapH: 640,
        chipW: 176,
        chipH: 40,
      );
      expect(mid.left, 180 - 88);
      expect(mid.top, 200 + 16);
      final low = planFingerHintPlacement(
        fingerX: 340,
        fingerY: 600,
        mapW: 360,
        mapH: 640,
        chipW: 176,
        chipH: 40,
        avoidRight: 56,
      );
      expect(low.left + 176, lessThanOrEqualTo(360 - 8 - 56));
      expect(low.top, lessThan(600));
      final above = planFingerHintPlacement(
        fingerX: 180,
        fingerY: 200,
        mapW: 360,
        mapH: 640,
        chipW: 244,
        chipH: 40,
        preferAbove: true,
      );
      expect(above.top, 200 - 40 - 12);
      expect(planFingerHintChipW(undo: false, firstAb: false), 176);
      expect(planFingerHintChipW(undo: true, firstAb: false), 228);
      expect(planFingerHintChipW(undo: false, firstAb: true), 244);
      expect(planFingerHintChipW(undo: true, firstAb: true), 280);
    });

    test('dest pin in the editor keeps start and vias', () {
      expect(
        planDestPinKeepsSession(
          editorActive: true,
          startSet: true,
          leftoverTour: false,
          pickingStart: false,
        ),
        isTrue,
      );
      expect(
        planDestPinKeepsSession(
          editorActive: true,
          startSet: true,
          leftoverTour: true,
          pickingStart: false,
        ),
        isFalse,
        reason: 'Tour leftover starts a fresh GPS→pin A–B',
      );
      expect(
        planDestPinKeepsSession(
          editorActive: false,
          startSet: true,
          leftoverTour: false,
          pickingStart: false,
        ),
        isFalse,
      );
    });

    test('tap radius tightens when zoomed in', () {
      expect(plannedRouteTapRadiusM(18), 28);
      expect(plannedRouteTapRadiusM(9), 200);
    });

    test('duplicate via within 40 m is rejected', () {
      expect(
        plannedRouteViaIsDuplicate(
          vias: const [(lat: 49.285, lng: 8.680)],
          lat: 49.2851,
          lng: 8.6801,
        ),
        isTrue,
      );
      expect(
        plannedRouteViaIsDuplicate(
          vias: const [(lat: 49.285, lng: 8.680)],
          lat: 49.295,
          lng: 8.700,
        ),
        isFalse,
      );
    });

    test('stale live A–B stays while a reshape is in flight', () {
      expect(
        shouldKeepStaleDiscoverLine(
          hasLiveStreetLine: true,
          leftoverTourOnMap: false,
        ),
        isTrue,
      );
      expect(
        shouldKeepStaleDiscoverLine(
          hasLiveStreetLine: true,
          leftoverTourOnMap: true,
        ),
        isFalse,
      );
      expect(
        shouldKeepStaleDiscoverLine(
          hasLiveStreetLine: false,
          leftoverTourOnMap: false,
        ),
        isFalse,
      );
    });

    test('drag preview km is compact', () {
      expect(planDragAlongLabelKm(0), '0');
      expect(planDragAlongLabelKm(80), '0');
      expect(planDragAlongLabelKm(1500), '1.5');
      expect(planDragAlongLabelKm(12400), '12');
    });

    test('ribbon dim keeps a faint live line under the rubber-band', () {
      expect(planRibbonDimOpacity(0.96, dimmed: false), 0.96);
      expect(planRibbonDimOpacity(0.96, dimmed: true), closeTo(0.0432, 0.0001));
      expect(planRibbonDimOpacity(0.22, dimmed: true), 0.028);
      expect(planRibbonDimOpacity(1.0, dimmed: true), closeTo(0.045, 0.0001));
      expect(planGrabHandleOpacity(0.95, dimmed: false), 0.95);
      expect(planGrabHandleOpacity(0.95, dimmed: true), closeTo(0.266, 0.0001));
      expect(planGrabHandleOpacity(0.10, dimmed: true), 0.14);
      expect(
        planMapAdaptingHintOnMap(
          routingBusy: true,
          hasLiveLine: true,
          hasFinger: true,
        ),
        isTrue,
      );
      expect(
        planMapAdaptingHintOnMap(
          routingBusy: true,
          hasLiveLine: true,
          hasFinger: false,
        ),
        isFalse,
      );
      expect(
        planMapDestWaitHintOnMap(
          editorActive: true,
          routingBusy: true,
          hasStart: true,
          hasEnd: true,
          fingerHint: false,
        ),
        isTrue,
      );
      expect(
        planMapDestWaitHintOnMap(
          editorActive: true,
          routingBusy: true,
          hasStart: true,
          hasEnd: true,
          fingerHint: true,
        ),
        isFalse,
      );
      expect(
        planMapDestWaitHintOnMap(
          editorActive: false,
          routingBusy: true,
          hasStart: true,
          hasEnd: true,
          fingerHint: false,
        ),
        isFalse,
      );
      expect(
        planMapDestWaitHintOnMap(
          editorActive: true,
          routingBusy: false,
          hasStart: false,
          hasEnd: true,
          fingerHint: false,
        ),
        isTrue,
      );
      expect(
        planMapDestWaitHintOnMap(
          editorActive: true,
          routingBusy: false,
          hasStart: true,
          hasEnd: true,
          fingerHint: false,
          destConfirm: true,
          hasLiveLine: false,
        ),
        isTrue,
      );
      expect(
        planMapDestWaitHintOnMap(
          editorActive: true,
          routingBusy: false,
          hasStart: true,
          hasEnd: true,
          fingerHint: false,
          destConfirm: true,
          hasLiveLine: true,
        ),
        isFalse,
      );
      expect(
        planMapDestWaitCopy(hasStart: false, hasLiveLine: false),
        PlanMapDestWaitCopy.waitingGps,
      );
      expect(
        planMapDestWaitCopy(hasStart: true, hasLiveLine: false),
        PlanMapDestWaitCopy.firstAb,
      );
      expect(
        planMapDestWaitCopy(hasStart: true, hasLiveLine: true),
        PlanMapDestWaitCopy.adapting,
      );
      expect(planLineGrabYieldsToPinch(pointerCount: 1), isFalse);
      expect(planLineGrabYieldsToPinch(pointerCount: 2), isTrue);
      expect(
        planLineGrabBecomesExclusive(pointerCount: 1, movePx: 8),
        isTrue,
      );
      expect(
        planLineGrabBecomesExclusive(pointerCount: 2, movePx: 20),
        isFalse,
      );
      expect(planLineHoldCancelsOnMove(movePx: 5), isFalse);
      expect(planLineHoldCancelsOnMove(movePx: 6), isTrue);
      expect(kPlanLineHoldCancelPx, lessThan(kPlanLineGrabMovePx));
      expect(kPlanLineHold.inMilliseconds, 450);
      expect(
        planGrabNativeDrivesPreview(hasSyncPreview: true),
        isFalse,
      );
      expect(
        planGrabNativeDrivesPreview(hasSyncPreview: false),
        isTrue,
      );
      expect(planLineCoachIsCompact(699), isTrue);
      expect(planLineCoachIsXCompact(639), isTrue);
      expect(planLineCoachIsXCompact(700), isFalse);
      expect(
        planLineCoachCopy(
          adopting: true,
          compact: true,
          full: 'full',
          short: 'short',
          adopt: 'adopt',
        ),
        'adopt',
      );
      expect(
        planLineCoachCopy(
          adopting: false,
          compact: true,
          full: 'full',
          short: 'short',
          adopt: 'adopt',
        ),
        'short',
      );
      expect(planRibbonLegendCompact(419), isTrue);
      expect(planRibbonLegendCompact(420), isFalse);
      expect(
        planChevronIconOpacity(dimmed: true, fresh: true),
        0,
      );
      expect(
        planChevronIconOpacity(dimmed: false, fresh: true),
        greaterThan(planChevronIconOpacity(dimmed: false, fresh: false)),
      );
      expect(
        planRibbonLegendKinds(
          bands: [
            (fromKm: 0, toKm: 1, surface: 'asphalt'),
            (fromKm: 1, toKm: 2, surface: 'fine_gravel'),
          ],
          hasSteep: true,
        ),
        {'asphalt', 'gravel', 'steep'},
      );
      expect(
        planRibbonLegendKinds(
          bands: [
            (fromKm: 0, toKm: 1, surface: 'asphalt'),
            (fromKm: 1, toKm: 1.05, surface: null),
          ],
        ),
        {'asphalt'},
      );
      expect(
        planRibbonLegendKinds(
          bands: [
            (fromKm: 0, toKm: 1, surface: 'asphalt'),
            (fromKm: 1, toKm: 1.2, surface: null),
          ],
        ),
        {'asphalt', 'unknown'},
      );
    });

    test('grab stays on the stale ribbon; wait chip lasts the whole calc', () {
      expect(
        planRibbonAllowsGrab(
          editorActive: true,
          hasLiveStreetLine: true,
          approx: false,
        ),
        isTrue,
      );
      expect(
        planRibbonAllowsGrab(
          editorActive: true,
          hasLiveStreetLine: true,
          approx: true,
        ),
        isFalse,
      );
      expect(kPlanRibbonGrabHaloWidth, greaterThanOrEqualTo(28));
      expect(
        planMapShowsRoutingWait(
          editorActive: true,
          routingBusy: true,
          hasStart: true,
          hasEnd: true,
        ),
        isTrue,
      );
      expect(
        planMapShowsRoutingWait(
          editorActive: true,
          routingBusy: false,
          hasStart: true,
          hasEnd: true,
        ),
        isFalse,
      );
      expect(
        planMapHistoryFabsVisible(
          editorActive: true,
          hasHistory: true,
          mapHintOnMap: false,
          rubberBand: false,
          coachVisible: false,
        ),
        isTrue,
        reason: 'idle plan shows history FABs',
      );
      expect(
        planMapHistoryFabsVisible(
          editorActive: true,
          hasHistory: true,
          mapHintOnMap: true,
          rubberBand: false,
          coachVisible: false,
        ),
        isFalse,
        reason: 'stop/wait chip owns Undo — hide FABs',
      );
      expect(
        planMapHistoryFabsVisible(
          editorActive: true,
          hasHistory: true,
          mapHintOnMap: false,
          rubberBand: true,
          coachVisible: false,
        ),
        isFalse,
      );
      expect(
        planMapHistoryFabsVisible(
          editorActive: true,
          hasHistory: true,
          mapHintOnMap: false,
          rubberBand: false,
          coachVisible: false,
          routingWaitBanner: true,
        ),
        isFalse,
      );
      expect(
        planParkedFingerClearsWhenIdle(routingBusy: true),
        isFalse,
        reason: 'keep parked finger while reshape is in flight',
      );
      expect(
        planParkedFingerClearsWhenIdle(routingBusy: false),
        isTrue,
        reason: 'drop parked finger when engine is idle',
      );
      expect(
        planMapHintAnchorLngLat(
          adaptingAt: (lng: 8.7, lat: 49.4),
          parkedFinger: (lng: 8.1, lat: 49.1),
        ),
        (lng: 8.7, lat: 49.4),
        reason: 'dest/stop pin wins over parked reshape finger',
      );
      expect(
        planMapHintAnchorLngLat(
          adaptingAt: null,
          parkedFinger: (lng: 8.1, lat: 49.1),
        ),
        (lng: 8.1, lat: 49.1),
      );
      expect(
        planMapHintAnchorLngLat(adaptingAt: null, parkedFinger: null),
        isNull,
      );
      expect(
        planMapAdaptingHintOnMap(
          routingBusy: true,
          hasLiveLine: true,
          hasFinger: true,
        ),
        isTrue,
      );
      expect(
        planMapAdaptingHintOnMap(
          routingBusy: true,
          hasLiveLine: true,
          hasFinger: false,
        ),
        isFalse,
        reason: 'without parked finger, dest-wait owns the chip',
      );
    });

    test('reshape handles sit mid-route and skip existing vias', () {
      final long = <List<double>>[
        for (var i = 0; i <= 20; i++) [8.67 + i * 0.01, 49.28 + i * 0.004],
      ];
      final handles = planReshapeHandles(
        lineLngLat: long,
        vias: const [],
      );
      expect(handles, isNotEmpty);
      expect(handles.length, greaterThanOrEqualTo(2));
      final blocked = planReshapeHandles(
        lineLngLat: long,
        vias: [
          (lat: handles.first.lat, lng: handles.first.lng),
        ],
      );
      expect(
        blocked.any(
          (h) =>
              (h.lat - handles.first.lat).abs() < 1e-5 &&
              (h.lng - handles.first.lng).abs() < 1e-5,
        ),
        isFalse,
      );
      final short = <List<double>>[
        [8.67, 49.4],
        [8.6735, 49.4025],
      ];
      expect(planReshapeHandles(lineLngLat: short, vias: const []), isNotEmpty);
    });

    test('joinPlanLineToPins meets nearby pins, never a field cut', () {
      final line = <List<double>>[
        [8.6702, 49.4001],
        [8.69, 49.405],
        [8.7098, 49.4099],
      ];
      final joined = joinPlanLineToPins(
        lineLngLat: line,
        startLat: 49.4,
        startLng: 8.67,
        endLat: 49.41,
        endLng: 8.71,
      );
      expect(joined.first[0], 8.67);
      expect(joined.first[1], 49.4);
      expect(joined.last[0], 8.71);
      expect(joined.last[1], 49.41);
      final far = joinPlanLineToPins(
        lineLngLat: line,
        startLat: 49.5,
        startLng: 8.8,
        endLat: 49.41,
        endLng: 8.71,
      );
      expect(far.first[0], 8.6702);
      expect(far.last[0], 8.71);
    });

    test('farm-trim snaps dest pin onto the street, never a field cut', () {
      const street = (lat: 49.4, lng: 8.67);
      final near = snapPlanPinToStreetLine(
        pinLat: 49.4,
        pinLng: 8.6711,
        streetLat: street.lat,
        streetLng: street.lng,
      );
      expect(near?.lat, street.lat);
      expect(near?.lng, street.lng);
      expect(
        snapPlanPinToStreetLine(
          pinLat: 49.4,
          pinLng: 8.67005,
          streetLat: street.lat,
          streetLng: street.lng,
        ),
        isNull,
      );
      expect(
        snapPlanPinToStreetLine(
          pinLat: 49.4,
          pinLng: 8.70,
          streetLat: street.lat,
          streetLng: street.lng,
        ),
        isNull,
      );
      final snap = applyFarmTrimPinSnap(
        startLat: 49.39,
        startLng: 8.66,
        endLat: 49.4,
        endLng: 8.6711,
        lineLngLat: [
          [8.66, 49.39],
          [8.67, 49.4],
        ],
        warnings: const ['Kein Weg bis zum Pin — Ziel liegt an der Straße.'],
        startIsGps: true,
      );
      expect(snap.snappedStart, isFalse);
      expect(snap.snappedEnd, isTrue);
      expect(snap.endLng, 8.67);
      expect(snap.endLat, 49.4);
      expect(
        applyFarmTrimPinSnap(
          startLat: 49.4,
          startLng: 8.67,
          endLat: 49.4,
          endLng: 8.6711,
          lineLngLat: [
            [8.67, 49.4],
            [8.68, 49.401],
          ],
          warnings: const [],
        ).snappedEnd,
        isFalse,
      );
    });

    test('plan-line coach retries after 14 days, legacy dismiss stays off', () {
      expect(planLineCoachShouldShow(stored: null), isTrue);
      expect(planLineCoachShouldShow(stored: true), isFalse);
      expect(planLineCoachShouldShow(stored: '1'), isFalse);
      expect(
        planLineCoachShouldShow(
          stored: DateTime.now().millisecondsSinceEpoch,
        ),
        isFalse,
      );
      expect(
        planLineCoachShouldShow(
          stored: DateTime.now()
              .subtract(const Duration(days: 15))
              .millisecondsSinceEpoch,
        ),
        isTrue,
      );
    });

    test('distance ticks appear on longer lines', () {
      final long = <List<double>>[
        for (var i = 0; i <= 40; i++) [8.67 + i * 0.012, 49.28],
      ];
      final ticks = planDistanceTicks(lineLngLat: long);
      expect(ticks, isNotEmpty);
      expect(double.parse(ticks.first.km), greaterThan(0));
      final firstAlongM = double.parse(ticks.first.km) * 1000;
      final skipped = planDistanceTicks(
        lineLngLat: long,
        avoidAlongM: [firstAlongM],
      );
      expect(skipped.any((t) => t.km == ticks.first.km), isFalse);
      expect(planDistanceTicksVisible(11), isFalse);
      expect(planDistanceTicksVisible(12), isTrue);
      expect(
        planDistanceTicks(lineLngLat: long, zoom: 11),
        isEmpty,
      );
      final close = planDistanceTicks(lineLngLat: long, zoom: 16);
      final overview = planDistanceTicks(lineLngLat: long, zoom: 12);
      expect(close.length, greaterThan(overview.length));
    });

    test('via map caption skips placeholders', () {
      expect(planViaMapCaption('Café König'), 'Café König');
      expect(planViaMapCaption('Punkt auf der Karte'), isNull);
      expect(planViaMapCaption('Stopp 1'), isNull);
      expect(planViaMapCaption('Via 2'), isNull);
      expect(
        planViaMapCaption('Zwischenstopp', placeholders: ['Zwischenstopp']),
        isNull,
      );
    });

    test('direction chevrons follow the line and skip far zoom', () {
      final long = <List<double>>[
        for (var i = 0; i <= 40; i++) [8.67 + i * 0.012, 49.28],
      ];
      final chevs = planDirectionChevrons(lineLngLat: long, zoom: 14);
      expect(chevs, isNotEmpty);
      expect(chevs.first.bearingDeg, isNot(0));
      expect(
        planDirectionChevrons(lineLngLat: long, zoom: 10),
        isEmpty,
      );
      final close = planDirectionChevrons(lineLngLat: long, zoom: 16);
      final far = planDirectionChevrons(lineLngLat: long, zoom: 13);
      expect(close.length, greaterThan(far.length));
      expect(planChevronStepM(16.5), lessThan(planChevronStepM(14.5)));
      expect(planChevronMax(16.5), greaterThan(planChevronMax(13)));
    });

    test('adopted tour line is customizable; leftover wipe skips after A+B',
        () {
      expect(
        isPlanCustomizableLine(engine: 'tour-adopt', coordinateCount: 4),
        isTrue,
      );
      expect(
        isPlanCustomizableLine(engine: 'tour-pin', coordinateCount: 4),
        isFalse,
      );
      expect(
        planLeftoverTourWipesOnTap(
          leftover: true,
          hasStart: true,
          hasEnd: true,
        ),
        isFalse,
      );
      expect(
        planLeftoverTourWipesOnTap(
          leftover: true,
          hasStart: true,
          hasEnd: false,
        ),
        isTrue,
      );
      expect(
        planBusyBlocksDestReplace(
          routingBusy: true,
          hasStart: true,
          hasEnd: true,
        ),
        isTrue,
      );
      expect(
        planBusyBlocksDestReplace(
          routingBusy: true,
          hasStart: true,
          hasEnd: true,
          pickingEnd: true,
        ),
        isFalse,
      );
      final long = <List<double>>[
        for (var i = 0; i <= 40; i++) [8.67 + i * 0.012, 49.28],
      ];
      final zoomed = planReshapeHandles(
        lineLngLat: long,
        vias: const [],
        zoom: 16,
      );
      final overview = planReshapeHandles(
        lineLngLat: long,
        vias: const [],
        zoom: 12,
      );
      expect(zoomed.length, greaterThanOrEqualTo(overview.length));
      expect(zoomed.length, greaterThan(5));
      expect(
        planReshapeHandleStepM(zoom: 16),
        lessThan(planReshapeHandleStepM(zoom: 12)),
      );
    });

    test('rubber-band preview goes through the finger', () {
      final line = <List<double>>[
        [8.67, 49.4],
        [8.69, 49.405],
        [8.71, 49.41],
      ];
      final band = planRubberBandLngLat(
        startLat: 49.4,
        startLng: 8.67,
        endLat: 49.41,
        endLng: 8.71,
        vias: const [],
        fingerLat: 49.42,
        fingerLng: 8.69,
        lineLngLat: line,
      );
      expect(band, hasLength(3));
      expect(band[1][0], 8.69);
      expect(band[1][1], 49.42);
      final startBand = planRubberBandLngLat(
        startLat: 49.4,
        startLng: 8.67,
        endLat: 49.41,
        endLng: 8.71,
        vias: const [],
        fingerLat: 49.39,
        fingerLng: 8.66,
        lineLngLat: line,
        draggingStart: true,
      );
      expect(startBand, hasLength(2));
      expect(startBand.first[0], 8.66);

      final keepLine = <List<double>>[
        [8.6, 49.4],
        [8.62, 49.401],
        [8.64, 49.402],
        [8.66, 49.403],
        [8.68, 49.404],
        [8.7, 49.405],
        [8.72, 49.406],
      ];
      final keepBand = planRubberBandLngLat(
        startLat: 49.4,
        startLng: 8.6,
        endLat: 49.406,
        endLng: 8.72,
        vias: const [(lat: 49.403, lng: 8.66)],
        fingerLat: 49.42,
        fingerLng: 8.69,
        lineLngLat: keepLine,
      );
      expect(keepBand.length, greaterThan(3));
      expect(keepBand.any((p) => p[0] == 8.69 && p[1] == 49.42), isTrue);
      expect(keepBand.first, keepLine.first);
      expect(keepBand.last, keepLine.last);
      expect(
        keepBand.any((p) => p[0] == 8.62 && p[1] == 49.401),
        isTrue,
        reason: 'head before the via stays on the live line',
      );
    });

    test('steep Höhenprofil matches Komoot 8 percent', () {
      expect(
        planElevSegmentSteep(fromM: 100, toM: 120, distM: 100),
        isTrue,
      );
      expect(
        planElevSegmentSteep(fromM: 100, toM: 101, distM: 100),
        isFalse,
      );
    });

    test('steep slices follow the climb and skip flat', () {
      final line = <List<double>>[
        [8.0, 49.0],
        [8.005, 49.0],
        [8.010, 49.0],
        [8.020, 49.0],
      ];
      final slices = planSteepLineSlices(
        lineLngLat: line,
        elevM: const [100, 100, 160, 160],
      );
      expect(slices, isNotEmpty);
      expect(planSteepLineSlices(lineLngLat: line, elevM: const []), isEmpty);
      expect(planSurfaceIsUnpaved('gravel'), isTrue);
      expect(planSurfaceIsUnpaved('asphalt'), isFalse);
      expect(planSurfaceKind('asphalt'), isNotNull);
      expect(planSurfaceKind('fine_gravel'), isNotNull);
      expect(planSurfaceKind('dirt'), isNotNull);
      expect(planSurfaceKind('xyz'), isNull);
      final surfaces = planSurfaceLineSlices(
        lineLngLat: line,
        bands: [
          (fromKm: 0, toKm: 0.4, surface: 'asphalt'),
          (fromKm: 0.4, toKm: 1.2, surface: 'gravel'),
        ],
      );
      expect(surfaces, isNotEmpty);
      final bridged = planSurfaceLineSlices(
        lineLngLat: line,
        bands: [
          (fromKm: 0, toKm: 0.4, surface: 'asphalt'),
          (fromKm: 0.4, toKm: 0.46, surface: null),
          (fromKm: 0.46, toKm: 1.2, surface: 'asphalt'),
        ],
      );
      expect(bridged, hasLength(1));
      expect(bridged.first.kind.name, 'asphalt');
      expect(planElevScrubT(alongM: 500, lineLenM: 2000), 0.25);
      expect(planElevScrubT(alongM: 0, lineLenM: 0), isNull);
      final gapFlags = [true, false, true];
      fillShortFlagGaps(
        flags: gapFlags,
        along: const [0, 20, 50, 90],
        mergeGapM: 80,
      );
      expect(gapFlags, [true, true, true]);
      final unpaved = planUnpavedLineSlices(
        lineLngLat: line,
        bands: [(fromKm: 0.2, toKm: 1.2, surface: 'gravel')],
      );
      expect(unpaved, isNotEmpty);
      expect(planLineSlice(line, 200, 900).length, greaterThanOrEqualTo(2));
      expect(
        planReshapeHandlesReady(hasVia: false, coachVisible: true),
        isFalse,
      );
      expect(
        planReshapeHandlesReady(hasVia: true, coachVisible: true),
        isTrue,
      );
      expect(
        planReshapeHandlesReady(hasVia: false, coachVisible: false),
        isTrue,
      );
      expect(planDistanceTicksMinZoom(8000), 12);
      expect(planDistanceTicksMinZoom(30000), 13);
      expect(planDistanceTicksVisible(12, minZoom: 13), isFalse);
      expect(
        planGradeKind(fromM: 100, toM: 120, distM: 100),
        PlanGradeKind.steepUp,
      );
      expect(
        planGradeKind(fromM: 100, toM: 90, distM: 100),
        PlanGradeKind.steepDown,
      );
      expect(
        planGradeKind(fromM: 100, toM: 101, distM: 100),
        PlanGradeKind.roll,
      );
      final grades = planGradeLineSlices(
        lineLngLat: line,
        elevM: const [100, 100, 200, 40],
      );
      expect(grades, isNotEmpty);
      expect(
        grades.any((g) => g.kind == PlanGradeKind.steepUp),
        isTrue,
      );
      expect(
        grades.any((g) => g.kind == PlanGradeKind.steepDown),
        isTrue,
      );
      expect(planGradeColorHex(PlanGradeKind.roll), '#FF6A00');
    });

    test('plan map projection hits the ribbon, not pins', () {
      const w = 256.0;
      const h = 256.0;
      final center = planMapScreenToLngLat(
        localX: 128,
        localY: 128,
        width: w,
        height: h,
        centerLng: 0,
        centerLat: 0,
        zoom: 0,
      );
      expect(center, isNotNull);
      expect(center!.lng, closeTo(0, 1e-6));
      expect(center.lat, closeTo(0, 1e-6));
      final east = planMapScreenToLngLat(
        localX: 192,
        localY: 128,
        width: w,
        height: h,
        centerLng: 0,
        centerLat: 0,
        zoom: 0,
      );
      expect(east, isNotNull);
      expect(east!.lng, greaterThan(0));
      const line = [
        [-10.0, 0.0],
        [10.0, 0.0],
      ];
      expect(
        planMapPointerHitsRibbon(
          localX: 128,
          localY: 128,
          width: w,
          height: h,
          centerLng: 0,
          centerLat: 0,
          zoom: 0,
          lineLngLat: line,
        ),
        isTrue,
      );
      expect(
        planMapPointerHitsRibbon(
          localX: 128,
          localY: 128,
          width: w,
          height: h,
          centerLng: 0,
          centerLat: 0,
          zoom: 0,
          lineLngLat: line,
          pinLngLat: const [
            [0.0, 0.0],
          ],
        ),
        isFalse,
      );
      expect(
        planMapPointerHitsRibbon(
          localX: 128,
          localY: 128,
          width: w,
          height: h,
          centerLng: 0,
          centerLat: 0,
          zoom: 0,
          tiltDeg: 12,
          lineLngLat: line,
        ),
        isTrue,
      );
      final tilted = planMapScreenToLngLat(
        localX: 128,
        localY: 128,
        width: w,
        height: h,
        centerLng: 8.67,
        centerLat: 49.4,
        zoom: 14,
        tiltDeg: 28,
      );
      expect(tilted, isNotNull);
      expect(tilted!.lng, closeTo(8.67, 1e-5));
      expect(tilted.lat, closeTo(49.4, 1e-5));
      final south = planMapScreenToLngLat(
        localX: 128,
        localY: 192,
        width: w,
        height: h,
        centerLng: 0,
        centerLat: 0,
        zoom: 3,
        tiltDeg: 35,
      );
      final north = planMapScreenToLngLat(
        localX: 128,
        localY: 64,
        width: w,
        height: h,
        centerLng: 0,
        centerLat: 0,
        zoom: 3,
        tiltDeg: 35,
      );
      expect(south, isNotNull);
      expect(north, isNotNull);
      expect(south!.lat, lessThan(0));
      expect(north!.lat, greaterThan(0));
      expect(
        north.lat.abs(),
        greaterThan(south.lat.abs()),
        reason: 'pitched far side (top) covers more ground than the near side',
      );
      final back = planMapLngLatToScreen(
        lng: south.lng,
        lat: south.lat,
        width: w,
        height: h,
        centerLng: 0,
        centerLat: 0,
        zoom: 3,
        tiltDeg: 35,
      );
      expect(back, isNotNull);
      expect(back!.x, closeTo(128, 1.5));
      expect(back.y, closeTo(192, 1.5));
      final corner = planMapScreenToLngLat(
        localX: 180,
        localY: 160,
        width: w,
        height: h,
        centerLng: 8.4,
        centerLat: 49.0,
        zoom: 12,
        bearingDeg: 40,
        tiltDeg: 28,
      );
      expect(corner, isNotNull);
      final cornerBack = planMapLngLatToScreen(
        lng: corner!.lng,
        lat: corner.lat,
        width: w,
        height: h,
        centerLng: 8.4,
        centerLat: 49.0,
        zoom: 12,
        bearingDeg: 40,
        tiltDeg: 28,
      );
      expect(cornerBack, isNotNull);
      expect(cornerBack!.x, closeTo(180, 2.5));
      expect(cornerBack.y, closeTo(160, 2.5));
      expect(
        planMapPointerHitsRibbon(
          localX: 128,
          localY: 128,
          width: w,
          height: h,
          centerLng: 0,
          centerLat: 0,
          zoom: 0,
          tiltDeg: 12,
          lineLngLat: line,
          pinLngLat: const [
            [0.0, 0.0],
          ],
        ),
        isFalse,
      );
    });

    test('native screen ribbon hit ignores pins and maps back to lnglat', () {
      const lineScreen = [
        (x: 10.0, y: 40.0),
        (x: 110.0, y: 40.0),
      ];
      const lineLngLat = [
        [8.0, 49.0],
        [8.1, 49.0],
      ];
      expect(
        planMapPointerHitsScreenRibbon(
          localX: 60,
          localY: 48,
          lineScreen: lineScreen,
        ),
        isTrue,
      );
      expect(
        planMapPointerHitsScreenRibbon(
          localX: 60,
          localY: 90,
          lineScreen: lineScreen,
        ),
        isFalse,
      );
      expect(
        planMapPointerHitsScreenRibbon(
          localX: 60,
          localY: 48,
          lineScreen: lineScreen,
          pinScreen: const [(x: 60.0, y: 40.0)],
        ),
        isFalse,
      );
      final at = planLngLatAtScreenRibbon(
        localX: 60,
        localY: 40,
        lineScreen: lineScreen,
        lineLngLat: lineLngLat,
      );
      expect(at, isNotNull);
      expect(at!.lng, closeTo(8.05, 1e-6));
      expect(at.lat, closeTo(49.0, 1e-6));
      final long = [
        for (var i = 0; i <= 200; i++) [8.0 + i * 0.01, 49.0],
      ];
      final sampled = planGrabScreenSample(
        long,
        zoom: 13,
        lat: 49,
      );
      expect(sampled.length, lessThanOrEqualTo(kPlanGrabScreenMaxPts));
      expect(sampled.first, long.first);
      expect(sampled.last, long.last);
      expect(
        planGrabScreenSampleDenseStepM(zoom: 13, lat: 49),
        lessThan(planGrabScreenSampleStepM(zoom: 13, lat: 49)),
      );
      // Long east–west line: viewport around the west end densifies there.
      final viewSample = planGrabScreenSample(
        long,
        zoom: 13,
        lat: 49,
        centerLng: 8.05,
        centerLat: 49,
        mapW: 360,
        mapH: 640,
      );
      expect(viewSample.length, lessThanOrEqualTo(kPlanGrabScreenMaxPts));
      expect(viewSample.first, long.first);
      expect(viewSample.last, long.last);
      var nearWest = 0;
      var nearEast = 0;
      for (final p in viewSample) {
        if (p[0] < 8.3) nearWest++;
        if (p[0] > 9.5) nearEast++;
      }
      expect(
        nearWest,
        greaterThan(nearEast),
        reason: 'viewport samples cluster near the camera',
      );
      expect(
        planGrabSampleInViewport(
          lng: 8.05,
          lat: 49,
          centerLng: 8.05,
          centerLat: 49,
          zoom: 13,
          mapW: 360,
          mapH: 640,
        ),
        isTrue,
      );
      expect(
        planGrabSampleInViewport(
          lng: 10.0,
          lat: 49,
          centerLng: 8.05,
          centerLat: 49,
          zoom: 13,
          mapW: 360,
          mapH: 640,
        ),
        isFalse,
      );
    });
  });
}
