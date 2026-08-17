import 'package:aetherride_mobile/domain/ble/bosch_ldi_proto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes speed, cadence, SoC and odometer from Bosch LiveData', () {
    final bytes = encodeBoschLdiTestFrame(
      speedHundredths: 2540,
      cadenceRpm: 78,
      riderPowerW: 140,
      batterySoc: 64,
      odometerM: 12470,
    );
    final f = decodeBoschLdiFrame(bytes);
    expect(f.speedKmh, closeTo(25.4, 0.001));
    expect(f.cadenceRpm, 78);
    expect(f.riderPowerW, 140);
    expect(f.batterySocPercent, 64);
    expect(f.odometerKm, closeTo(12.47, 0.001));
    expect(f.hasLiveMetrics, isTrue);
  });

  test('sparse frame does not invent SoC', () {
    final bytes = encodeBoschLdiTestFrame(speedHundredths: 1800);
    final f = decodeBoschLdiFrame(bytes);
    expect(f.speedKmh, closeTo(18, 0.001));
    expect(f.batterySocPercent, isNull);
    expect(f.riderPowerW, isNull);
  });

  test('empty payload is empty frame', () {
    final f = decodeBoschLdiFrame(const []);
    expect(f.hasLiveMetrics, isFalse);
    expect(f.batterySocPercent, isNull);
  });
}
