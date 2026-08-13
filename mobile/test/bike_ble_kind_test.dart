import 'package:aetherride_mobile/domain/ble/bike_ble_kind.dart';
import 'package:aetherride_mobile/domain/ble/gatt_sensors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('classifyBikeBle', () {
    test('Bosch Smart System name', () {
      expect(
        classifyBikeBle(
          platformName: 'SMART SYSTEM EBIKE',
          advertisedServiceUuids: const [],
        ),
        BikeBleKind.bosch,
      );
    });

    test('Bosch Kiox / Nyon / Purion names', () {
      expect(
        classifyBikeBle(
          platformName: 'Kiox 300',
          advertisedServiceUuids: const [],
        ),
        BikeBleKind.bosch,
      );
      expect(
        classifyBikeBle(
          platformName: 'Nyon',
          advertisedServiceUuids: const [],
        ),
        BikeBleKind.bosch,
      );
      expect(
        classifyBikeBle(
          platformName: 'Purion 200',
          advertisedServiceUuids: const [],
        ),
        BikeBleKind.bosch,
      );
    });

    test('Bosch LDI / Flow 128-bit UUID without name', () {
      expect(
        classifyBikeBle(
          platformName: '',
          advertisedServiceUuids: const [
            '00000010-eaa2-11e9-81b4-2a2ae2dbcce4',
          ],
        ),
        BikeBleKind.bosch,
      );
    });

    test('Shimano STEPS display names', () {
      expect(
        classifyBikeBle(
          platformName: 'SC-E7000',
          advertisedServiceUuids: const [],
        ),
        BikeBleKind.shimano,
      );
      expect(
        classifyBikeBle(
          platformName: 'Shimano STEPS',
          advertisedServiceUuids: const [],
        ),
        BikeBleKind.shimano,
      );
      expect(
        classifyBikeBle(
          platformName: 'E-TUBE',
          advertisedServiceUuids: const [],
        ),
        BikeBleKind.shimano,
      );
      expect(
        classifyBikeBle(
          platformName: 'EP801',
          advertisedServiceUuids: const [],
        ),
        BikeBleKind.shimano,
      );
    });

    test('CSC advertisement is a wheel sensor, not a watch', () {
      expect(
        classifyBikeBle(
          platformName: 'Magene S3+',
          advertisedServiceUuids: const [
            '00001816-0000-1000-8000-00805f9b34fb',
          ],
        ),
        BikeBleKind.csc,
      );
    });

    test('Cycling Power is a bike candidate even with Garmin in the name', () {
      expect(
        classifyBikeBle(
          platformName: 'Garmin Rally',
          advertisedServiceUuids: const [
            '00001818-0000-1000-8000-00805f9b34fb',
          ],
        ),
        BikeBleKind.power,
      );
    });

    test('watch without CSC is not a bike candidate', () {
      expect(
        classifyBikeBle(
          platformName: 'Polar Vantage M2',
          advertisedServiceUuids: const [
            '0000180d-0000-1000-8000-00805f9b34fb',
          ],
        ),
        isNull,
      );
    });

    test('headphones are noise', () {
      expect(
        classifyBikeBle(
          platformName: 'AirPods Pro',
          advertisedServiceUuids: const [],
        ),
        isNull,
      );
    });

    test('unnamed vendor UUID is not guessed as an e-bike', () {
      expect(
        classifyBikeBle(
          platformName: '',
          advertisedServiceUuids: const [
            '0000fe00-0000-1000-8000-00805f9b34fb',
          ],
        ),
        isNull,
      );
    });
  });

  test('parseBatteryLevelPercent stays in 0–100', () {
    expect(parseBatteryLevelPercent(const []), isNull);
    expect(parseBatteryLevelPercent(const [64]), 64);
    expect(parseBatteryLevelPercent(const [0]), 0);
    expect(parseBatteryLevelPercent(const [100]), 100);
    expect(parseBatteryLevelPercent(const [101]), isNull);
  });
}
