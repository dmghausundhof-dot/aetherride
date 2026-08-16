import 'package:aetherride_mobile/domain/routing/trail_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const line = <List<double>>[
    [8.40, 49.40],
    [8.41, 49.41],
    [8.42, 49.42],
  ];

  test('nearest end when not downhill', () {
    final o = orientTrail(
      geometry: line,
      fromLat: 49.42,
      fromLng: 8.42,
      preferDownhill: false,
    );
    expect(o.reversed, isTrue);
    expect(o.usedElevation, isFalse);
    expect(o.entryLat, closeTo(49.42, 1e-9));
  });

  test('gravity uses higher endpoint as start', () {
    final o = orientTrail(
      geometry: line,
      fromLat: 49.40,
      fromLng: 8.40,
      startElevM: 200,
      endElevM: 800,
      preferDownhill: true,
    );
    expect(o.usedElevation, isTrue);
    expect(o.reversed, isTrue);
    expect(o.entryLat, closeTo(49.42, 1e-9));
    expect(o.exitLat, closeTo(49.40, 1e-9));
  });

  test('gravity keeps OSM order when first point is already the top', () {
    final o = orientTrail(
      geometry: line,
      fromLat: 49.42,
      fromLng: 8.42,
      startElevM: 900,
      endElevM: 200,
      preferDownhill: true,
    );
    expect(o.reversed, isFalse);
    expect(o.entryLat, closeTo(49.40, 1e-9));
  });

  test('tiny elev delta falls back to nearest', () {
    final o = orientTrail(
      geometry: line,
      fromLat: 49.42,
      fromLng: 8.42,
      startElevM: 410,
      endElevM: 412,
      preferDownhill: true,
    );
    expect(o.usedElevation, isFalse);
    expect(o.reversed, isTrue);
  });
}
