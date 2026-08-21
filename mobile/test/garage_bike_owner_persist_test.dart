import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';

import 'package:aetherride_mobile/data/local/app_database.dart';
import 'package:aetherride_mobile/data/local/garage_repository.dart';
import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/bike_owner.dart';

void main() {
  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(
        OperatingSystem.linux,
        () => DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libsqlite3.so.0'),
      );
    }
  });

  late AppDatabase db;
  late GarageRepository garage;

  setUp(() {
    db = createMemoryDatabase();
    garage = GarageRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('Rahmennummer and owner card survive reload', () async {
    final bike = await garage.addBikeBasic(
      name: 'Gravel',
      category: BikeCategory.gravel,
      owner: BikeOwner.normalize(
        serialNumber: 'WS-1847',
        color: 'Salbei',
        weightKg: 9.4,
        purchasedAt: '2024-06-01',
        insuranceName: 'ADAC',
        keyNumber: '2241',
      ),
    );
    final again = await garage.getById(bike.id);
    expect(again, isNotNull);
    expect(again!.owner.serialNumber, 'WS-1847');
    expect(again.owner.color, 'Salbei');
    expect(again.owner.weightKg, 9.4);
    expect(again.owner.purchasedAt, '2024-06-01');
    expect(again.owner.insuranceName, 'ADAC');
    expect(again.owner.keyNumber, '2241');
  });

  test('sync payload flattens owner fields for web', () async {
    final bike = await garage.addBikeBasic(
      name: 'City',
      category: BikeCategory.urban,
      owner: const BikeOwner(serialNumber: 'C-9', notes: 'Licht neu'),
    );
    final payload = await garage.buildSyncPayload();
    final rows = payload.bikes as List;
    final map = Map<String, dynamic>.from(
      rows.cast<Map>().firstWhere((e) => e['id'] == bike.id),
    );
    expect(map['serialNumber'], 'C-9');
    expect(map['notes'], 'Licht neu');
  });
}
