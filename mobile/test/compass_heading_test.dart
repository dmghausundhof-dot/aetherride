import 'package:aetherride_mobile/domain/routing/compass_heading.dart';
import 'package:aetherride_mobile/domain/routing/tour_nav_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CompassHeading', () {
    test('heading buckets stay out of the default tour list', () {
      expect(CompassHeading.showBucketsInDefaultTourList, isFalse);
    });

    test('peek uses selected tour, never a heading card', () {
      expect(
        CompassHeading.peekTourId(
          selectedTourId: null,
          firstFilteredTourId: 'seed-mittel-14',
        ),
        'seed-mittel-14',
      );
      expect(
        CompassHeading.peekTourId(
          selectedTourId: 'seed-mittel-14',
          firstFilteredTourId: 'other',
        ),
        'seed-mittel-14',
      );
    });

    test('Discover overlay gate stays off for demo/heading', () {
      expect(
        CompassHeading.hideComputedRibbonOnDiscover(
          isDemoOrApprox: true,
          discoverExplore: true,
        ),
        isTrue,
      );
      expect(
        CompassHeading.hideComputedRibbonOnDiscover(
          isDemoOrApprox: false,
          discoverExplore: true,
        ),
        isFalse,
      );
      expect(
        CompassHeading.hideComputedRibbonOnDiscover(
          isDemoOrApprox: true,
          discoverExplore: false,
        ),
        isFalse,
        reason: 'Navigieren may preview the planned A→B',
      );
      expect(
        shouldPaintActiveComputedRibbon(
          trackLngLat: [
            [8.67, 49.28],
            [8.67, 49.34],
            [8.68, 49.36],
            [8.69, 49.38],
          ],
          isHeadingOrDemoOverlay: true,
          approachPaintedSeparately: false,
        ),
        isFalse,
      );
    });
  });
}
