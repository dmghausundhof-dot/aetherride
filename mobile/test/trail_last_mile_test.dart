import 'package:aetherride_mobile/domain/routing/trail_difficulty.dart';
import 'package:aetherride_mobile/domain/routing/trail_last_mile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final s3 = <List<double>>[
    [8.70, 49.401],
    [8.73, 49.401],
    [8.76, 49.401],
    [8.79, 49.401],
  ];

  test('tap on S3 is dest-on-trail', () {
    expect(
      destLiesOnTrail(s3, toLat: 49.401, toLng: 8.76),
      isTrue,
    );
    expect(
      destLiesOnTrail(s3, toLat: 49.42, toLng: 8.76),
      isFalse,
    );
  });

  test('last mile stops at the tap, not the far trailhead', () {
    final mile = clipTrailLastMile(
      trailLngLat: s3,
      fromLat: 49.398,
      fromLng: 8.74,
      toLat: 49.401,
      toLng: 8.76,
    );
    expect(mile, isNotNull);
    final lngs = [for (final c in mile!.geometry) c[0]];
    expect(lngs.reduce((a, b) => a > b ? a : b), lessThan(8.765));
    expect(mile.joinLng, greaterThan(8.73));
    expect(mile.lastMileM, lessThan(2500));
  });

  test('from near the west end still caps last mile', () {
    final mile = clipTrailLastMile(
      trailLngLat: s3,
      fromLat: 49.4008,
      fromLng: 8.701,
      toLat: 49.401,
      toLng: 8.76,
    );
    expect(mile, isNotNull);
    expect(mile!.lastMileM, lessThanOrEqualTo(kTrailLastMileMaxM + 80));
    expect(mile.joinLng, greaterThan(8.72));
  });

  test('nudge keeps GH off the distant trailhead', () {
    final n = nudgeJoinTowardRider(
      joinLat: 49.401,
      joinLng: 8.75,
      fromLat: 49.398,
      fromLng: 8.74,
    );
    expect(n.lat, lessThan(49.401));
    expect(n.lng, lessThan(8.75));
  });

  test('via snaps onto nearby trail, far point stays', () {
    final hit = snapPointOntoTrails(
      trails: [s3],
      lat: 49.4014,
      lng: 8.76,
    );
    expect(hit, isNotNull);
    expect(hit!.lat, closeTo(49.401, 0.0003));
    expect(
      snapPointOntoTrails(trails: [s3], lat: 49.5, lng: 8.76),
      isNull,
    );
  });

  test('farm track without scale is not corridor-eligible', () {
    expect(
      trailIsCorridorEligible(
        highway: 'track',
        difficulty: TrailDifficulty.open,
      ),
      isFalse,
    );
    expect(
      trailIsCorridorEligible(
        highway: 'path',
        difficulty: TrailDifficulty.open,
      ),
      isFalse,
    );
    expect(
      trailIsCorridorEligible(
        highway: 'path',
        difficulty: TrailDifficulty.s1,
      ),
      isTrue,
    );
    expect(
      trailIsCorridorEligible(
        highway: 'cycleway',
        difficulty: TrailDifficulty.open,
      ),
      isTrue,
    );
    expect(
      trailIsCorridorEligible(
        highway: 'track',
        difficulty: TrailDifficulty.s1,
      ),
      isTrue,
    );
  });
}
