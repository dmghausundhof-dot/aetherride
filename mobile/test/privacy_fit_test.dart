import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';

import 'package:aetherride_mobile/data/export/fit.dart';
import 'package:aetherride_mobile/domain/privacy/consents.dart';
import 'package:aetherride_mobile/domain/privacy/track_trim.dart';
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

  test('trimTrackForPrivacyZones drops points inside zone', () {
    const zone = PrivacyZone(
      id: 'z1',
      label: 'Home',
      lat: 47.45,
      lng: 12.15,
      radiusM: 500,
    );
    final track = [
      {'lat': 47.45, 'lng': 12.15}, // in zone
      {'lat': 47.46, 'lng': 12.16},
      {'lat': 47.47, 'lng': 12.17},
      {'lat': 47.48, 'lng': 12.18},
      {'lat': 47.49, 'lng': 12.19},
      {'lat': 47.50, 'lng': 12.20},
    ];
    // trimEndsM=0 to focus on zone filter
    final out = trimTrackForPrivacyZones(track, [zone], trimEndsM: 0);
    expect(out.every((p) {
      final lat = (p['lat'] as num).toDouble();
      final lng = (p['lng'] as num).toDouble();
      final dLat = (lat - 47.45) * 111000;
      final dLng = (lng - 12.15) * 111000 * 0.7;
      return (dLat * dLat + dLng * dLng) >= 500 * 500;
    }), isTrue);
    expect(out.length, lessThan(track.length));
  });

  test('rideToFit produces non-empty FIT with CRC trailer', () {
    final ride = RideRecord(
      id: 'r1',
      bikeId: 'b1',
      startedAt: DateTime.utc(2026, 1, 1, 10),
      endedAt: DateTime.utc(2026, 1, 1, 11),
      distanceKm: 12,
      movingTimeSec: 3600,
      elevationM: 400,
      track: [
        for (var i = 0; i < 20; i++)
          {'lat': 47.4 + i * 0.001, 'lng': 12.1 + i * 0.001, 'elev': 800 + i, 'time': i * 30},
      ],
    );
    final bytes = rideToFit(ride);
    expect(bytes.length, greaterThan(20));
    expect(String.fromCharCodes(bytes.sublist(8, 12)), '.FIT');
  });

  test('rideToFit skips Null Island and missing lat/lng', () {
    final ride = RideRecord(
      id: 'r2',
      bikeId: 'b1',
      startedAt: DateTime.utc(2026, 1, 1, 10),
      endedAt: DateTime.utc(2026, 1, 1, 11),
      distanceKm: 1,
      movingTimeSec: 600,
      elevationM: 10,
      track: [
        {'lat': 0, 'lng': 0, 'time': 0},
        {'lat': 47.5, 'lng': 12.2, 'elev': 800, 'time': 30},
        {'lng': 12.3, 'time': 60}, // missing lat
        {'lat': 47.51, 'lng': 12.21, 'elev': 801, 'time': 90},
      ],
    );
    final withJunk = rideToFit(ride);
    final clean = rideToFit(
      RideRecord(
        id: 'r2c',
        bikeId: 'b1',
        startedAt: ride.startedAt,
        endedAt: ride.endedAt,
        distanceKm: 1,
        movingTimeSec: 600,
        elevationM: 10,
        track: [
          {'lat': 47.5, 'lng': 12.2, 'elev': 800, 'time': 30},
          {'lat': 47.51, 'lng': 12.21, 'elev': 801, 'time': 90},
        ],
      ),
    );
    // Same number of record messages → same length as clean track.
    expect(withJunk.length, clean.length);
    expect(String.fromCharCodes(withJunk.sublist(8, 12)), '.FIT');
  });
}
