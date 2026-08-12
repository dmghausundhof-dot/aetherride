import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';

import 'package:aetherride_mobile/data/local/app_database.dart';
import 'package:aetherride_mobile/data/local/garage_repository.dart';
import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/bike_assist.dart';

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

  test('E-City / E-Gravel / E-Road survive reload via isEbike', () async {
    for (final entry in [
      (BikeCategory.urban, 'E-City'),
      (BikeCategory.gravel, 'E-Gravel'),
      (BikeCategory.road, 'E-Road'),
    ]) {
      final cat = entry.$1;
      final label = entry.$2;
      final persisted = BikeAssistUx.persistCategory(cat, BikeAssistMode.ebike);
      final bike = await garage.addBikeBasic(
        name: label,
        category: persisted,
        isEbike: BikeAssistUx.persistIsEbike(cat, BikeAssistMode.ebike),
        makeActive: true,
      );
      expect(bike.category, cat);
      expect(bike.isEbike, isTrue);
      expect(bike.categoryLabel, label);

      final again = await garage.getById(bike.id);
      expect(again, isNotNull);
      expect(again!.category, cat);
      expect(again.isEbike, isTrue);
      expect(again.hasElectricAssist, isTrue);
      expect(again.categoryLabel, label);
      expect(
        BikeAssistUx.modeFor(
          category: again.category,
          isEbike: again.isEbike,
        ),
        BikeAssistMode.ebike,
      );

      await garage.deleteBike(bike.id);
    }
  });

  test('E-MTB and E-Trekking still persist', () async {
    final emtb = await garage.addBikeBasic(
      name: 'E-MTB',
      category: BikeCategory.emtb,
      isEbike: true,
    );
    final et = await garage.addBikeBasic(
      name: 'E-Trekking',
      category: BikeCategory.etrekking,
      isEbike: true,
      makeActive: false,
    );
    expect((await garage.getById(emtb.id))!.category, BikeCategory.emtb);
    expect((await garage.getById(emtb.id))!.isEbike, isTrue);
    expect((await garage.getById(et.id))!.category, BikeCategory.etrekking);
    expect((await garage.getById(et.id))!.isEbike, isTrue);
  });

  test('muscle City stays without isEbike', () async {
    final bike = await garage.addBikeBasic(
      name: 'City',
      category: BikeCategory.urban,
      isEbike: false,
    );
    final again = await garage.getById(bike.id);
    expect(again!.category, BikeCategory.urban);
    expect(again.isEbike, isFalse);
    expect(again.categoryLabel, 'City');
  });
}
