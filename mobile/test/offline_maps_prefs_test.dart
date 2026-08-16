import 'package:flutter_test/flutter_test.dart';
import 'package:aetherride_mobile/data/routing/offline_maps_prefs.dart';

void main() {
  test('pointInBbox matches pack envelope', () {
    const bbox = [8.2, 49.2, 9.0, 49.6];
    expect(OfflineMapsPrefs.pointInBbox(bbox, 8.68, 49.41), isTrue);
    expect(OfflineMapsPrefs.pointInBbox(bbox, 13.4, 52.5), isFalse);
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
}
