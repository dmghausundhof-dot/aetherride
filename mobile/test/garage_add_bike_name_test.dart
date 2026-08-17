import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';

import 'package:aetherride_mobile/data/local/app_database.dart';
import 'package:aetherride_mobile/data/local/garage_repository.dart';
import 'package:aetherride_mobile/domain/bike.dart';

void main() {
  test('resolvedBikeName uses category, never Mein Bike', () {
    expect(fallbackBikeName(BikeCategory.gravel), 'Gravel');
    expect(fallbackBikeName(BikeCategory.urban), 'City');
    expect(fallbackBikeName(BikeCategory.mtbAm), 'MTB');
    expect(fallbackBikeName(BikeCategory.urban, isEbike: true), 'E-City');
    expect(resolvedBikeName('', BikeCategory.gravel), 'Gravel');
    expect(resolvedBikeName('   ', BikeCategory.urban), 'City');
    expect(resolvedBikeName('Luna', BikeCategory.urban), 'Luna');
    expect(resolvedBikeName('Mein Bike', BikeCategory.urban), 'Mein Bike');
    expect(fallbackBikeName(BikeCategory.urban), isNot('Mein Bike'));
    expect(fallbackBikeName(BikeCategory.urban), isNot('Bike'));
  });

  group('addBikeBasic empty name', () {
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

    test('empty name stores category, not Mein Bike', () async {
      final gravel = await garage.addBikeBasic(
        name: '',
        category: BikeCategory.gravel,
      );
      expect(gravel.name, 'Gravel');
      expect(gravel.name, isNot('Mein Bike'));

      final city = await garage.addBikeBasic(
        name: '  ',
        category: BikeCategory.urban,
        makeActive: false,
      );
      expect(city.name, 'City');

      final mtb = await garage.addBikeBasic(
        name: '',
        category: BikeCategory.mtbAm,
        makeActive: false,
      );
      expect(mtb.name, 'MTB');

      final again = await garage.getById(gravel.id);
      expect(again!.name, 'Gravel');
    });

    test('typed name is kept, including legacy Mein Bike', () async {
      final luna = await garage.addBikeBasic(
        name: 'Luna',
        category: BikeCategory.urban,
      );
      expect(luna.name, 'Luna');

      final legacy = await garage.addBikeBasic(
        name: 'Mein Bike',
        category: BikeCategory.gravel,
        makeActive: false,
      );
      expect(legacy.name, 'Mein Bike');

      expect((await garage.getById(luna.id))!.name, 'Luna');
      expect((await garage.getById(legacy.id))!.name, 'Mein Bike');
    });
  });
}
