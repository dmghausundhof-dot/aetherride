import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';

import 'package:aetherride_mobile/data/local/app_database.dart';
import 'package:aetherride_mobile/data/local/garage_repository.dart';
import 'package:aetherride_mobile/data/local/setup_repository.dart';
import 'package:aetherride_mobile/data/sync/sync_payload.dart';
import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/post_ride/analyze.dart';
import 'package:aetherride_mobile/domain/privacy/consents.dart';
import 'package:aetherride_mobile/domain/setup.dart';

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
  late SetupRepository setups;

  setUp(() {
    db = createMemoryDatabase();
    garage = GarageRepository(db);
    setups = SetupRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('hours persist after addOdometer', () async {
    final bike = await garage.addBikeBasic(
      name: 'Test',
      category: BikeCategory.mtbTrail,
    );
    await garage.addOdometer(bikeId: bike.id, distanceKm: 12.5, hours: 1.5);
    final again = await garage.getById(bike.id);
    expect(again!.odometerKm, 12.5);
    expect(again.hours, 1.5);
  });

  test('applySuggestion creates current setup version', () async {
    final bike = await garage.addBikeBasic(
      name: 'Trail',
      category: BikeCategory.emtb,
    );
    await setups.createVersion(
      bikeId: bike.id,
      label: 'Basis',
      values: BikeSetup.defaultValues(),
    );
    final applied = await setups.applySuggestion(
      bikeId: bike.id,
      suggestion: const SetupChangeSuggestion(
        title: 'Zugstufe Gabel: 2 Klicks langsamer',
        content: 'test',
        reasoning: 'harsh',
        expectedEffect: 'ruhiger',
        limits: '0-14',
        confidence: 'high',
        adjusterKey: 'fork.rebound',
        suggestedDelta: -2,
      ),
      linkedRideId: 'ride-1',
    );
    expect(applied.isCurrent, isTrue);
    expect(applied.createdBy, 'recommendation');
    expect(applied.valueFor('fork.rebound'), 6);
    expect(applied.linkedRideId, 'ride-1');
    final current = await setups.getCurrent(bike.id);
    expect(current!.id, applied.id);
    expect(current.version, 2);
  });

  test('sync apply setups and consents', () async {
    await garage.applyRemotePayload(
      SyncPayload(
        bikes: [
          {
            'id': 'bike-remote',
            'name': 'Remote Bike',
            'category': 'mtbAm',
            'odometerKm': 100,
            'hours': 9.5,
            'isActive': true,
            'setups': [
              {
                'id': 'setup-1',
                'bikeId': 'bike-remote',
                'label': 'Dry',
                'isCurrent': true,
                'version': 1,
                'createdAt': DateTime.now().toUtc().toIso8601String(),
                'values': [
                  {'adjusterKey': 'fork.rebound', 'valueNum': 7, 'unit': 'clicks'},
                ],
              },
            ],
          },
        ],
        setups: [
          {
            'id': 'setup-top',
            'bikeId': 'bike-remote',
            'label': 'Wet',
            'isCurrent': false,
            'version': 2,
            'createdAt': DateTime.now().toUtc().toIso8601String(),
            'values': [
              {'adjusterKey': 'fork.rebound', 'valueNum': 10, 'unit': 'clicks'},
            ],
          },
        ],
        consents: [
          {
            'purpose': 'product_recommendations',
            'granted': true,
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
            'policyVersion': '1.0',
          },
        ],
        activeBikeId: 'bike-remote',
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      ),
    );

    final bike = await garage.getById('bike-remote');
    expect(bike, isNotNull);
    expect(bike!.hours, 9.5);
    expect(bike.isActive, isTrue);

    final list = await setups.listForBike('bike-remote');
    expect(list.length, 2);
    final current = await setups.getCurrent('bike-remote');
    expect(current!.label, 'Dry');
    expect(current.valueFor('fork.rebound'), 7);

    final consents = await garage.listConsents();
    expect(consents['product_recommendations'], isTrue);
  });

  test('privacy zones persist and sync payload includes them', () async {
    await garage.upsertPrivacyZone(
      const PrivacyZone(
        id: 'pz-1',
        label: 'Zuhause',
        lat: 47.45,
        lng: 12.15,
        radiusM: 200,
      ),
    );
    final zones = await garage.listPrivacyZones();
    expect(zones.length, 1);
    expect(zones.first.label, 'Zuhause');

    final payload = await garage.buildSyncPayload();
    expect(payload.privacyZones, isA<List>());
    expect((payload.privacyZones as List).length, 1);
    expect(payload.savedRoutes, isA<List>());
  });
}
