import 'package:aetherride_mobile/domain/garage/last_ride_hero.dart';
import 'package:aetherride_mobile/domain/ride.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Hero zeigt echte Kilometer, sonst keine Zahl', () {
    expect(lastRideHeroLine(null), isNull);
    expect(
      lastRideHeroLine(
        RideRecord(
          id: 'r1',
          bikeId: 'b1',
          startedAt: DateTime(2026, 8, 1),
          endedAt: DateTime(2026, 8, 1, 1),
          distanceKm: 12.4,
        ),
      ),
      'Zuletzt 12.4 km',
    );
    expect(
      lastRideHeroLine(
        RideRecord(
          id: 'r2',
          bikeId: 'b1',
          startedAt: DateTime(2026, 8, 1),
          endedAt: DateTime(2026, 8, 1, 1),
          distanceKm: 0,
        ),
      ),
      'Zuletzt unterwegs — ohne GPS-Strecke',
    );
    expect(
      lastRideHeroLine(
        RideRecord(
          id: 'r3',
          bikeId: 'b1',
          startedAt: DateTime(2026, 8, 1),
          endedAt: DateTime(2026, 8, 1, 1),
          distanceKm: 12.4,
          elevationM: 140,
        ),
      ),
      'Zuletzt 12.4 km · 140 hm',
    );
  });

  test('Aktive Session zählt nicht als letzte Fahrt', () {
    final ended = RideRecord(
      id: 'old',
      bikeId: 'b1',
      startedAt: DateTime(2026, 8, 1),
      endedAt: DateTime(2026, 8, 1, 2),
      distanceKm: 8,
    );
    final live = RideRecord(
      id: 'live',
      bikeId: 'b1',
      startedAt: DateTime(2026, 8, 16),
      distanceKm: 1,
    );
    expect(lastEndedRideForBike([live, ended], 'b1')?.id, 'old');
  });
}
