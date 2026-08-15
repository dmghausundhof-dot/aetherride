import 'dart:io';

import 'package:aetherride_mobile/data/sensor/bike_ble_store.dart';
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

  test('save / load / remove per bike', () async {
    expect(await store.deviceForBike('bike-a'), isNull);

    await store.saveForBike(
      'bike-a',
      const BikeBleDevice(deviceId: 'AA:BB', name: 'Magene', kind: 'csc'),
    );
    final saved = await store.deviceForBike('bike-a');
    expect(saved?.deviceId, 'AA:BB');
    expect(saved?.name, 'Magene');
    expect(saved?.kind, 'csc');

    await store.saveForBike(
      'bike-a',
      const BikeBleDevice(
        deviceId: 'CC:DD',
        name: 'SMART SYSTEM EBIKE',
        kind: 'bosch',
      ),
    );
    expect((await store.deviceForBike('bike-a'))?.kind, 'bosch');

    await store.removeForBike('bike-a');
    expect(await store.deviceForBike('bike-a'), isNull);
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
