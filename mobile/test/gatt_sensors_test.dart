import 'package:aetherride_mobile/domain/ble/gatt_sensors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('heart rate uint8', () {
    expect(parseHeartRateBpm([0x00, 72]), 72);
  });

  test('heart rate uint16 little-endian', () {
    expect(parseHeartRateBpm([0x01, 0x2C, 0x01]), 300);
  });

  test('heart rate rejects empty', () {
    expect(parseHeartRateBpm(const []), isNull);
  });

  test('cycling power instantaneous watts', () {
    expect(parseCyclingPowerWatts([0x00, 0x00, 180, 0]), 180);
    expect(parseCyclingPowerWatts([0x00, 0x00]), isNull);
  });

  test('RSC walking speed and step cadence', () {
    // flags=0, speed=2.0 m/s (512 / 256), cadence=80 spm
    final parsed = parseRscMeasurement([0x00, 0x00, 0x02, 80]);
    expect(parsed, isNotNull);
    expect(parsed!.speedMps, 2.0);
    expect(parsed.cadenceSpm, 80);
    expect(parsed.isRunning, isFalse);
    expect(parsed.strideLengthM, isNull);
    expect(parsed.totalDistanceM, isNull);
  });

  test('RSC running flag and stride when present', () {
    // flags=stride+running (0x05), speed=1 m/s (256), cadence=90, stride=1.20 m
    final parsed = parseRscMeasurement([0x05, 0x00, 0x01, 90, 120, 0]);
    expect(parsed, isNotNull);
    expect(parsed!.speedMps, 1.0);
    expect(parsed.cadenceSpm, 90);
    expect(parsed.isRunning, isTrue);
    expect(parsed.strideLengthM, 1.20);
  });

  test('RSC rejects truncated packets', () {
    expect(parseRscMeasurement(const []), isNull);
    expect(parseRscMeasurement([0x00, 0x00, 0x02]), isNull);
    expect(parseRscMeasurement([0x01, 0x00, 0x02, 80]), isNull);
  });
}
