import 'package:aetherride_mobile/data/routing/routing_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OSM round-trip sport gate — no MTB / EMTB / hike', () {
    expect(profileAllowsOsmRoundTrip(RoutingProfile.gravel), isTrue);
    expect(profileAllowsOsmRoundTrip(RoutingProfile.road), isTrue);
    expect(profileAllowsOsmRoundTrip(RoutingProfile.urban), isTrue);
    expect(profileAllowsOsmRoundTrip(RoutingProfile.ebikeTour), isTrue);
    expect(profileAllowsOsmRoundTrip(RoutingProfile.mtbTrail), isFalse);
    expect(profileAllowsOsmRoundTrip(RoutingProfile.mtbEnduro), isFalse);
    expect(profileAllowsOsmRoundTrip(RoutingProfile.downhill), isFalse);
    expect(profileAllowsOsmRoundTrip(RoutingProfile.emtb), isFalse);
    expect(profileAllowsOsmRoundTrip(RoutingProfile.hiking), isFalse);
    expect(profileAllowsOsmRoundTrip(RoutingProfile.driving), isFalse);
  });
}
