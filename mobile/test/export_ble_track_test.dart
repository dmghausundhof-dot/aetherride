import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/data/export/fit.dart';
import 'package:aetherride_mobile/data/export/gpx.dart';
import 'package:aetherride_mobile/domain/ride.dart';

RideRecord _ride(List<Map<String, dynamic>> track) {
  return RideRecord(
    id: 'r-ble',
    bikeId: 'b1',
    startedAt: DateTime.utc(2026, 8, 16, 10),
    endedAt: DateTime.utc(2026, 8, 16, 11),
    distanceKm: 12,
    movingTimeSec: 3600,
    elevationM: 200,
    track: track,
  );
}

void main() {
  test('TrackPoint JSON omits missing HR/cadence/power', () {
    const bare = TrackPoint(lat: 48.1, lng: 8.2, timeMs: 1000, elev: 400);
    expect(bare.toJson().containsKey('hr'), isFalse);
    expect(bare.toJson().containsKey('cad'), isFalse);
    expect(bare.toJson().containsKey('power'), isFalse);

    const live = TrackPoint(
      lat: 48.1,
      lng: 8.2,
      timeMs: 1000,
      heartRateBpm: 132,
      cadenceRpm: 78,
      powerW: 210,
    );
    expect(live.toJson()['hr'], 132);
    expect(live.toJson()['cad'], 78);
    expect(live.toJson()['power'], 210);

    const zeros = TrackPoint(
      lat: 48.1,
      lng: 8.2,
      timeMs: 1000,
      heartRateBpm: 0,
      cadenceRpm: 0,
      powerW: 0,
    );
    expect(zeros.toJson().containsKey('hr'), isFalse);
    expect(zeros.toJson().containsKey('cad'), isFalse);
    expect(zeros.toJson().containsKey('power'), isFalse);
  });

  test('GPX writes Garmin HR/cadence only when present', () {
    final without = rideToGpx(
      _ride([
        {'lat': 47.99, 'lng': 7.85, 'elev': 280, 'time': 0},
        {'lat': 48.0, 'lng': 7.86, 'elev': 300, 'time': 60},
      ]),
    );
    expect(without, contains('47.99'));
    expect(without, isNot(contains('<gpxtpx:hr>')));
    expect(without, isNot(contains('<gpxtpx:cad>')));
    expect(without, isNot(contains('PowerInWatts')));

    final withLive = rideToGpx(
      _ride([
        {
          'lat': 47.99,
          'lng': 7.85,
          'elev': 280,
          'time': 0,
          'hr': 132,
          'cad': 78,
          'power': 210,
        },
        {'lat': 48.0, 'lng': 7.86, 'elev': 300, 'time': 60, 'hr': 140},
      ]),
    );
    expect(withLive, contains('<gpxtpx:hr>132</gpxtpx:hr>'));
    expect(withLive, contains('<gpxtpx:cad>78</gpxtpx:cad>'));
    expect(withLive, contains('<gpxpx:PowerInWatts>210</gpxpx:PowerInWatts>'));
    expect(withLive, contains('<gpxtpx:hr>140</gpxtpx:hr>'));
  });

  test('FIT with live HR is larger than GPS-only, never invents 0 bpm', () {
    final gpsOnly = rideToFit(
      _ride([
        {'lat': 47.5, 'lng': 12.2, 'elev': 800, 'time': 0},
        {'lat': 47.51, 'lng': 12.21, 'elev': 801, 'time': 30},
      ]),
    );
    final withHr = rideToFit(
      _ride([
        {'lat': 47.5, 'lng': 12.2, 'elev': 800, 'time': 0, 'hr': 132},
        {'lat': 47.51, 'lng': 12.21, 'elev': 801, 'time': 30, 'hr': 140},
      ]),
    );
    expect(gpsOnly.length, withHr.length);
    expect(String.fromCharCodes(gpsOnly.sublist(8, 12)), '.FIT');
    expect(withHr, isNot(equals(gpsOnly)));
  });
}
