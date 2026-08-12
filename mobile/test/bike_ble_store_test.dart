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
      const BikeBleDevice(deviceId: 'AA:BB', name: 'Magene'),
    );
    final saved = await store.deviceForBike('bike-a');
    expect(saved?.deviceId, 'AA:BB');
    expect(saved?.name, 'Magene');

    await store.removeForBike('bike-a');
    expect(await store.deviceForBike('bike-a'), isNull);
  });
}
