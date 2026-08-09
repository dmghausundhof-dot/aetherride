import 'package:flutter_test/flutter_test.dart';
import 'package:aetherride_mobile/data/routing/routing_client.dart';
import 'package:aetherride_mobile/domain/routing/nav_cues.dart';

void main() {
  test('navStepsFromPolyline L-shape yields turn and finish', () {
    // ~2 km south then ~2 km east (enough for bearing windows)
    final pts = <({double lat, double lng})>[
      (lat: 48.0, lng: 7.8),
      (lat: 47.991, lng: 7.8),
      (lat: 47.982, lng: 7.8),
      (lat: 47.982, lng: 7.81),
      (lat: 47.982, lng: 7.82),
      (lat: 47.982, lng: 7.83),
    ];
    final steps = navStepsFromPolyline(pts);
    expect(steps, isNotEmpty);
    expect(steps.first.instruction, 'Losfahren');
    expect(steps.any((s) => s.instruction == 'Ziel erreicht'), isTrue);
    expect(
      steps.any(
        (s) =>
            s.instruction.contains('rechts') ||
            s.instruction.contains('links') ||
            s.instruction.contains('Rechts') ||
            s.instruction.contains('Links'),
      ),
      isTrue,
    );
  });

  test('stepsFromCoordinates maps to RouteStep', () {
    final coords = [
      const GeoPoint(48.0, 7.8),
      const GeoPoint(47.99, 7.8),
      const GeoPoint(47.98, 7.8),
      const GeoPoint(47.98, 7.81),
      const GeoPoint(47.98, 7.82),
    ];
    final steps = stepsFromCoordinates(coords);
    expect(steps.first, isA<RouteStep>());
    expect(steps.first.id, 'start');
  });

  test('short polyline still returns start/finish', () {
    final steps = navStepsFromPolyline([
      (lat: 48.0, lng: 7.8),
      (lat: 48.001, lng: 7.801),
    ]);
    expect(steps.length, greaterThanOrEqualTo(2));
    expect(steps.last.instruction, 'Ziel erreicht');
  });
}
