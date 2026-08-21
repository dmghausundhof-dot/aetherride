import 'package:flutter_test/flutter_test.dart';
import 'package:aetherride_mobile/domain/routing/tour_filters.dart';
import 'package:aetherride_mobile/domain/routing/trail_difficulty.dart';
import 'package:aetherride_mobile/presentation/discover/discover_map_line_style.dart';

void main() {
  test('Discover map tour cap stays above prior 16 without spam', () {
    expect(DiscoverMapLineStyle.mapTourCap, greaterThanOrEqualTo(20));
    expect(DiscoverMapLineStyle.mapTourCap, lessThanOrEqualTo(48));
    expect(DiscoverMapLineStyle.warmBatchSize, inInclusiveRange(3, 8));
  });

  test('selected routed line is brighter and thicker than unselected', () {
    expect(DiscoverMapLineStyle.selectedRouted, '#FF6A00');
    expect(DiscoverMapLineStyle.planSteep, '#C2410C');
    expect(DiscoverMapLineStyle.selectedRouted, isNot('#00E676'));
    expect(DiscoverMapLineStyle.unselectedRouted, isNot(DiscoverMapLineStyle.selectedRouted));
    expect(
      DiscoverMapLineStyle.activeWidth,
      greaterThan(DiscoverMapLineStyle.inactiveWidth),
    );
    expect(
      DiscoverMapLineStyle.activeWidth,
      lessThan(6.5),
      reason: 'selected orange ribbon stays slim next to pins',
    );
    expect(
      DiscoverMapLineStyle.activeOpacity,
      greaterThan(DiscoverMapLineStyle.inactiveOpacity),
    );
    expect(
      DiscoverMapLineStyle.inactiveOpacity,
      greaterThan(0.5),
      reason: 'unselected routes must stay visible like Komoot',
    );
    expect(
      DiscoverMapLineStyle.activeCasingWidth,
      greaterThan(DiscoverMapLineStyle.mutedCasingWidth),
    );
    expect(
      DiscoverMapLineStyle.selectedGlowWidth,
      greaterThan(DiscoverMapLineStyle.activeCasingWidth),
    );
    expect(DiscoverMapLineStyle.selectedGlowOpacity, lessThan(0.4));
  });

  test('trail overlay stays under tour ribbons', () {
    expect(DiscoverMapLineStyle.trailUnselectedOpacity, lessThan(0.4));
  });

  test('pending A–B ghost stays lighter than the live ribbon', () {
    expect(DiscoverMapLineStyle.pendingAbOpacity, lessThan(0.75));
    expect(
      DiscoverMapLineStyle.pendingAbWidth,
      lessThan(DiscoverMapLineStyle.activeWidth),
    );
    expect(DiscoverMapLineStyle.pendingAbDash.length, 2);
    expect(DiscoverMapLineStyle.planRubber, '#FF6A00');
    expect(
      DiscoverMapLineStyle.planRubberOpacity,
      greaterThan(DiscoverMapLineStyle.pendingAbOpacity),
    );
    expect(
      DiscoverMapLineStyle.planGrabHaloWidth,
      greaterThan(DiscoverMapLineStyle.activeWidth * 4),
    );
    expect(
      DiscoverMapLineStyle.planGrabHaloOpacity,
      greaterThan(0),
      reason: 'MapLibre skips fully transparent line hits',
    );
    expect(
      DiscoverMapLineStyle.planGrabHaloOpacity,
      lessThan(0.04),
      reason: 'native first-frame translate must stay invisible',
    );
  });

  test('gravel, road and DH ribbons are not the same mint green', () {
    final gravel = DiscoverMapLineStyle.ribbonForTour(
      sport: TourSportKey.gravel,
      scale: TrailDifficulty.open,
      selected: false,
      routed: true,
    );
    final road = DiscoverMapLineStyle.ribbonForTour(
      sport: TourSportKey.road,
      scale: TrailDifficulty.open,
      selected: false,
      routed: true,
    );
    final mtb = DiscoverMapLineStyle.ribbonForTour(
      sport: TourSportKey.mtb,
      scale: TrailDifficulty.open,
      selected: true,
      routed: true,
    );
    final s2 = DiscoverMapLineStyle.ribbonForTour(
      sport: TourSportKey.mtb,
      scale: TrailDifficulty.s2,
      selected: false,
      routed: true,
    );
    expect(gravel, isNot(mtb));
    expect(road, isNot(mtb));
    expect(road, isNot(gravel));
    expect(s2, trailDifficultyColor(TrailDifficulty.s2));
    expect(DiscoverMapLineStyle.approachCore, '#29B6F6');
    expect(
      DiscoverMapLineStyle.approachCore,
      isNot(DiscoverMapLineStyle.selectedRouted),
    );
  });

  test('plan outside pack is sage, not chrome', () {
    expect(DiscoverMapLineStyle.packOutside, '#7A8B73');
    expect(
      DiscoverMapLineStyle.packOutside,
      isNot(DiscoverMapLineStyle.selectedRouted),
    );
    expect(
      DiscoverMapLineStyle.packOutsideCasing,
      isNot(DiscoverMapLineStyle.packOutside),
    );
    expect(DiscoverMapLineStyle.packOutsideDash.length, 2);
    expect(
      DiscoverMapLineStyle.packOutsideWidth,
      lessThan(DiscoverMapLineStyle.activeWidth),
    );
  });
}
