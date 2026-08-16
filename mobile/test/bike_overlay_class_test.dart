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
}
