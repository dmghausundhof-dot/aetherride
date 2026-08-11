import 'package:aetherride_mobile/data/routing/routing_client.dart';
import 'package:flutter_test/flutter_test.dart';

// Surface-Helpers sind privat in discover_screen — hier nur Profil-Labels
// und Multi-Sport-Parität absichern (öffentliche API).

void main() {
  test('routing profile labels are short multi-sport', () {
    expect(RoutingProfile.road.label, 'Rennrad');
    expect(RoutingProfile.urban.label, 'City');
    expect(RoutingProfile.gravel.label, 'Gravel');
    expect(RoutingProfile.mtbTrail.label, 'MTB');
    expect(RoutingProfile.ebikeTour.label, 'E-Trekking');
  });
}
