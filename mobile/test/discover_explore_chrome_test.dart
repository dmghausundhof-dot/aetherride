import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/domain/routing/bike_overlay_class.dart';
import 'package:aetherride_mobile/presentation/discover/discover_explore_chrome.dart';

void main() {
  group('DiscoverExploreChromeLogic', () {
    test('around origin ignores DACH overview and low zoom', () {
      expect(
        DiscoverExploreChromeLogic.aroundOriginIsUsable(
          hasGpsOrStart: true,
          browseLat: 47.2,
          browseLng: 6.5,
          mapZoom: 5.5,
        ),
        isTrue,
      );
      expect(
        DiscoverExploreChromeLogic.aroundOriginIsUsable(
          hasGpsOrStart: false,
          browseLat: 47.2,
          browseLng: 6.5,
          mapZoom: 12,
        ),
        isFalse,
      );
      expect(
        DiscoverExploreChromeLogic.aroundOriginIsUsable(
          hasGpsOrStart: false,
          browseLat: 49.4,
          browseLng: 8.67,
          mapZoom: 5.5,
        ),
        isFalse,
      );
      expect(
        DiscoverExploreChromeLogic.aroundOriginIsUsable(
          hasGpsOrStart: false,
          browseLat: 49.4,
          browseLng: 8.67,
          mapZoom: 12,
        ),
        isTrue,
      );
      expect(
        DiscoverExploreChromeLogic.aroundOriginIsUsable(
          hasGpsOrStart: false,
          browseLat: null,
          browseLng: null,
          mapZoom: 12,
        ),
        isFalse,
      );
    });

    test('legend swatches follow layer toggles', () {
      expect(
        DiscoverExploreChromeLogic.legendShowsPaved(waysOn: false),
        isFalse,
      );
      expect(
        DiscoverExploreChromeLogic.legendShowsTrailFamily(trailsOn: false),
        isFalse,
      );
      expect(
        DiscoverExploreChromeLogic.legendShowsPaved(waysOn: true),
        isTrue,
      );
      expect(
        DiscoverExploreChromeLogic.legendShowsTrailFamily(trailsOn: true),
        isTrue,
      );
    });

    test('around chip shows 35 km until a max is set', () {
      expect(DiscoverExploreChromeLogic.defaultAroundKm, 35);
      expect(DiscoverExploreChromeLogic.aroundDisplayKm(null), 35);
      expect(DiscoverExploreChromeLogic.aroundDisplayKm(40), 40);
      expect(DiscoverExploreChromeLogic.aroundIsSet(null), isFalse);
      expect(DiscoverExploreChromeLogic.aroundIsSet(40), isTrue);
    });

    test('Hof-pinned away wins over the 35 km placeholder', () {
      expect(
        DiscoverExploreChromeLogic.aroundDisplayKm(null, selectedAwayKm: 11.2),
        11,
      );
      expect(
        DiscoverExploreChromeLogic.usesSelectedAway(null, 11.2),
        isTrue,
      );
      expect(
        DiscoverExploreChromeLogic.aroundDisplayKm(40, selectedAwayKm: 11.2),
        40,
      );
      expect(DiscoverExploreChromeLogic.formatLoopKm(15), '15');
      expect(DiscoverExploreChromeLogic.formatLoopKm(9.4), '9.4');
      expect(DiscoverExploreChromeLogic.formatAwayKm(11.2), 11);
      expect(DiscoverExploreChromeLogic.formatAwayKm(0.4), 0);
    });

    test('GPS does not steal the camera from a Hof pin', () {
      expect(
        DiscoverExploreChromeLogic.gpsMayRecenterOnUser(
          hofPinLoopId: 'seed-loop-heidelberg-neckarwiese-60',
          selectedTourId: 'seed-loop-heidelberg-neckarwiese-60',
        ),
        isFalse,
      );
      expect(
        DiscoverExploreChromeLogic.gpsMayRecenterOnUser(
          hofPinLoopId: null,
          selectedTourId: 'seed-loop-heidelberg-neckarwiese-60',
        ),
        isFalse,
      );
      expect(
        DiscoverExploreChromeLogic.gpsMayRecenterOnUser(
          hofPinLoopId: null,
          selectedTourId: null,
        ),
        isTrue,
      );
    });

    test('narrow Explore stacks search on its own row', () {
      expect(DiscoverExploreChromeLogic.stackSearchOnOwnRow(359), isTrue);
      expect(DiscoverExploreChromeLogic.stackSearchOnOwnRow(360), isFalse);
      expect(DiscoverExploreChromeLogic.stackSearchOnOwnRow(390), isFalse);
      expect(DiscoverExploreChromeLogic.exploreChromeBodyHeightFor(359), 160);
      expect(DiscoverExploreChromeLogic.exploreChromeBodyHeightFor(360), 112);
      expect(
        DiscoverExploreChromeLogic.resolvedChromeHeight(
          measured: 112,
          width: 320,
        ),
        160,
      );
      expect(
        DiscoverExploreChromeLogic.resolvedChromeHeight(
          measured: 161,
          width: 320,
        ),
        161,
      );
      expect(
        DiscoverExploreChromeLogic.resolvedChromeHeight(
          measured: 112,
          width: 400,
        ),
        112,
      );
    });

    test('filter chip keeps the word Filter', () {
      expect(
        DiscoverExploreChromeLogic.filterChipIconOnly(
          compact: true,
          aroundUsesAway: true,
        ),
        isFalse,
      );
    });

    test('ornaments sit below the chrome and legend', () {
      expect(
        DiscoverExploreChromeLogic.ornamentExtraBelowSafe(112),
        greaterThan(112),
      );
      expect(
        DiscoverExploreChromeLogic.ornamentExtraBelowSafe(112),
        greaterThanOrEqualTo(
          DiscoverExploreChromeLogic.exploreChromeTopPad +
              112 +
              DiscoverExploreChromeLogic.exploreChromeToLayersGap +
              DiscoverExploreChromeLogic.exploreLegendHeight,
        ),
      );
    });

    test('Karteninhalt is customized only when a default layer is off', () {
      expect(
        DiscoverExploreChromeLogic.mapContentsCustomized(
          toursOn: true,
          trailsOn: true,
          waysOn: true,
          hillshadeOn: true,
          placesOn: true,
          heatOn: false,
          heatConsent: false,
        ),
        isFalse,
      );
      expect(
        DiscoverExploreChromeLogic.mapContentsCustomized(
          toursOn: true,
          trailsOn: false,
          waysOn: true,
          hillshadeOn: true,
          placesOn: true,
          heatOn: true,
          heatConsent: true,
        ),
        isTrue,
      );
      expect(
        DiscoverExploreChromeLogic.mapContentsCustomized(
          toursOn: true,
          trailsOn: true,
          waysOn: true,
          hillshadeOn: true,
          placesOn: true,
          heatOn: false,
          heatConsent: true,
        ),
        isTrue,
      );
    });

    test('tour selection keeps the same chrome as idle', () {
      expect(
        DiscoverExploreChromeLogic.compactExploreChrome(
          hasSelection: true,
          searching: false,
        ),
        isFalse,
      );
      expect(
        DiscoverExploreChromeLogic.compactExploreChrome(
          hasSelection: false,
          searching: true,
        ),
        isTrue,
      );
      expect(
        DiscoverExploreChromeLogic.showExploreLayerRow(
          hasSelection: true,
          planning: false,
        ),
        isTrue,
      );
      expect(
        DiscoverExploreChromeLogic.showExploreLayerRow(
          hasSelection: false,
          planning: true,
        ),
        isFalse,
      );
      expect(
        DiscoverExploreChromeLogic.chromeShowsPlanCta(true),
        isTrue,
      );
      expect(
        DiscoverExploreChromeLogic.chromeShowsPlanCta(false),
        isTrue,
      );
      expect(
        DiscoverExploreChromeLogic.layerRowTop(
          statusTop: 52,
          chromeHeight: DiscoverExploreChromeLogic.exploreChromeBodyHeight,
        ),
        greaterThan(52 + 92),
      );
      expect(
        DiscoverExploreChromeLogic.backClearsSelection(
          selectedTourId: 'seed-loop-heidelberg-boxberg-gravel-60',
          atPeek: true,
        ),
        isTrue,
      );
      expect(
        DiscoverExploreChromeLogic.backClearsSelection(
          selectedTourId: 'seed-loop-heidelberg-boxberg-gravel-60',
          atPeek: false,
        ),
        isFalse,
      );
      expect(
        DiscoverExploreChromeLogic.backClearsSelection(
          selectedTourId: null,
          atPeek: true,
        ),
        isFalse,
      );
    });

    test('idle peek stays empty until a tour is chosen', () {
      expect(DiscoverExploreChromeLogic.showIdlePeek(null), isFalse);
      expect(DiscoverExploreChromeLogic.showIdlePeek(''), isFalse);
      expect(
        DiscoverExploreChromeLogic.showIdlePeek(
          'seed-loop-karlsruhe-hardtwald-mtb',
        ),
        isTrue,
      );
    });

    test('Explore layers default to all classes, not the active bike', () {
      expect(DiscoverExploreChromeLogic.defaultDurationMin, 0);
      expect(DiscoverExploreChromeLogic.mapDurationChips, [30, 60, 90, 0]);
      expect(
        DiscoverExploreChromeLogic.overlayClassesForLayers(
          trailsOn: true,
          waysOn: true,
        ),
        containsAll([
          BikeOverlayClass.mtb,
          BikeOverlayClass.gravel,
          BikeOverlayClass.road,
          BikeOverlayClass.urban,
        ]),
      );
      expect(
        DiscoverExploreChromeLogic.overlayClassesForLayers(
          trailsOn: true,
          waysOn: false,
        ).intersection(DiscoverExploreChromeLogic.wayOverlayClasses),
        isEmpty,
      );
      expect(
        DiscoverExploreChromeLogic.overlayClassesForLayers(
          trailsOn: false,
          waysOn: true,
        ).intersection(DiscoverExploreChromeLogic.trailOverlayClasses),
        isEmpty,
      );
      expect(
        DiscoverExploreChromeLogic.legendShowsMeshNote(
          isMesh: true,
          expanded: false,
        ),
        isFalse,
      );
      expect(
        DiscoverExploreChromeLogic.legendShowsMeshNote(
          isMesh: true,
          expanded: true,
        ),
        isTrue,
      );
    });

    test('Hof pin survives empty nearby and missing catalog', () {
      expect(
        DiscoverExploreChromeLogic.keepHofPin(
          selectedTourId: 'seed-loop-heidelberg-boxberg-gravel-60',
          selectedFound: false,
          selectedNearby: false,
          loopsAvailable: false,
        ),
        isTrue,
      );
      expect(
        DiscoverExploreChromeLogic.keepHofPin(
          selectedTourId: 'seed-loop-heidelberg-boxberg-gravel-60',
          selectedFound: false,
          selectedNearby: false,
          loopsAvailable: true,
        ),
        isTrue,
      );
      expect(
        DiscoverExploreChromeLogic.keepHofPin(
          selectedTourId: 'seed-loop-heidelberg-boxberg-gravel-60',
          selectedFound: true,
          selectedNearby: true,
          loopsAvailable: true,
        ),
        isTrue,
      );
      expect(
        DiscoverExploreChromeLogic.keepHofPin(
          selectedTourId: 'seed-loop-heidelberg-boxberg-gravel-60',
          selectedFound: true,
          selectedNearby: false,
          loopsAvailable: true,
        ),
        isFalse,
      );
      expect(
        DiscoverExploreChromeLogic.keepHofPin(
          selectedTourId: null,
          selectedFound: false,
          selectedNearby: false,
          loopsAvailable: false,
        ),
        isFalse,
      );
    });
  });
}
