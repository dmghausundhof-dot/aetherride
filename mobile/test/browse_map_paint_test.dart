import 'package:aetherride_mobile/domain/routing/bike_overlay_class.dart';
import 'package:aetherride_mobile/domain/routing/browse_map_paint.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('browse map uses three honest colors, not gray paths', () {
    expect(BikeOverlayColors.road, BrowseMapPaint.wayHex);
    expect(BikeOverlayColors.urban, BrowseMapPaint.wayHex);
    expect(BikeOverlayColors.gravel, BrowseMapPaint.gravelHex);
    expect(BikeOverlayColors.unrated, BrowseMapPaint.trailHex);
    expect(BikeOverlayColors.dirt, BrowseMapPaint.trailHex);
    expect(BikeOverlayColors.unrated, isNot('#90A4AE'));
    expect(
      {BrowseMapPaint.wayHex, BrowseMapPaint.gravelHex, BrowseMapPaint.trailHex}
          .length,
      3,
    );
  });

  test('relief is quiet and on by default', () {
    expect(BrowseMapPaint.hillshadeOnByDefault, isTrue);
    expect(BrowseMapPaint.hillshadeExaggeration, lessThan(0.2));
    expect(BrowseMapPaint.hillshadeExaggeration, greaterThan(0.05));
  });

  test('live network paints earlier than the old zoom-12 floor', () {
    expect(BrowseMapPaint.quietOpacity, lessThan(BrowseMapPaint.lineOpacity));
    expect(BrowseMapPaint.opacityForClass('urban'), BrowseMapPaint.quietOpacity);
    expect(BrowseMapPaint.opacityForClass('gravel'), BrowseMapPaint.quietOpacity);
    expect(BrowseMapPaint.opacityForClass('mtb'), BrowseMapPaint.lineOpacity);
    expect(BrowseMapPaint.liveCyclewayMinZoom, lessThanOrEqualTo(10));
    expect(BrowseMapPaint.livePathMinZoom, lessThan(12));
    expect(BrowseMapPaint.liveTrackMinZoom, greaterThanOrEqualTo(13));
    expect(BrowseMapPaint.packMinZoom, 10);
    expect(
      BrowseMapPaint.liveCyclewayWidth,
      greaterThan(BrowseMapPaint.livePathWidth),
    );
    expect(
      BrowseMapPaint.liveCyclewayWidth,
      greaterThan(BrowseMapPaint.liveTrackWidth),
    );
    expect(
      BrowseMapPaint.farmTrackOpacity,
      lessThan(BrowseMapPaint.quietOpacity),
    );
    expect(BrowseMapPaint.farmTrackDash.length, 2);
  });

  test('surface color falls back to class, dirt is trail not brown', () {
    final expr = bikeOverlaySurfaceLineColor(BikeOverlayColors.unrated);
    expect(expr.toString(), contains(BrowseMapPaint.trailHex));
    expect(expr.toString(), isNot(contains('#9A5B32')));
    expect(expr[2], BrowseMapPaint.trailHex);
  });
}
