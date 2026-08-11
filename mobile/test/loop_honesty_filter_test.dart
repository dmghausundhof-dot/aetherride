import 'package:aetherride_mobile/data/routing/naehe_seeds.dart';
import 'package:aetherride_mobile/domain/routing/route_shape.dart';
import 'package:flutter_test/flutter_test.dart';

/// D-60-LOOP-FILTER-01 — mirror of Discover `_isLoop` / Rundkurs filter.
bool isHonestLoop({
  required bool? isLoopHint,
  List<List<double>>? trackLngLat,
}) {
  final shape = routeShapeOf(trackLngLat);
  if (shape == RouteShape.loop) return true;
  if (shape == RouteShape.pointToPoint) return false;
  return isLoopHint == true;
}

void main() {
  test('linear seed excluded; is_loop seed included', () {
    expect(
      isHonestLoop(isLoopHint: false, trackLngLat: null),
      isFalse,
      reason: 'linear Spree-style seed excluded',
    );
    expect(
      isHonestLoop(isLoopHint: true, trackLngLat: null),
      isTrue,
      reason: 'curated is_loop without geometry included',
    );
  });

  test('closed geometry ≤~200 m passes without is_loop flag', () {
    final ring = syntheticLoopLngLat(lat: 52.47, lng: 13.40, distanceKm: 12);
    expect(routeShapeOf(ring), RouteShape.loop);
    expect(
      isHonestLoop(isLoopHint: false, trackLngLat: ring),
      isTrue,
      reason: 'start≈end geometry alone is enough',
    );
  });

  test('point-to-point geometry never padded as Rundkurs', () {
    final line = [
      for (var i = 0; i < 12; i++) [13.4 + i * 0.01, 52.5],
    ];
    expect(routeShapeOf(line), RouteShape.pointToPoint);
    expect(
      isHonestLoop(isLoopHint: true, trackLngLat: line),
      isFalse,
      reason: 'lying is_loop rejected when geometry is A→B',
    );
  });

  test('legacy loop / closed aliases set isLoop', () {
    final viaLoop = NaeheSeedRoute.fromJson({
      'id': 'a',
      'type': 'route',
      'title': 'RN legacy',
      'distance_km': 16,
      'ascent_m': 40,
      'duration_min': 55,
      'center': {'lat': 49.4, 'lng': 8.6},
      'loop': true,
    });
    final viaClosed = NaeheSeedRoute.fromJson({
      'id': 'b',
      'type': 'route',
      'title': 'Closed alias',
      'distance_km': 12,
      'ascent_m': 20,
      'duration_min': 50,
      'center': {'lat': 52.5, 'lng': 13.4},
      'closed': true,
    });
    final missing = NaeheSeedRoute.fromJson({
      'id': 'c',
      'type': 'route',
      'title': 'No flag',
      'distance_km': 18,
      'ascent_m': 40,
      'duration_min': 55,
      'center': {'lat': 52.5, 'lng': 13.4},
    });
    expect(viaLoop.isLoop, isTrue);
    expect(viaClosed.isLoop, isTrue);
    expect(missing.isLoop, isFalse);
  });
}
