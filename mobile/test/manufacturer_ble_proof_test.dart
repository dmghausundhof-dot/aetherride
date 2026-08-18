import 'dart:io';

import 'package:aetherride_mobile/data/sensor/bike_ble_store.dart';
import 'package:aetherride_mobile/domain/ble/bike_ble_kind.dart';
import 'package:aetherride_mobile/domain/ble/bosch_ldi_proto.dart';
import 'package:aetherride_mobile/domain/ble/csc_measurement.dart';
import 'package:aetherride_mobile/domain/ble/gatt_sensors.dart';
import 'package:aetherride_mobile/domain/ble/manufacturer_ble.dart';
import 'package:aetherride_mobile/domain/ble/watch_candidate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every profile has a unique proof id and never invents values', () {
    final ids = kManufacturerBleProfiles.map((p) => p.proofId).toSet();
    expect(ids.length, kManufacturerBleProfiles.length);
    for (final p in kManufacturerBleProfiles) {
      expect(p.inventsValues, isFalse);
      expect(p.connectMeaning, isNotEmpty);
      expect(p.forgetMeaning, isNotEmpty);
    }
  });

  test('Bosch LDI is the only open drive decoder — Android and iOS accessory', () {
    final ldi = manufacturerBleByProofId('bosch-ldi-v1')!;
    expect(ldi.openness, ManufacturerBleOpenness.openPartial);
    expect(ldi.androidLive, isTrue);
    expect(ldi.iosLive, isTrue);
    expect(ldi.metrics, contains(ManufacturerBleMetric.batterySoc));
    expect(ldi.decodesLive, isTrue);

    final display = manufacturerBleByProofId('bosch-display-identity')!;
    expect(display.openness, ManufacturerBleOpenness.identityOnly);
    expect(display.decodesLive, isFalse);
  });

  test('Shimano / Yamaha / ESM-drive remain identity-only', () {
    for (final id in [
      'shimano-identity-only',
      'yamaha-identity-only',
      'fazua-identity',
      'tq-identity',
      'brose-identity',
      'specialized-identity',
      'giant-identity',
      'mahle-identity',
      'bafang-identity',
    ]) {
      final p = manufacturerBleByProofId(id)!;
      expect(p.openness, ManufacturerBleOpenness.identityOnly);
      expect(p.metrics, isEmpty);
      expect(p.androidLive, isFalse);
      expect(manufacturerBleForbidsInventedDriveMetrics(p.kind), isTrue);
    }
  });

  test('ESM uses SIG parsers, not a proprietary motor frame', () {
    final esm = manufacturerBleByProofId('esm-open-sig')!;
    expect(esm.openness, ManufacturerBleOpenness.openDecodable);
    expect(esm.protocol, contains('0x1816'));
    expect(esm.kind, isNull);
    expect(
      classifyBikeBle(
        platformName: 'ESM',
        advertisedServiceUuids: const [],
      ),
      BikeBleKind.otherDrive,
    );
    expect(
      classifyBikeBle(
        platformName: 'ESM Pulse',
        advertisedServiceUuids: const ['00001816-0000-1000-8000-00805f9b34fb'],
      ),
      BikeBleKind.otherDrive,
    );
  });

  test('open SIG proofs: CSC speed from wheel, never cadence-as-speed', () {
    final csc = manufacturerBleByProofId('sig-csc')!;
    expect(csc.decodesLive, isTrue);

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
    expect(second.speedKmh, closeTo(7.56, 0.01));
    expect(second.cadenceRpm, closeTo(60, 0.01));

    final crankOnly = parseCscMeasurement(
      [0x02, 11, 0, 0, 4],
      wheelCircumferenceM: 2.1,
      prevCrankRevs: 10,
      prevCrankEventTime: 0,
    );
    expect(crankOnly.speedKmh, 0);
  });

  test('open SIG proofs: power, HR, battery parsers reject garbage', () {
    expect(parseCyclingPowerWatts([0x00, 0x00, 0x8c, 0x00]), 140);
    expect(parseCyclingPowerWatts([0x00]), isNull);
    expect(parseHeartRateBpm([0x00, 72]), 72);
    expect(parseHeartRateBpm([]), isNull);
    expect(parseBatteryLevelPercent([64]), 64);
    expect(parseBatteryLevelPercent([200]), isNull);
  });

  test('Bosch LDI protobuf proof: sparse frame does not invent SoC', () {
    final full = decodeBoschLdiFrame(
      encodeBoschLdiTestFrame(
        speedHundredths: 2540,
        cadenceRpm: 78,
        riderPowerW: 140,
        batterySoc: 64,
        odometerM: 12470,
      ),
    );
    expect(full.hasLiveMetrics, isTrue);
    expect(full.batterySocPercent, 64);

    final sparse = decodeBoschLdiFrame(
      encodeBoschLdiTestFrame(speedHundredths: 1800),
    );
    expect(sparse.speedKmh, closeTo(18, 0.001));
    expect(sparse.batterySocPercent, isNull);
    expect(sparse.riderPowerW, isNull);
  });

  test('watch honesty: Polar pairable, Apple blocked', () {
    expect(watchHonestyForName('Polar H10'), WatchHonesty.hrBroadcast);
    expect(watchHonestyPairable(WatchHonesty.hrBroadcast), isTrue);
    expect(watchHonestyForName('Apple Watch'), WatchHonesty.appleUnsupported);
    expect(watchHonestyPairable(WatchHonesty.appleUnsupported), isFalse);
  });

  test('clearAll deletes every manufacturer pairing file', () async {
    final tmp = await Directory.systemTemp.createTemp('mfg_ble_');
    addTearDown(() async {
      if (await tmp.exists()) await tmp.delete(recursive: true);
    });
    final store = BikeBleStore(dirProvider: () async => tmp);
    await store.saveForBike(
      'bike-a',
      const BikeBleDevice(deviceId: 'W1', kind: 'csc'),
    );
    await store.saveWatch(
      const BikeBleDevice(deviceId: 'HR1', name: 'Polar'),
    );
    await File('${tmp.path}/$kBleLastCscIdFile').writeAsString('W1');
    await File('${tmp.path}/$kBleLastWatchIdFile').writeAsString('HR1');

    await store.clearAll();

    expect((await store.bindingForBike('bike-a')).isEmpty, isTrue);
    expect(await store.savedWatch(), isNull);
    for (final name in kManufacturerBleLocalFiles) {
      expect(File('${tmp.path}/$name').existsSync(), isFalse, reason: name);
    }
  });

  test('Mahle / Mission Control classify as other drive, not CSC', () {
    expect(
      classifyBikeBle(
        platformName: 'Mahle X20',
        advertisedServiceUuids: const [],
      ),
      BikeBleKind.otherDrive,
    );
    expect(
      classifyBikeBle(
        platformName: 'Mission Control',
        advertisedServiceUuids: const [],
      ),
      BikeBleKind.otherDrive,
    );
  });
}
