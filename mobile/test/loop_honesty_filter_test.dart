import 'package:aetherride_mobile/domain/routing/route_shape.dart';
import 'package:aetherride_mobile/data/routing/naehe_seeds.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirror of Discover `_isLoop` / Rundkurs filter semantics (D-60-02).
bool isHonestLoop({
  required bool? isLoopHint,
  List<List<double>>? trackLngLat,
  bool isSeed = false,
}) {
  // Curated seeds: explicit is_loop wins (never empty from geometry FN).
  if (isSeed) return isLoopHint == true;
  final shape = routeShapeOf(trackLngLat);
  if (shape == RouteShape.loop) return true;
  if (shape == RouteShape.pointToPoint) return false;
  return isLoopHint == true;
}

void main() {
  test('linear seed excluded from loop filter; closed seed included', () {
    expect(
      isHonestLoop(isLoopHint: false, trackLngLat: null, isSeed: true),
      isFalse,
      reason: 'linear Spree-style seed excluded',
    );
    expect(
      isHonestLoop(isLoopHint: true, trackLngLat: null, isSeed: true),
      isTrue,
      reason: 'curated is_loop seed included even without geometry',
    );

    final linearTrack = <List<double>>[
      [13.4, 52.52],
      [13.42, 52.53],
      [13.45, 52.54],
      [13.5, 52.55],
    ];
    expect(
      isHonestLoop(isLoopHint: true, trackLngLat: linearTrack, isSeed: false),
      isFalse,
      reason: 'live/catalog P2P geometry never passes even with lying hint',
    );

    final closed = syntheticLoopLngLat(
      lat: 52.473,
      lng: 13.405,
      distanceKm: 12,
    );
    expect(
      isHonestLoop(isLoopHint: true, trackLngLat: closed, isSeed: true),
      isTrue,
      reason: 'closed seed included',
    );
    expect(
      isHonestLoop(isLoopHint: false, trackLngLat: closed, isSeed: false),
      isTrue,
      reason: 'live geometry confirms loop even without hint',
    );
  });

  test('legacy loop flag alias parses as isLoop', () {
    final route = NaeheSeedRoute.fromJson({
      'id': 'seed-loop-alias',
      'type': 'route',
      'title': 'Alias Loop',
      'distance_km': 16,
      'ascent_m': 40,
      'duration_min': 55,
      'effort_label': 'Leicht',
      'sport_tags': ['city'],
      'center': {'lat': 49.4, 'lng': 8.6},
      'loop': true, // RN premium/base schema
      'duration_band': '60',
    });
    expect(route.isLoop, isTrue);
  });
}
