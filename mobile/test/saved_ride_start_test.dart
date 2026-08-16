import 'package:aetherride_mobile/domain/saved_route.dart';
import 'package:aetherride_mobile/domain/tours/saved_ride_start.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('activeRouteFromSaved needs a real track', () {
    final empty = SavedRouteEntry(
      id: 'saved-empty',
      name: 'Nur Name',
      distanceKm: 10,
      elevationM: 100,
      durationMin: 40,
      savedAt: DateTime.utc(2026, 8, 15),
    );
    expect(activeRouteFromSaved(empty), isNull);

    final withTrack = SavedRouteEntry(
      id: 'saved-track',
      name: 'Neckar',
      distanceKm: 16,
      elevationM: 80,
      durationMin: 60,
      savedAt: DateTime.utc(2026, 8, 15),
      coordinates: const [
        [8.67, 49.41],
        [8.68, 49.42],
        [8.69, 49.41],
      ],
    );
    final route = activeRouteFromSaved(withTrack);
    expect(route, isNotNull);
    expect(route!.id, 'saved-track');
    expect(route.coordinates.length, 3);
  });
}
