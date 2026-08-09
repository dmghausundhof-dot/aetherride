import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/domain/ble/csc_measurement.dart';

void main() {
  test('CSC wheel+crank yields speed and cadence without inventing SoC', () {
    // flags=0x03 (wheel+crank), 1 wheel rev in 1024 ticks (=1s), 1 crank rev
    final first = parseCscMeasurement(
      [0x03, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      wheelCircumferenceM: 2.1,
    );
    final second = parseCscMeasurement(
      [0x03, 1, 0, 0, 0, 0, 4, 1, 0, 0, 4],
      wheelCircumferenceM: 2.1,
      prevWheelRevs: first.prevWheelRevs,
      prevWheelEventTime: first.prevWheelEventTime,
      prevCrankRevs: first.prevCrankRevs,
      prevCrankEventTime: first.prevCrankEventTime,
    );
    // 2.1 m / 1 s * 3.6 = 7.56 km/h
    expect(second.speedKmh, closeTo(7.56, 0.01));
    // 1 rev / 1 s * 60 = 60 rpm
    expect(second.cadenceRpm, closeTo(60, 0.01));
  });

  test('CSC crank-only does not invent speed from cadence', () {
    final first = parseCscMeasurement(
      [0x02, 10, 0, 0, 0],
      wheelCircumferenceM: 2.1,
      speedKmh: 0,
    );
    final second = parseCscMeasurement(
      [0x02, 11, 0, 0, 4],
      wheelCircumferenceM: 2.1,
      prevCrankRevs: first.prevCrankRevs,
      prevCrankEventTime: first.prevCrankEventTime,
      speedKmh: 0,
    );
    expect(second.speedKmh, 0);
    expect(second.cadenceRpm, closeTo(60, 0.01));
  });
}
