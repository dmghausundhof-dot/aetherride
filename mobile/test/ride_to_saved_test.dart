import 'package:aetherride_mobile/data/routing/ride_to_saved.dart';
import 'package:aetherride_mobile/domain/ride.dart';
import 'package:aetherride_mobile/domain/saved_route_note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trackToLngLat keeps valid points as [lng,lat]', () {
    final coords = trackToLngLat([
      {'lat': 48.4, 'lng': 9.9},
      {'lat': 48.41, 'lng': 9.91},
      {'lat': 999, 'lng': 0}, // invalid
    ]);
    expect(coords, [
      [9.9, 48.4],
      [9.91, 48.41],
    ]);
  });

  test('rideRecordToSavedEntry marks source recorded', () {
    final ride = RideRecord(
      id: 'ride-1',
      bikeId: 'bike-1',
      startedAt: DateTime.utc(2026, 8, 12, 10),
      endedAt: DateTime.utc(2026, 8, 12, 11),
      distanceKm: 12.5,
      movingTimeSec: 3600,
      elevationM: 140,
      name: 'Test Freeride',
      track: [
        {'lat': 48.4, 'lng': 9.9},
        {'lat': 48.41, 'lng': 9.91},
        {'lat': 48.42, 'lng': 9.92},
      ],
    );
    final entry = rideRecordToSavedEntry(ride);
    expect(entry.source, 'recorded');
    expect(entry.name, 'Test Freeride');
    expect(entry.coordinates.length, 3);
    expect(entry.tour.length, 3);
    expect(entry.distanceKm, 12.5);
    expect(entry.durationMin, 60);
    expect(entry.id, startsWith('recorded-'));
  });

  test('SavedRouteNote + Meta roundtrip JSON', () {
    final note = SavedRouteNote.create(text: 'Schöner Flow', authorLabel: 'Du');
    final meta = SavedRouteMeta(
      description: 'Hausrunde',
      photoPaths: const ['/tmp/a.jpg'],
      notes: [note],
      rideId: 'ride-1',
    );
    final decoded = SavedRouteMeta.fromJson(meta.toJson());
    expect(decoded.description, 'Hausrunde');
    expect(decoded.photoPaths, ['/tmp/a.jpg']);
    expect(decoded.notes.single.text, 'Schöner Flow');
    expect(decoded.rideId, 'ride-1');
  });
}
