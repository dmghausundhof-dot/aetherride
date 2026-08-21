import 'package:flutter_test/flutter_test.dart';
import 'package:aetherride_mobile/data/routing/offline_maps_prefs.dart';

void main() {
  test('pointInBbox matches pack envelope', () {
    const bbox = [8.2, 49.2, 9.0, 49.6];
    expect(OfflineMapsPrefs.pointInBbox(bbox, 8.68, 49.41), isTrue);
    expect(OfflineMapsPrefs.pointInBbox(bbox, 13.4, 52.5), isFalse);
  });

  test('routeCoveredByBbox requires vias and along samples', () {
    const bbox = [8.2, 49.2, 9.0, 49.6];
    expect(
      OfflineMapsPrefs.routeCoveredByBbox(
        bbox: bbox,
        fromLng: 8.68,
        fromLat: 49.41,
        toLng: 8.47,
        toLat: 49.48,
      ),
      isTrue,
    );
    expect(
      OfflineMapsPrefs.routeCoveredByBbox(
        bbox: bbox,
        fromLng: 8.68,
        fromLat: 49.41,
        toLng: 8.47,
        toLat: 49.48,
        vias: [(lng: 13.4, lat: 52.5)],
      ),
      isFalse,
    );
    expect(
      OfflineMapsPrefs.routeCoveredByBbox(
        bbox: bbox,
        fromLng: 8.68,
        fromLat: 49.41,
        toLng: 8.47,
        toLat: 49.48,
        along: [(lng: 8.5, lat: 49.3), (lng: 9.4, lat: 49.4)],
      ),
      isFalse,
    );
  });

  test('coversPoint is false without an activated pack', () async {
    expect(await OfflineMapsPrefs.coversPoint(8.68, 49.41), isFalse);
  });

  test('packBboxFrom requires four numbers', () {
    expect(OfflineMapsPrefs.packBboxFrom({}), isNull);
    expect(
      OfflineMapsPrefs.packBboxFrom({
        'packBbox': [8.2, 49.2, 9.0, 49.6],
      }),
      [8.2, 49.2, 9.0, 49.6],
    );
  });

  test('packIdFromActivatedPath takes the folder name', () {
    expect(OfflineMapsPrefs.packIdFromActivatedPath(null), isNull);
    expect(OfflineMapsPrefs.packIdFromActivatedPath(''), isNull);
    expect(
      OfflineMapsPrefs.packIdFromActivatedPath(
        '/docs/regions/rhein-neckar',
      ),
      'rhein-neckar',
    );
    expect(
      OfflineMapsPrefs.packIdFromActivatedPath(r'C:\docs\regions\de-saarland'),
      'de-saarland',
    );
  });
}
