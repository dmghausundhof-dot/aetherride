import 'package:aetherride_mobile/domain/routing/route_honesty.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('weather hint is never an mtb:scale', () {
    for (final hint in ['wet_likely', 'damp_possible', 'dry_likely', 'closed']) {
      expect(scaleFromConditionHint(hint), isNull);
    }
  });

  test('ORS traildifficulty is never an S-grade', () {
    expect(scaleFromOrsTrailDifficulty(1), isNull);
    expect(scaleFromOrsTrailDifficulty(6), isNull);
  });

  test('parseHonestyBands keeps OSM surface and honest scale only', () {
    final surface = parseHonestyBands([
      {'fromKm': 0, 'toKm': 1.2, 'surface': 'asphalt'},
      {'fromKm': 1.2, 'toKm': 2, 'surface': 'dirt'},
    ], scale: false);
    expect(surface.first.surface, 'asphalt');

    final scale = parseHonestyBands([
      {'fromKm': 0, 'toKm': 1, 'scale': 'S2'},
      {'fromKm': 1, 'toKm': 2, 'scale': 'T3'},
      {'fromKm': 2, 'toKm': 3, 'scale': 'wet_likely'},
    ], scale: true);
    expect(dominantHonestScale(scale), 'S2');
    expect(scale.where((b) => b.scale == 'T3'), isEmpty);
    expect(scale.where((b) => b.scale == 'wet_likely'), isEmpty);
  });

  test('manual compute recedes once the tour exists', () {
    expect(
      planManualComputeVisible(
        hasStart: true,
        hasEnd: true,
        routingBusy: false,
        hasComputed: true,
      ),
      isFalse,
    );
    expect(
      planManualComputeVisible(
        hasStart: true,
        hasEnd: true,
        routingBusy: false,
        hasComputed: false,
      ),
      isTrue,
    );
  });
}
