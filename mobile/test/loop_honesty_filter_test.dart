import 'package:aetherride_mobile/domain/routing/route_shape.dart';
import 'package:aetherride_mobile/data/routing/naehe_seeds.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirror of Discover `_isLoop` / Rundkurs filter semantics (D-60-02).
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
  test('linear seed excluded from loop filter; closed seed included', () {
    final linearTrack = <List<double>>[
      [13.4, 52.52],
      [13.42, 52.53],
      [13.45, 52.54],
      [13.5, 52.55],
    ];
    expect(
      isHonestLoop(isLoopHint: true, trackLngLat: linearTrack),
      isFalse,
      reason: 'P2P geometry never passes even with lying hint',
    );
    expect(
      isHonestLoop(isLoopHint: false, trackLngLat: null),
      isFalse,
      reason: 'linear Spree-style seed without track excluded',
    );

    final closed = syntheticLoopLngLat(
      lat: 52.473,
      lng: 13.405,
      distanceKm: 12,
    );
    expect(
      isHonestLoop(isLoopHint: true, trackLngLat: closed),
      isTrue,
      reason: 'closed seed included',
    );
    expect(
      isHonestLoop(isLoopHint: false, trackLngLat: closed),
      isTrue,
      reason: 'geometry confirms loop even without hint',
    );
    expect(
      isHonestLoop(isLoopHint: true, trackLngLat: null),
      isTrue,
      reason: 'seed is_loop without track still honest for curated loops',
    );
  });
}
