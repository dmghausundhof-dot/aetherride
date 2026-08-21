import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/component.dart';
import 'package:aetherride_mobile/domain/maintenance/wear_forecast.dart';
import 'package:aetherride_mobile/domain/ride.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chain wear is a range, never a point', () {
    const bike = Bike(
      id: 'b1',
      name: 'Trail',
      category: BikeCategory.mtbTrail,
    );
    final chain = BikeComponent(
      id: 'c1',
      bikeId: 'b1',
      slot: ComponentSlot.chain,
      installedAt: DateTime(2024, 1, 1),
    );
    final rides = [
      RideRecord(
        id: 'r1',
        bikeId: 'b1',
        startedAt: DateTime(2024, 6, 1),
        endedAt: DateTime(2024, 6, 1, 2),
        distanceKm: 800,
        movingTimeSec: 3600 * 4,
      ),
    ];
    final out = forecastWear(
      bike: bike,
      components: [chain],
      rides: rides,
    );
    expect(out, hasLength(1));
    expect(out.first.slot, ComponentSlot.chain);
    expect(out.first.remainingKmHigh, greaterThan(out.first.remainingKmLow));
  });

  test('no wear parts means empty forecast', () {
    const bike = Bike(
      id: 'b1',
      name: 'Trail',
      category: BikeCategory.mtbTrail,
    );
    expect(
      forecastWear(bike: bike, components: const [], rides: const []),
      isEmpty,
    );
  });
}
