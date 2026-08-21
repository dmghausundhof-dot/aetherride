import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/domain/ride/ride_telemetry.dart';

void main() {
  test('empty track stays empty', () {
    expect(buildRideTelemetry([]).samples, isEmpty);
    expect(buildRideTelemetry([{'lat': 48, 'lng': 8}]).channels.elev, isFalse);
  });

  test('1 km climb yields ~10% grade and climb', () {
    final endLat = 48.0 + 1000 / 111320;
    final t = buildRideTelemetry([
      {
        'lat': 48.0,
        'lng': 8.0,
        'elev': 200,
        'time': 1700000000000,
      },
      {
        'lat': endLat,
        'lng': 8.0,
        'elev': 300,
        'time': 1700000000000 + 240000,
      },
    ]);
    expect(t.channels.elev, isTrue);
    expect(t.climbM, inInclusiveRange(90, 110));
    expect(t.descentM, 0);
    expect(t.samples.last.gradePct, isNotNull);
    expect(t.samples.last.gradePct!, inInclusiveRange(8, 12));
    expect(t.samples.last.band, GradeBand.steepUp);
  });

  test('GPS jitter under 18 m does not invent a grade', () {
    final t = buildRideTelemetry([
      {'lat': 48.0, 'lng': 8.0, 'elev': 200},
      {'lat': 48.0 + 2 / 111320, 'lng': 8.0, 'elev': 212},
    ]);
    expect(t.samples.last.gradePct, isNull);
    expect(t.samples.last.band, GradeBand.gap);
  });

  test('elevation gap stays a gap', () {
    final t = buildRideTelemetry([
      {'lat': 48.0, 'lng': 8.0, 'elev': 200},
      {'lat': 48.0 + 400 / 111320, 'lng': 8.0},
      {'lat': 48.0 + 800 / 111320, 'lng': 8.0, 'elev': 240},
    ]);
    expect(t.gapKm, greaterThan(0.2));
    expect(t.samples[1].elevM, isNull);
    expect(t.samples[1].band, GradeBand.gap);
  });

  test('sensor channels only when present', () {
    final live = buildRideTelemetry([
      {
        'lat': 48.0,
        'lng': 8.0,
        'elev': 200,
        'hr': 132,
        'cad': 78,
        'power': 190,
        'lean': 8,
        'g': 1.4,
      },
      {
        'lat': 48.0 + 500 / 111320,
        'lng': 8.0,
        'elev': 210,
        'hr': 148,
        'cad': 82,
        'power': 210,
        'lean': 12,
        'g': 2.1,
        'impact': 1,
      },
    ]);
    expect(live.channels.hr, isTrue);
    expect(live.channels.impact, isTrue);
    expect(live.impactCount, 1);

    final bare = buildRideTelemetry([
      {'lat': 48.0, 'lng': 8.0, 'elev': 200},
      {'lat': 48.0 + 500 / 111320, 'lng': 8.0, 'elev': 210},
    ]);
    expect(bare.channels.hr, isFalse);
    expect(bare.channels.impact, isFalse);
  });

  test('honestClimbM prefers telemetry over stored gain', () {
    final climb = honestClimbM([
      {'lat': 48.0, 'lng': 8.0, 'elev': 200, 'time': 0},
      {
        'lat': 48.0 + 1000 / 111320,
        'lng': 8.0,
        'elev': 300,
        'time': 240,
      },
    ], 800);
    expect(climb, inInclusiveRange(90, 110));
    expect(honestClimbM(const [], 120), 120);
    expect(
      honestClimbM([
        {'lat': 48.0, 'lng': 8.0, 'elev': 200, 'time': 0},
        {
          'lat': 48.0 + 800 / 111320,
          'lng': 8.0,
          'elev': 201,
          'time': 180,
        },
      ], 800),
      0,
    );
    final t = buildRideTelemetry([
      {'lat': 48.0, 'lng': 8.0, 'elev': 200},
      {'lat': 48.0 + 600 / 111320, 'lng': 8.0, 'elev': 260},
    ]);
    expect(nearestSample(t, t.totalDistKm / 2), isNotNull);
    expect(terrainCaption(t), contains('hm'));
    expect(terrainCaption(buildRideTelemetry(const [])), isNull);
  });

  test('grade map layers have color and at least two points', () {
    final t = buildRideTelemetry([
      {'lat': 48.0, 'lng': 8.0, 'elev': 200},
      {'lat': 48.0 + 600 / 111320, 'lng': 8.0, 'elev': 260},
      {'lat': 48.0 + 1200 / 111320, 'lng': 8.0, 'elev': 250},
    ]);
    final layers = gradeMapLayers(t);
    expect(layers, isNotEmpty);
    expect(layers.first.points.length, greaterThanOrEqualTo(2));
    expect(layers.first.colorHex, startsWith('#'));
  });
}
