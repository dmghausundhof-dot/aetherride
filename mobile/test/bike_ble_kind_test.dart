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
            '0000eb20-eaa2-11e9-81b4-2a2ae2dbcce4',
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

    test('Shimano public component names', () {
      const names = [
        'SC-E6100',
        'SC-E8000',
        'SC-EM800',
        'SC-EN600',
        'DU-E8000',
        'DU-EP800',
        'DU-EP801',
        'DU-EP600',
        'EW-EN100',
        'EW-EN101',
        'SM-BTR1',
        'SM-BTR2',
        'STEPS E',
      ];
      for (final name in names) {
        expect(
          classifyBikeBle(platformName: name, advertisedServiceUuids: const []),
          BikeBleKind.shimano,
          reason: name,
        );
      }
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

  test('identified Bosch is a successful pair without CSC', () {
    expect(
      blePairAccepted(connected: false, kind: BikeBleKind.bosch),
      isTrue,
    );
    expect(
      blePairAccepted(connected: false, kind: BikeBleKind.shimano),
      isTrue,
    );
    expect(
      blePairAccepted(connected: false, kind: BikeBleKind.csc),
      isFalse,
    );
    expect(
      blePairAccepted(connected: true, kind: BikeBleKind.csc),
      isTrue,
    );
    expect(
      blePairDeviceId(lastRemoteId: null, scanDeviceId: 'AA:BB'),
      'AA:BB',
    );
    expect(
      blePairDeviceId(lastRemoteId: 'CC:DD', scanDeviceId: 'AA:BB'),
      'CC:DD',
    );
  });

  test('sheet pops only on GATT; drive identity is opt-in remember', () {
    expect(blePairGattRequired(BikeBleKind.csc), isTrue);
    expect(blePairGattRequired(BikeBleKind.power), isTrue);
    expect(blePairGattRequired(BikeBleKind.bosch), isFalse);
    expect(blePairGattRequired(BikeBleKind.shimano), isFalse);
    expect(blePairSheetSuccess(connected: false), isFalse);
    expect(blePairSheetSuccess(connected: true), isTrue);
    expect(
      blePairAccepted(connected: false, kind: BikeBleKind.bosch),
      isTrue,
    );
  });

  test('ride auto-connect skips preferred GATT on a drive', () {
    expect(
      bleSkipPreferredDriveGatt(
        scanIfMissing: true,
        kindHint: BikeBleKind.bosch,
      ),
      isTrue,
    );
    expect(
      bleSkipPreferredDriveGatt(
        scanIfMissing: false,
        kindHint: BikeBleKind.bosch,
      ),
      isFalse,
    );
    expect(
      bleSkipPreferredDriveGatt(
        scanIfMissing: true,
        kindHint: BikeBleKind.csc,
      ),
      isFalse,
    );
  });

  test('Shimano name without UUID is proprietary drive, not invented SoC', () {
    expect(
      bikeBleCapsFromUuids(const [], platformName: 'SC-EM800'),
      contains(BikeBleCap.proprietaryDrive),
    );
    expect(
      bikeBleCapsFromUuids(const [], platformName: 'Intuvia 100'),
      contains(BikeBleCap.proprietaryDrive),
    );
    expect(
      bikeBleCapsFromUuids(const ['00001816-0000-1000-8000-00805f9b34fb']),
      isNot(contains(BikeBleCap.proprietaryDrive)),
    );
  });

  test('transient GATT 133/147 get honest German hints', () {
    expect(isTransientGattError(133), isTrue);
    expect(isTransientGattError(147), isTrue);
    expect(isTransientGattError(1), isTrue);
    expect(isTransientGattError(8), isFalse);
    expect(isTransientGattError(null), isFalse);
    expect(
      bleGattStatusHint(133),
      contains('Flow'),
    );
    expect(
      bleGattStatusHint(147),
      contains('15s'),
    );
    expect(
      parseGattErrorCode(
        'FlutterBluePlusException | connect | android-code: 133 | GATT',
      ),
      133,
    );
    expect(bleReconnectDelay(0), const Duration(seconds: 5));
    expect(bleReconnectDelay(1), const Duration(seconds: 15));
    expect(bleReconnectDelay(2), const Duration(seconds: 30));
    expect(bleReconnectDelay(9), const Duration(seconds: 30));
  });

  test('untrusted drive drop without OS-bond does not reconnect', () {
    expect(bleIsUntrustedDrop(8), isTrue);
    expect(bleIsUntrustedDrop(5), isTrue);
    expect(bleIsUntrustedDrop(19), isTrue);
    expect(bleIsUntrustedDrop(133), isFalse);
    expect(
      bleShouldReconnectAfterDrop(
        kind: BikeBleKind.bosch,
        disconnectCode: 8,
        bonded: false,
      ),
      isFalse,
    );
    expect(
      bleShouldReconnectAfterDrop(
        kind: BikeBleKind.bosch,
        disconnectCode: 8,
        bonded: true,
      ),
      isTrue,
    );
    expect(
      bleShouldReconnectAfterDrop(
        kind: BikeBleKind.csc,
        disconnectCode: 8,
        bonded: false,
      ),
      isTrue,
    );
    expect(bleGattStatusHint(8), contains('Kopplung'));
  });

  test('connect notes stay short and maker-specific', () {
    expect(bikeBlePairLead(isEbike: true), contains('Display an'));
    expect(bikeBlePairLead(isEbike: false), contains('Sensor'));
    expect(bikeBleConnectTip(BikeBleKind.bosch), contains('Flow'));
    expect(bikeBleConnectTip(BikeBleKind.shimano), contains('15 s'));
    expect(bikeBleConnectTip(BikeBleKind.yamaha), contains('e-Sync'));
    final ebike = bikeBleConnectNotes(isEbike: true);
    expect(ebike.map((n) => n.brand), containsAll(['Bosch', 'Shimano']));
    expect(ebike.every((n) => n.line.length < 120), isTrue);
    expect(bikeBleConnectNotes(isEbike: false).single.brand, 'Sensor');
  });

  test('parseBatteryLevelPercent stays in 0–100', () {
    expect(parseBatteryLevelPercent(const []), isNull);
    expect(parseBatteryLevelPercent(const [64]), 64);
    expect(parseBatteryLevelPercent(const [0]), 0);
    expect(parseBatteryLevelPercent(const [100]), 100);
    expect(parseBatteryLevelPercent(const [101]), isNull);
  });

  test('drive GATT without CSC/power/SoC is not live', () {
    expect(
      bleHasLiveBikeMetrics(
        hasCscNotify: false,
        hasPowerNotify: false,
        hasSoc: false,
      ),
      isFalse,
    );
    expect(
      bleHasLiveBikeMetrics(
        hasCscNotify: true,
        hasPowerNotify: false,
        hasSoc: false,
      ),
      isTrue,
    );
    expect(
      bleDriveWithoutLiveMetrics(
        connected: true,
        kind: BikeBleKind.bosch,
        hasCscNotify: false,
        hasPowerNotify: false,
        hasSoc: false,
      ),
      isTrue,
    );
    expect(
      bleDriveWithoutLiveMetrics(
        connected: true,
        kind: BikeBleKind.csc,
        hasCscNotify: true,
        hasPowerNotify: false,
        hasSoc: false,
      ),
      isFalse,
    );
  });
}
