import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/data/routing/geocode_client.dart';
import 'package:aetherride_mobile/domain/routing/navigate_workflow.dart';

void main() {
  const frankfurt = GeocodeHit(
    label: 'Frankfurt (Main) Hauptbahnhof',
    lat: 50.107,
    lng: 8.664,
  );

  test('Navigieren ohne Ziel übernimmt den letzten Ort', () {
    final intent = beginNavigateIntent(
      hasEnd: false,
      lastPlace: frankfurt,
    );
    expect(intent.pickEnd, isTrue);
    expect(intent.destination?.label, frankfurt.label);
  });

  test('gesetztes Ziel bleibt', () {
    final intent = beginNavigateIntent(
      hasEnd: true,
      lastPlace: frankfurt,
    );
    expect(intent.destination, isNull);
  });

  test('ohne letzten Ort gilt der erste Chip', () {
    final intent = beginNavigateIntent(
      hasEnd: false,
      pendingHits: [frankfurt],
    );
    expect(intent.destination?.label, frankfurt.label);
  });

  test('Orts-Chip ist nur im Plan das Ziel', () {
    expect(placeHitAppliesAsDestination(navigating: true), isTrue);
    expect(placeHitAppliesAsDestination(navigating: false), isFalse);
  });

  test('Explore-Long-Press öffnet Planen ohne Pick', () {
    expect(
      discoverExploreMapTapOpensPlan(planning: false, picking: false),
      isTrue,
    );
    expect(
      discoverExploreMapTapOpensPlan(planning: true, picking: false),
      isFalse,
    );
    expect(
      discoverExploreMapTapOpensPlan(planning: false, picking: true),
      isFalse,
    );
  });
}
