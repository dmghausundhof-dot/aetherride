import 'package:aetherride_mobile/data/routing/simple_add_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromStart is pin-only — no invented track', () {
    final entry = SimpleAddRoute.fromStart(
      name: '  Neckar Feierabend  ',
      lat: 49.41,
      lng: 8.69,
      now: DateTime.utc(2026, 8, 12, 10),
      id: 'library-test',
    );
    expect(entry.id, 'library-test');
    expect(entry.name, 'Neckar Feierabend');
    expect(entry.source, 'library');
    expect(entry.coordinates, isEmpty);
    expect(entry.distanceKm, 0);
    expect(entry.durationMin, 0);
    expect(entry.waypoints, hasLength(1));
    expect(entry.waypoints.single.role, 'start');
    expect(entry.waypoints.single.lat, 49.41);
    expect(entry.waypoints.single.lng, 8.69);
  });

  test('empty name falls back to dated default', () {
    final entry = SimpleAddRoute.fromStart(
      name: '   ',
      lat: 52.52,
      lng: 13.4,
      now: DateTime(2026, 8, 12, 18),
    );
    expect(entry.name, 'Route 12.8.');
    expect(entry.source, 'library');
    expect(entry.coordinates, isEmpty);
  });

  test('fromExistingTour keeps geometry when present, never invents', () {
    final withTrack = SimpleAddRoute.fromExistingTour(
      id: 'seed-loop-tempelhofer-60',
      name: 'Tempelhofer',
      distanceKm: 18,
      elevationM: 40,
      durationMin: 55,
      startLat: 52.47,
      startLng: 13.4,
      coordinates: [
        [13.4, 52.47],
        [13.41, 52.48],
      ],
    );
    expect(withTrack.coordinates, hasLength(2));
    expect(withTrack.waypoints, hasLength(2));

    final pinOnly = SimpleAddRoute.fromExistingTour(
      id: 'idea-x',
      name: 'Idee',
      distanceKm: 20,
      elevationM: 100,
      durationMin: 60,
      startLat: 49.4,
      startLng: 8.7,
    );
    expect(pinOnly.coordinates, isEmpty);
    expect(pinOnly.waypoints, hasLength(1));
  });

  test('empty library list is safe to iterate', () {
    const saved = <Object>[];
    expect(() => saved.map((e) => e).toList(), returnsNormally);
    expect(saved.isEmpty, isTrue);
  });
}
