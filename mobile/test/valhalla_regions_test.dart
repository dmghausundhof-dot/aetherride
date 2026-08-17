import 'package:aetherride_mobile/data/routing/valhalla_regions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('valhallaRegionForPoint picks dense packs and country envelopes', () {
    expect(valhallaRegionForPoint(7.85, 47.99)?.id, 'schwarzwald-nord');
    expect(valhallaRegionForPoint(4.9, 52.37)?.id, 'amsterdam');
    expect(valhallaRegionForPoint(5.5, 52.5)?.id, 'nl-netherlands');
    expect(valhallaRegionForPoint(4.35, 50.85)?.id, 'be-belgium');
    expect(valhallaRegionForPoint(11.5, 48.1)?.id, 'de-bayern');
    expect(valhallaRegionForPoint(2.35, 48.86)?.id, 'fr-ile-de-france');
    expect(valhallaRegionForPoint(12.5, 41.9)?.id, 'it-centro');
    expect(valhallaRegionForPoint(13.405, 52.52)?.id, 'de-brandenburg');
    expect(valhallaRegionForPoint(-30, 0), isNull);
  });

  test('valhallaTilesCdnPath mirrors TS', () {
    expect(
      valhallaTilesCdnPath('nl-netherlands'),
      'nl-netherlands/valhalla_tiles.tar',
    );
  });

  test('suggestedValhallaRegionId prefers map center over bbox', () {
    expect(
      suggestedValhallaRegionId(mapLng: 5.5, mapLat: 52.5),
      'nl-netherlands',
    );
    expect(
      suggestedValhallaRegionId(
        regionBbox: [7.7, 47.8, 8.2, 48.15],
      ),
      'schwarzwald-nord',
    );
    // Map center wins when both are set (Amsterdam over Schwarzwald bbox).
    expect(
      suggestedValhallaRegionId(
        mapLng: 4.9,
        mapLat: 52.37,
        regionBbox: [7.7, 47.8, 8.2, 48.15],
      ),
      'amsterdam',
    );
    expect(suggestedValhallaRegionId(), isNull);
  });
}
