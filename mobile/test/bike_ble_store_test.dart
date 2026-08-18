import 'dart:convert';
import 'dart:io';

import 'package:aetherride_mobile/data/sensor/bike_ble_store.dart';
import 'package:aetherride_mobile/domain/ble.dart';
import 'package:aetherride_mobile/domain/ble/bike_ble_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tmp;
  late BikeBleStore store;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('bike_ble_');
    store = BikeBleStore(dirProvider: () async => tmp);
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('wheel and drive occupy separate slots', () async {
    expect((await store.bindingForBike('bike-a')).isEmpty, isTrue);

    await store.saveForBike(
      'bike-a',
      const BikeBleDevice(deviceId: 'AA:BB', name: 'Magene', kind: 'csc'),
    );
    await store.saveForBike(
      'bike-a',
      const BikeBleDevice(
        deviceId: 'CC:DD',
        name: 'SMART SYSTEM EBIKE',
        kind: 'bosch',
      ),
    );

    final b = await store.bindingForBike('bike-a');
    expect(b.wheel?.deviceId, 'AA:BB');
    expect(b.drive?.deviceId, 'CC:DD');
    expect((await store.deviceForBike('bike-a'))?.deviceId, 'AA:BB');

    await store.removeWheel('bike-a');
    expect((await store.bindingForBike('bike-a')).wheel, isNull);
    expect((await store.bindingForBike('bike-a')).drive?.kind, 'bosch');

    await store.removeForBike('bike-a');
    expect((await store.bindingForBike('bike-a')).isEmpty, isTrue);
  });

  test('legacy flat JSON migrates drive vs wheel', () async {
    final f = File('${tmp.path}/bike_ble_devices.json');
    await f.writeAsString(
      jsonEncode({
        'legacy-csc': {'deviceId': 'W1', 'name': 'Magene', 'kind': 'csc'},
        'legacy-bosch': {
          'deviceId': 'D1',
          'name': 'Intuvia',
          'kind': 'bosch',
        },
      }),
    );
    final migrated = BikeBleStore(dirProvider: () async => tmp);
    expect((await migrated.bindingForBike('legacy-csc')).wheel?.deviceId, 'W1');
    expect((await migrated.bindingForBike('legacy-csc')).drive, isNull);
    expect(
      (await migrated.bindingForBike('legacy-bosch')).drive?.deviceId,
      'D1',
    );
    expect((await migrated.bindingForBike('legacy-bosch')).wheel, isNull);
  });

  test('ride preferred target is wheel only', () {
    const both = BikeBleBinding(
      wheel: BikeBleDevice(deviceId: 'W', kind: 'csc'),
      drive: BikeBleDevice(deviceId: 'D', kind: 'bosch'),
    );
    expect(rideBlePreferredTarget(both).deviceId, 'W');
    expect(rideBlePreferredTarget(both).kindHint, BikeBleKind.csc);

    const driveOnly = BikeBleBinding(
      drive: BikeBleDevice(deviceId: 'D', kind: 'bosch'),
    );
    expect(rideBlePreferredTarget(driveOnly).deviceId, isNull);
  });

  test('garage wake reconnects CSC and offers Bosch LDI', () {
    const both = BikeBleBinding(
      wheel: BikeBleDevice(deviceId: 'W', kind: 'csc'),
      drive: BikeBleDevice(deviceId: boschLdiAccessoryId, kind: 'bosch'),
    );
    final bothPlan = garageBleWakePlan(both);
    expect(bothPlan.wheelId, 'W');
    expect(bothPlan.wheelKind, BikeBleKind.csc);
    expect(bothPlan.startLdi, isTrue);

    const cscOnly = BikeBleBinding(
      wheel: BikeBleDevice(deviceId: 'W', kind: 'csc'),
    );
    expect(garageBleWakePlan(cscOnly).startLdi, isFalse);
    expect(garageBleWakePlan(cscOnly).wheelId, 'W');

    const driveOnly = BikeBleBinding(
      drive: BikeBleDevice(deviceId: boschLdiAccessoryId, kind: 'bosch'),
    );
    expect(garageBleWakePlan(driveOnly).wheelId, isNull);
    expect(garageBleWakePlan(driveOnly).startLdi, isTrue);

    const shimano = BikeBleBinding(
      drive: BikeBleDevice(deviceId: 'SH-1', kind: 'shimano'),
    );
    expect(garageBleWakePlan(shimano).startLdi, isFalse);
    expect(garageBleWakePlan(shimano).attachDrive, isTrue);
  });

  test('ride plan awaits Bosch LDI when no wheel sensor', () {
    const driveOnly = BikeBleBinding(
      drive: BikeBleDevice(deviceId: boschLdiAccessoryId, kind: 'bosch'),
    );
    final p = rideBleConnectPlan(driveOnly);
    expect(p.wheelId, isNull);
    expect(p.startLdi, isTrue);
    expect(p.attachDrive, isTrue);
    expect(p.awaitDriveForSpeed, isTrue);

    const both = BikeBleBinding(
      wheel: BikeBleDevice(deviceId: 'W', kind: 'csc'),
      drive: BikeBleDevice(deviceId: boschLdiAccessoryId, kind: 'bosch'),
    );
    final bothPlan = rideBleConnectPlan(both);
    expect(bothPlan.wheelId, 'W');
    expect(bothPlan.awaitDriveForSpeed, isFalse);
    expect(bothPlan.attachDrive, isTrue);
  });

  test('watch is rider kit, not stored on the bike', () async {
    await store.saveForBike(
      'bike-a',
      const BikeBleDevice(deviceId: 'CSC-1', name: 'Magene'),
    );
    await store.saveWatch(
      const BikeBleDevice(deviceId: 'WATCH-1', name: 'Polar Vantage'),
    );

    expect((await store.deviceForBike('bike-a'))?.deviceId, 'CSC-1');
    expect((await store.savedWatch())?.deviceId, 'WATCH-1');
    expect((await store.savedWatch())?.name, 'Polar Vantage');

    await store.removeWatch();
    expect(await store.savedWatch(), isNull);
    expect((await store.deviceForBike('bike-a'))?.deviceId, 'CSC-1');
  });
}
