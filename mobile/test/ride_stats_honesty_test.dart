import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';

import 'package:aetherride_mobile/data/local/app_database.dart';
import 'package:aetherride_mobile/data/local/garage_repository.dart';
import 'package:aetherride_mobile/data/local/ride_repository.dart';
import 'package:aetherride_mobile/domain/ride.dart';

void main() {
  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(
        OperatingSystem.linux,
        () => DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libsqlite3.so.0'),
      );
    }
  });

  group('formatProfileDistanceKm', () {
    test('empty log stays 0', () {
      expect(
        formatProfileDistanceKm(
          rideCount: 0,
          totalKm: 0,
          distanceKnown: true,
        ),
        '0',
      );
    });

    test('unknown distance is dash, not 0', () {
      expect(
        formatProfileDistanceKm(
          rideCount: 1,
          totalKm: 0,
          distanceKnown: false,
        ),
        '—',
      );
    });

    test('sub-kilometer rides say <1', () {
      expect(
        formatProfileDistanceKm(
          rideCount: 1,
          totalKm: 0.4,
          distanceKnown: true,
        ),
        '<1',
      );
    });

    test('known kilometers round', () {
      expect(
        formatProfileDistanceKm(
          rideCount: 2,
          totalKm: 12.4,
          distanceKnown: true,
        ),
        '12',
      );
    });
  });

  test('distanceKmFromTrack estimates haversine length', () {
    final km = distanceKmFromTrack(const [
      {'lat': 49.40, 'lng': 8.67},
      {'lat': 49.41, 'lng': 8.67},
    ]);
    expect(km, closeTo(1.11, 0.05));
  });

  group('RideRepository.statsSummary', () {
    late AppDatabase db;
    late RideRepository rides;

    setUp(() {
      db = createMemoryDatabase();
      rides = RideRepository(db, GarageRepository(db));
    });

    tearDown(() async {
      await db.close();
    });

    test('fills km from track when stored distance is 0', () async {
      await rides.endRide(
        bikeId: 'b1',
        startedAt: DateTime.utc(2026, 8, 1, 10),
        endedAt: DateTime.utc(2026, 8, 1, 11),
        distanceKm: 0,
        movingTimeSec: 3600,
        elevationM: 120,
        track: const [
          TrackPoint(lat: 49.40, lng: 8.67, timeMs: 0),
          TrackPoint(lat: 49.41, lng: 8.67, timeMs: 60000),
        ],
      );
      final stats = await rides.statsSummary();
      expect(stats.rideCount, 1);
      expect(stats.totalKm, greaterThan(1));
      expect(stats.distanceKnown, isTrue);
      expect(stats.totalElevationM, 120);
    });

    test('1 ride without track stays unknown, not 0 km sold as fact', () async {
      await rides.endRide(
        bikeId: 'b1',
        startedAt: DateTime.utc(2026, 8, 1, 10),
        endedAt: DateTime.utc(2026, 8, 1, 10, 20),
        distanceKm: 0,
        movingTimeSec: 1200,
        track: const [],
      );
      final stats = await rides.statsSummary();
      expect(stats.rideCount, 1);
      expect(stats.totalKm, 0);
      expect(stats.distanceKnown, isFalse);
      expect(
        formatProfileDistanceKm(
          rideCount: stats.rideCount,
          totalKm: stats.totalKm,
          distanceKnown: stats.distanceKnown,
        ),
        '—',
      );
    });

    test('unknown bikeId is not persisted and gets no wear', () async {
      await rides.endRide(
        bikeId: 'unknown',
        startedAt: DateTime.utc(2026, 8, 1, 10),
        endedAt: DateTime.utc(2026, 8, 1, 11),
        distanceKm: 12,
        movingTimeSec: 3600,
      );
      final list = await rides.listRides();
      expect(list, hasLength(1));
      expect(list.first.bikeId, isEmpty);
      expect(list.first.summary['unassigned'], isTrue);
    });
  });
}
