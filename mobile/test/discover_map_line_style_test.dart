import 'package:flutter_test/flutter_test.dart';
import 'package:aetherride_mobile/presentation/discover/discover_map_line_style.dart';

void main() {
  test('Discover map tour cap stays above prior 16 without spam', () {
    expect(DiscoverMapLineStyle.mapTourCap, greaterThanOrEqualTo(20));
    expect(DiscoverMapLineStyle.mapTourCap, lessThanOrEqualTo(40));
    expect(DiscoverMapLineStyle.warmBatchSize, inInclusiveRange(3, 8));
  });

  test('selected routed line is brighter and thicker than unselected', () {
    expect(DiscoverMapLineStyle.selectedRouted, '#00E676');
    expect(DiscoverMapLineStyle.unselectedRouted, isNot(DiscoverMapLineStyle.selectedRouted));
    expect(
      DiscoverMapLineStyle.activeWidth,
      greaterThan(DiscoverMapLineStyle.inactiveWidth),
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
  });

  test('trail overlay stays under tour ribbons', () {
    expect(DiscoverMapLineStyle.trailUnselectedOpacity, lessThan(0.4));
  });
}
