import 'package:aetherride_mobile/domain/ble.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CSC map does not invent SoC, power, assist or HR', () {
    final d = BoschLiveData.fromMap({
      'speedKmh': 22.4,
      'cadenceRpm': 78,
      'odometerKm': 12,
      'lightStatus': false,
      'ambientBrightness': 0,
      'systemLock': false,
      'bikeNotDriving': false,
      'chargerConnected': false,
      'timestampMs': 1,
    });
    expect(d.batterySocPercent, isNull);
    expect(d.riderPowerW, isNull);
    expect(d.assistMode, isNull);
    expect(d.heartRateBpm, isNull);
  });

  test('LDI map keeps SoC and assist when native sends them', () {
    final d = BoschLiveData.fromMap({
      'speedKmh': 18,
      'batterySocPercent': 64,
      'riderPowerW': 140,
      'assistMode': 'Tour',
      'heartRateBpm': 132,
      'cadenceRpm': 70,
      'odometerKm': 3,
      'lightStatus': true,
      'ambientBrightness': 40,
      'systemLock': false,
      'bikeNotDriving': false,
      'chargerConnected': false,
      'timestampMs': 2,
    });
    expect(d.batterySocPercent, 64);
    expect(d.riderPowerW, 140);
    expect(d.assistMode, 'Tour');
    expect(d.heartRateBpm, 132);
  });
}
