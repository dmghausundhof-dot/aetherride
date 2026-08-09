import 'package:flutter_test/flutter_test.dart';
import 'package:aetherride_mobile/domain/routing/route_progress.dart';
import 'package:aetherride_mobile/data/import/gpx_import.dart';

void main() {
  test('projectOntoRoute along mid segment', () {
    final coords = [
      [12.0, 47.0],
      [12.01, 47.0],
      [12.02, 47.0],
    ];
    final mid = projectOntoRoute(
      coordinates: coords,
      lat: 47.0,
      lng: 12.01,
    );
    expect(mid.crossTrackM, lessThan(5));
    expect(mid.distanceAlongM, greaterThan(100));
  });

  test('off-route hysteresis', () {
    expect(
      updateOffRouteState(currentlyOff: false, crossTrackM: 45),
      isTrue,
    );
    expect(
      updateOffRouteState(currentlyOff: true, crossTrackM: 30),
      isTrue,
    );
    expect(
      updateOffRouteState(currentlyOff: true, crossTrackM: 20),
      isFalse,
    );
  });

  test('parseGpx reads trkpt', () {
    const xml = '''
<gpx><trk><name>Testtrail</name><trkseg>
<trkpt lat="47.1" lon="12.2"><ele>800</ele></trkpt>
<trkpt lat="47.11" lon="12.21"><ele>820</ele></trkpt>
</trkseg></trk></gpx>
''';
    final t = parseGpx(xml);
    expect(t, isNotNull);
    expect(t!.name, 'Testtrail');
    expect(t.points.length, 2);
    expect(t.distanceKm, greaterThan(0));
  });
}
