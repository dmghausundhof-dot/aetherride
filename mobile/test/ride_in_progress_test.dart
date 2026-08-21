import 'dart:convert';
import 'dart:io';

import 'package:aetherride_mobile/data/local/app_database.dart';
import 'package:aetherride_mobile/data/local/garage_repository.dart';
import 'package:aetherride_mobile/data/local/ride_in_progress_store.dart';
import 'package:aetherride_mobile/data/local/ride_repository.dart';
import 'package:aetherride_mobile/domain/ride.dart';
import 'package:aetherride_mobile/domain/ride/ride_in_progress.dart';
import 'package:aetherride_mobile/domain/ride_journal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';
import 'dart:ffi';

void main() {
  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(
        OperatingSystem.linux,
        () => DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libsqlite3.so.0'),
      );
    }
  });

  group('TrackPoint.tryParse', () {
    test('roundtrips compact toJson keys', () {
      const p = TrackPoint(
        lat: 49.41,
        lng: 8.69,
        timeMs: 1700000000000,
        elev: 112,
        heartRateBpm: 142,
        cadenceRpm: 78,
        powerW: 210,
        leanDeg: 12.34,
        gPeak: 1.23,
        impact: true,
        speedKmh: 24.6,
      );
      final parsed = TrackPoint.tryParse(p.toJson());
      expect(parsed, isNotNull);
      expect(parsed!.lat, closeTo(49.41, 1e-9));
      expect(parsed.lng, closeTo(8.69, 1e-9));
      expect(parsed.timeMs, 1700000000000);
      expect(parsed.elev, 112);
      expect(parsed.heartRateBpm, 142);
      expect(parsed.cadenceRpm, 78);
      expect(parsed.powerW, 210);
      expect(parsed.leanDeg, closeTo(12.3, 0.05));
      expect(parsed.gPeak, closeTo(1.23, 0.005));
      expect(parsed.impact, isTrue);
      expect(parsed.speedKmh, closeTo(24.6, 0.05));
    });

    test('rejects junk coordinates', () {
      expect(TrackPoint.tryParse({'lat': 99, 'lng': 8}), isNull);
      expect(TrackPoint.tryParse({'lat': 49, 'lng': 200}), isNull);
      expect(TrackPoint.tryParse({'latitude': 49.4}), isNull);
      expect(TrackPoint.tryParse('nope'), isNull);
    });
  });

  group('RideInProgressDraft', () {
    final started = DateTime.utc(2026, 8, 21, 10);
    final saved = DateTime.utc(2026, 8, 21, 11);
    final draft = RideInProgressDraft(
      rideId: 'ride-1',
      startedAt: started,
      savedAt: saved,
      distanceM: 3210,
      elapsedSec: 3600,
      usingGps: true,
      drawingTour: true,
      paused: true,
      peakG: 2.1,
      flowSum: 12,
      flowN: 4,
      routeId: 'route-9',
      routeName: 'Neckar-Schleife',
      journal: RideJournal(photoPaths: const ['/tmp/a.jpg']),
      track: const [
        TrackPoint(lat: 49.40, lng: 8.67, timeMs: 1, elev: 100),
        TrackPoint(lat: 49.41, lng: 8.67, timeMs: 20000, elev: 108),
      ],
    );

    test('JSON roundtrip keeps track and journal', () {
      final parsed = RideInProgressDraft.fromJson(draft.toJson());
      expect(parsed, isNotNull);
      expect(parsed!.rideId, 'ride-1');
      expect(parsed.distanceM, 3210);
      expect(parsed.elapsedSec, 3600);
      expect(parsed.usingGps, isTrue);
      expect(parsed.drawingTour, isTrue);
      expect(parsed.paused, isTrue);
      expect(parsed.routeId, 'route-9');
      expect(parsed.routeName, 'Neckar-Schleife');
      expect(parsed.track, hasLength(2));
      expect(parsed.track.last.lat, closeTo(49.41, 1e-9));
      expect(parsed.journal.photoPaths, ['/tmp/a.jpg']);
      expect(parsed.startedAt.millisecondsSinceEpoch, started.millisecondsSinceEpoch);
      expect(parsed.savedAt.millisecondsSinceEpoch, saved.millisecondsSinceEpoch);
    });

    test('fromJson ignores corrupt payload', () {
      expect(RideInProgressDraft.fromJson(null), isNull);
      expect(RideInProgressDraft.fromJson({}), isNull);
      expect(RideInProgressDraft.fromJson({'rideId': ''}), isNull);
      expect(
        RideInProgressDraft.fromJson({'rideId': 'x', 'track': 'bad'}),
        isNull,
      );
    });

    test('fromJson drops invalid points and keeps valid ones', () {
      final parsed = RideInProgressDraft.fromJson({
        'rideId': 'r',
        'startedAtMs': started.millisecondsSinceEpoch,
        'savedAtMs': saved.millisecondsSinceEpoch,
        'track': [
          {'lat': 49.4, 'lng': 8.67, 'time': 1},
          {'lat': 99, 'lng': 0},
          'x',
        ],
      });
      expect(parsed!.track, hasLength(1));
    });
  });

  group('rideInProgressIsRecoverable', () {
    final now = DateTime.utc(2026, 8, 21, 16);

    RideInProgressDraft base({
      List<TrackPoint> track = const [],
      int elapsedSec = 0,
      DateTime? savedAt,
    }) {
      return RideInProgressDraft(
        rideId: 'ride-1',
        startedAt: DateTime.utc(2026, 8, 21, 10),
        savedAt: savedAt ?? DateTime.utc(2026, 8, 21, 15),
        track: track,
        elapsedSec: elapsedSec,
      );
    }

    test('track with points is always recoverable', () {
      expect(
        rideInProgressIsRecoverable(
          base(
            track: const [TrackPoint(lat: 49.4, lng: 8.67, timeMs: 1)],
          ),
          now: now,
        ),
        isTrue,
      );
    });

    test('empty short draft is discarded', () {
      expect(rideInProgressIsRecoverable(base(), now: now), isFalse);
      expect(
        rideInProgressIsRecoverable(base(elapsedSec: 4), now: now),
        isFalse,
      );
    });

    test('empty but elapsed draft recovers within 48h', () {
      expect(
        rideInProgressIsRecoverable(base(elapsedSec: 90), now: now),
        isTrue,
      );
      expect(
        rideInProgressIsRecoverable(
          base(
            elapsedSec: 90,
            savedAt: DateTime.utc(2026, 8, 19, 10),
          ),
          now: now,
        ),
        isFalse,
      );
    });

    test('null is not recoverable', () {
      expect(rideInProgressIsRecoverable(null), isFalse);
    });
  });

  group('rideInProgressShouldCheckpoint', () {
    final t0 = DateTime.utc(2026, 8, 21, 10);

    test('writes immediately when nothing is on disk yet', () {
      expect(
        rideInProgressShouldCheckpoint(
          lastAt: null,
          lastLen: 0,
          trackLen: 0,
          now: t0,
        ),
        isTrue,
      );
    });

    test('throttles until interval or new points', () {
      expect(
        rideInProgressShouldCheckpoint(
          lastAt: t0,
          lastLen: 4,
          trackLen: 6,
          now: t0.add(const Duration(seconds: 3)),
        ),
        isFalse,
      );
      expect(
        rideInProgressShouldCheckpoint(
          lastAt: t0,
          lastLen: 4,
          trackLen: 13,
          now: t0.add(const Duration(seconds: 1)),
        ),
        isTrue,
      );
      expect(
        rideInProgressShouldCheckpoint(
          lastAt: t0,
          lastLen: 4,
          trackLen: 5,
          now: t0.add(const Duration(seconds: 8)),
        ),
        isTrue,
      );
    });

    test('force writes a started ride even without points', () {
      expect(
        rideInProgressShouldCheckpoint(
          lastAt: null,
          lastLen: 0,
          trackLen: 0,
          now: t0,
          force: true,
        ),
        isTrue,
      );
    });
  });

  group('RideInProgressStore', () {
    late Directory dir;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('ride_in_progress_');
      RideInProgressStore.debugDirectory = dir;
    });

    tearDown(() {
      RideInProgressStore.debugDirectory = null;
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    test('write / kill / read restores the track', () async {
      final draft = RideInProgressDraft(
        rideId: 'killed-1',
        startedAt: DateTime.utc(2026, 8, 21, 10),
        savedAt: DateTime.utc(2026, 8, 21, 10, 20),
        distanceM: 1800,
        elapsedSec: 1200,
        usingGps: true,
        track: const [
          TrackPoint(lat: 49.40, lng: 8.67, timeMs: 1),
          TrackPoint(lat: 49.41, lng: 8.67, timeMs: 60000),
        ],
      );
      await RideInProgressStore.write(draft);

      // Process-kill equivalent: new read from the same file, no in-memory copy.
      final restored = await RideInProgressStore.read();
      expect(rideInProgressIsRecoverable(restored), isTrue);
      expect(restored!.rideId, 'killed-1');
      expect(restored.track, hasLength(2));
      expect(restored.distanceM, 1800);
      expect(
        File('${dir.path}/${RideInProgressStore.fileName}').existsSync(),
        isTrue,
      );
    });

    test('sync flush after async write survives another read', () async {
      final first = RideInProgressDraft(
        rideId: 'sync-1',
        startedAt: DateTime.utc(2026, 8, 21, 10),
        savedAt: DateTime.utc(2026, 8, 21, 10, 1),
        track: const [TrackPoint(lat: 49.40, lng: 8.67, timeMs: 1)],
      );
      await RideInProgressStore.write(first);
      RideInProgressStore.writeSync(
        RideInProgressDraft(
          rideId: 'sync-1',
          startedAt: first.startedAt,
          savedAt: DateTime.utc(2026, 8, 21, 10, 2),
          distanceM: 40,
          track: const [
            TrackPoint(lat: 49.40, lng: 8.67, timeMs: 1),
            TrackPoint(lat: 49.4003, lng: 8.67, timeMs: 4000),
          ],
        ),
      );
      final restored = await RideInProgressStore.read();
      expect(restored!.track, hasLength(2));
      expect(restored.distanceM, 40);
    });

    test('clear removes the draft', () async {
      await RideInProgressStore.write(
        RideInProgressDraft(
          rideId: 'gone',
          startedAt: DateTime.utc(2026, 8, 21, 10),
          savedAt: DateTime.utc(2026, 8, 21, 10),
          track: const [TrackPoint(lat: 49.4, lng: 8.67, timeMs: 1)],
        ),
      );
      await RideInProgressStore.clear();
      expect(await RideInProgressStore.read(), isNull);
    });

    test('corrupt file reads as null', () async {
      await File('${dir.path}/${RideInProgressStore.fileName}')
          .writeAsString('{not-json');
      expect(await RideInProgressStore.read(), isNull);
    });
  });

  group('recovered track can finish via endRide', () {
    late AppDatabase db;
    late RideRepository rides;

    setUp(() {
      db = createMemoryDatabase();
      rides = RideRepository(db, GarageRepository(db));
    });

    tearDown(() async {
      await db.close();
    });

    test('persist + restore + endRide keeps the same id and track', () async {
      final raw = jsonEncode(
        RideInProgressDraft(
          rideId: 'recover-save',
          startedAt: DateTime.utc(2026, 8, 21, 10),
          savedAt: DateTime.utc(2026, 8, 21, 11),
          distanceM: 2500,
          elapsedSec: 2400,
          usingGps: true,
          routeName: 'Neckar-Schleife',
          track: const [
            TrackPoint(lat: 49.40, lng: 8.67, timeMs: 1),
            TrackPoint(lat: 49.41, lng: 8.67, timeMs: 60000),
          ],
        ).toJson(),
      );
      final draft = RideInProgressDraft.fromJson(jsonDecode(raw));
      expect(rideInProgressIsRecoverable(draft), isTrue);

      final record = await rides.endRide(
        id: draft!.rideId,
        bikeId: 'b1',
        startedAt: draft.startedAt,
        endedAt: DateTime.utc(2026, 8, 21, 11, 5),
        distanceKm: draft.distanceM / 1000,
        movingTimeSec: draft.elapsedSec,
        name: draft.routeName ?? 'Freeride',
        track: draft.track,
      );
      expect(record.id, 'recover-save');
      expect(record.name, 'Neckar-Schleife');
      expect(record.endedAt, isNotNull);
      expect(record.track, hasLength(2));
      expect(record.distanceKm, closeTo(2.5, 0.01));
      expect(record.isActive, isFalse);
    });
  });
}
