import 'package:flutter_test/flutter_test.dart';
import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/component.dart';
import 'package:aetherride_mobile/domain/ebike/range.dart';

void main() {
  test('calibrateFromRide increases samples', () {
    final prev = defaultCalibration(category: BikeCategory.emtb);
    final next = calibrateFromRide(
      prev: prev,
      distanceKm: 18,
      movingTimeSec: 3600,
      batteryWhUsed: 220,
    );
    expect(next.samples, prev.samples + 1);
    expect(next.updatedAt, isNotNull);
  });

  test('calibrateFromRide skips short rides', () {
    final prev = defaultCalibration(category: BikeCategory.emtb);
    final next = calibrateFromRide(
      prev: prev,
      distanceKm: 1,
      movingTimeSec: 600,
      batteryWhUsed: 5,
    );
    expect(next.samples, prev.samples);
  });

  test('packCapacityWh reads garage battery, never invents 500', () {
    expect(packCapacityWh(const []), isNull);
    expect(
      packCapacityWh([
        const BikeComponent(
          id: 'b1',
          bikeId: 'bike',
          slot: ComponentSlot.battery,
          catalogModelId: 'cm-bosch-powertube-800',
        ),
      ]),
      800,
    );
    expect(
      packCapacityWh([
        const BikeComponent(
          id: 'b2',
          bikeId: 'bike',
          slot: ComponentSlot.battery,
          attributes: {'capacity_wh': 625},
        ),
      ]),
      625,
    );
  });

  test('rideEnergyUsedWh needs pack Wh and SoC drop — no 12 Wh/km', () {
    expect(
      rideEnergyUsedWh(
        distanceKm: 10,
        startSoc: 80,
        endSoc: 60,
        packWh: 500,
      ),
      100,
    );
    expect(
      rideEnergyUsedWh(
        distanceKm: 10,
        startSoc: 80,
        endSoc: 60,
      ),
      isNull,
    );
    expect(
      rideEnergyUsedWh(distanceKm: 40),
      isNull,
    );
    expect(
      shouldCalibrateRange(distanceKm: 10, batteryWhUsed: null),
      isFalse,
    );
    expect(
      shouldCalibrateRange(distanceKm: 10, batteryWhUsed: 120),
      isTrue,
    );
  });
}
