import 'package:flutter_test/flutter_test.dart';
import 'package:aetherride_mobile/data/routing/routing_client.dart';
import 'package:aetherride_mobile/domain/routing/engine_steps_along.dart';

void main() {
  test('sampleTrackWaypoints keeps start and end', () {
    final pts = [
      for (var i = 0; i < 40; i++) GeoPoint(49.4 + i * 0.001, 8.7 + i * 0.001),
    ];
    final sampled = sampleTrackWaypoints(pts, maxPoints: 8);
    expect(sampled.length, inInclusiveRange(2, 8));
    expect(sampled.first.lat, pts.first.lat);
    expect(sampled.last.lat, closeTo(pts.last.lat, 0.002));
  });

  test('remapEngineStepsOntoTrack projects by coordinate', () {
    final track = [
      [8.70, 49.40],
      [8.71, 49.40],
      [8.72, 49.41],
    ];
    final steps = [
      const RouteStep(
        id: 'a',
        instruction: 'Rechts abbiegen auf Hauptstraße',
        distanceAlongM: 9999,
        streetName: 'Hauptstraße',
        lat: 49.40,
        lng: 8.71,
      ),
    ];
    final remapped = remapEngineStepsOntoTrack(steps, track);
    expect(remapped.single.distanceAlongM, lessThan(2000));
    expect(remapped.single.streetName, 'Hauptstraße');
  });

  test('engineStepsUseful requires streets or enough maneuvers', () {
    expect(
      engineStepsUseful([
        const RouteStep(id: '1', instruction: 'Losfahren', distanceAlongM: 0),
        const RouteStep(id: '2', instruction: 'Weiter', distanceAlongM: 10),
      ]),
      isFalse,
    );
    expect(
      engineStepsUseful([
        const RouteStep(id: '1', instruction: 'Losfahren', distanceAlongM: 0),
        const RouteStep(
          id: '2',
          instruction: 'Links abbiegen auf Neckarstaden',
          distanceAlongM: 120,
          streetName: 'Neckarstaden',
        ),
        const RouteStep(id: '3', instruction: 'Ziel erreicht', distanceAlongM: 400),
      ]),
      isTrue,
    );
  });
}
