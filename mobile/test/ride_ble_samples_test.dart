import 'package:aetherride_mobile/domain/ble.dart';
import 'package:aetherride_mobile/domain/ble/ride_ble_samples.dart';
import 'package:flutter_test/flutter_test.dart';

BoschLiveData _sample({
  double cadenceRpm = 0,
  double? heartRateBpm,
  double? riderPowerW,
}) {
  return BoschLiveData(
    speedKmh: 0,
    cadenceRpm: cadenceRpm,
    heartRateBpm: heartRateBpm,
    riderPowerW: riderPowerW,
    odometerKm: 0,
    lightStatus: false,
    ambientBrightness: 0,
    systemLock: false,
    bikeNotDriving: true,
    chargerConnected: false,
    timestampMs: 1,
  );
}

void main() {
  test('empty samples write nothing', () {
    expect(RideBleSamples().toSummary(), isEmpty);
  });

  test('HR average and max from live packets only', () {
    final acc = RideBleSamples();
    acc.add(_sample());
    acc.add(_sample(heartRateBpm: 120));
    acc.add(_sample(heartRateBpm: 140));
    acc.add(_sample(heartRateBpm: 0));
    expect(acc.toSummary(), {'avgHr': 130, 'maxHr': 140});
  });

  test('cadence and power skip zeros', () {
    final acc = RideBleSamples();
    acc.add(_sample(cadenceRpm: 80, riderPowerW: 200));
    acc.add(_sample(cadenceRpm: 0, riderPowerW: 0));
    expect(acc.toSummary(), {'avgCadence': 80, 'avgPowerW': 200});
  });

  test('reset clears the ride', () {
    final acc = RideBleSamples()..add(_sample(heartRateBpm: 110));
    acc.reset();
    expect(acc.toSummary(), isEmpty);
  });
}
