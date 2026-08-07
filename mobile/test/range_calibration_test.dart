import 'package:flutter_test/flutter_test.dart';
import 'package:aetherride_mobile/domain/bike.dart';
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
}
