import 'package:flutter_test/flutter_test.dart';
import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/routing/bike_overlay_class.dart';

void main() {
  test('mtb:scale path is mtb S2, never inferred from sac_scale', () {
    final tagged = classifyBikeWay({
      'highway': 'path',
      'mtb:scale': '2',
    });
    expect(tagged.bikeClass, BikeOverlayClass.mtb);
    expect(tagged.mtbScale, MtbScaleLabel.s2);
    expect(mtbScaleCss(MtbScaleLabel.s3), 'S3+');
    expect(parseOsmMtbScale('4'), MtbScaleLabel.s3);

    final sacOnly = classifyBikeWay({
      'highway': 'path',
      'sac_scale': 'mountain_hiking',
    });
    expect(sacOnly.bikeClass, BikeOverlayClass.mtbUnrated);
    expect(sacOnly.mtbScale, isNull);
  });

  test('untagged path/track is offen/unbewertet, not S2', () {
    final r = classifyBikeWay({'highway': 'path', 'surface': 'ground'});
    expect(r.bikeClass, BikeOverlayClass.mtbUnrated);
    expect(r.mtbScale, isNull);
  });

  test('hides bicycle=no and mtb=no', () {
    expect(
      classifyBikeWay({
        'highway': 'path',
        'mtb:scale': '1',
        'bicycle': 'no',
      }).bikeClass,
      BikeOverlayClass.hidden,
    );
    expect(
      classifyBikeWay({'highway': 'track', 'mtb': 'no'}).bikeClass,
      BikeOverlayClass.hidden,
    );
  });

  test('gravel / road / urban classes', () {
    expect(
      classifyBikeWay({
        'highway': 'track',
        'tracktype': 'grade2',
        'surface': 'fine_gravel',
      }).bikeClass,
      BikeOverlayClass.gravel,
    );
    expect(
      classifyBikeWay({
        'highway': 'cycleway',
        'surface': 'asphalt',
        'bicycle': 'designated',
      }).bikeClass,
      BikeOverlayClass.road,
    );
    expect(
      classifyBikeWay({'highway': 'living_street'}).bikeClass,
      BikeOverlayClass.urban,
    );
  });

  test('imba tag colors mtb, garage family defaults', () {
    final r = classifyBikeWay({
      'highway': 'track',
      'mtb:scale:imba': '0',
    });
    expect(r.bikeClass, BikeOverlayClass.mtb);
    expect(r.mtbScale, MtbScaleLabel.s0);
    expect(
      overlayClassesForFamily(overlayFamilyForBike(BikeCategory.mtbAm)),
      [BikeOverlayClass.mtb, BikeOverlayClass.mtbUnrated],
    );
    expect(
      overlayClassesForFamily(overlayFamilyForBike(BikeCategory.gravel)),
      [BikeOverlayClass.gravel],
    );
  });

  test('City default extraOn skips S-scale; MTB keeps trails', () {
    expect(
      overlayDefaultExtraOn(BikeOverlayFamily.urban),
      {BikeOverlayClass.urban, BikeOverlayClass.road},
    );
    expect(
      overlayDefaultExtraOn(BikeOverlayFamily.mtb),
      {BikeOverlayClass.mtb, BikeOverlayClass.mtbUnrated},
    );
    expect(overlayLegendShowsSScale(BikeOverlayFamily.urban), isFalse);
    expect(overlayLegendShowsSScale(BikeOverlayFamily.mtb), isTrue);
    expect(
      overlayLegendRows(family: BikeOverlayFamily.urban, expanded: false),
      isEmpty,
    );
    expect(
      overlayLegendRows(family: BikeOverlayFamily.urban, expanded: true)
          .map((r) => r.key),
      ['urban', 'road'],
    );
    expect(
      overlayLegendRows(family: BikeOverlayFamily.mtb, expanded: true)
          .map((r) => r.key),
      ['S0', 'S1', 'S2', 'S3+', 'unrated'],
    );
  });

  test('Discover overlay default is all classes; off hides, never 16%', () {
    expect(kAllPaintedOverlayClasses, contains(BikeOverlayClass.mtbUnrated));
    expect(kAllPaintedOverlayClasses, contains(BikeOverlayClass.road));
    expect(
      overlayClassesShown(
        overlayOn: true,
        extraOn: kAllPaintedOverlayClasses,
      ),
      kAllPaintedOverlayClasses,
    );
    expect(
      overlayClassesShown(
        overlayOn: false,
        extraOn: kAllPaintedOverlayClasses,
      ),
      isEmpty,
    );
    expect(
      overlayClassesShown(
        overlayOn: true,
        extraOn: {BikeOverlayClass.gravel},
      ),
      {BikeOverlayClass.gravel},
    );
  });

  test('signed cycle-route mesh keeps icn/ncn/rcn/mtb, drops lcn', () {
    expect(
      classifyBikeRoute({
        'route': 'bicycle',
        'network': 'icn',
        'ref': 'EV15',
      }).bikeClass,
      BikeOverlayClass.road,
    );
    expect(keepSignedCycleMesh({'route': 'bicycle', 'network': 'lcn'}), isFalse);
    expect(keepSignedCycleMesh({'route': 'bicycle', 'network': 'rcn'}), isTrue);
    expect(keepSignedCycleMesh({'route': 'bicycle', 'ref': 'EV6'}), isTrue);
    expect(keepSignedCycleMesh({'route': 'mtb'}), isFalse);
  });

  test('surface kind and line-color keep class fallback without field', () {
    expect(bikeOverlaySurfaceKind('asphalt'), BikeOverlaySurfaceKind.paved);
    expect(bikeOverlaySurfaceKind('compacted'), BikeOverlaySurfaceKind.gravel);
    expect(bikeOverlaySurfaceKind('dirt'), BikeOverlaySurfaceKind.dirt);
    expect(bikeOverlaySurfaceKind('unpaved'), BikeOverlaySurfaceKind.dirt);
    expect(bikeOverlaySurfaceKind(''), BikeOverlaySurfaceKind.unknown);
    final expr = bikeOverlaySurfaceLineColor(BikeOverlayColors.road);
    expect(expr.first, 'case');
    expect(expr.toString(), contains('has'));
    expect(expr.toString(), contains('surface'));
    expect(expr.toString(), contains('asphalt'));
    expect(expr.toString(), contains('any'));
    expect(expr[2], BikeOverlayColors.road);
    expect(expr.toString(), contains(BikeOverlayColors.dirt));
    expect(expr.toString(), contains(BikeOverlayColors.road));
  });
}
