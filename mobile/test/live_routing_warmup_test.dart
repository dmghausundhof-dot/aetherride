import 'package:aetherride_mobile/domain/routing/live_routing_warmup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('warmup dummy sits east of the rider without racing A–B', () {
    final to = liveRoutingWarmupTo(lat: 49.4, lng: 8.67);
    expect(to.lat, 49.4);
    expect(to.lng, greaterThan(8.67));
    expect(to.lng - 8.67, lessThan(0.01));
    expect(
      liveRoutingWarmupCell(profile: 'gravel', lat: 49.4, lng: 8.67),
      liveRoutingWarmupCell(profile: 'gravel', lat: 49.401, lng: 8.669),
    );
    expect(
      liveRoutingWarmupCell(profile: 'gravel', lat: 49.4, lng: 8.67),
      isNot(liveRoutingWarmupCell(profile: 'urban', lat: 49.4, lng: 8.67)),
    );
    expect(
      shouldWarmLiveRouting(hasStart: true, hasEnd: false),
      isTrue,
    );
    expect(
      shouldWarmLiveRouting(hasStart: true, hasEnd: true),
      isFalse,
    );
  });
}
