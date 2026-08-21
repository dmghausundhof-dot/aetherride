import 'package:aetherride_mobile/data/local/ride_prefs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parsePlanGeocodeRecents drops junk, caps at 5, dedupes', () {
    expect(parsePlanGeocodeRecents(null), isEmpty);
    expect(
      parsePlanGeocodeRecents([
        {'label': 'Kino', 'lat': 49.3, 'lng': 8.64},
        {'label': 'Kino', 'lat': 49.3, 'lng': 8.64},
        {'label': 'bad', 'lat': 99, 'lng': 0},
        {'label': 'Markt', 'lat': 49.41, 'lng': 8.69},
      ]).map((e) => e.label).toList(),
      ['Kino', 'Markt'],
    );
  });

  test('mergePlanGeocodeRecents puts last dest first', () {
    const recents = [
      PlanGeocodeRecent(label: 'Markt', lat: 49.41, lng: 8.69),
    ];
    const last = LastPlanDest(lat: 49.3, lng: 8.64, label: 'Kino');
    expect(
      mergePlanGeocodeRecents(recents, last).map((e) => e.label).toList(),
      ['Kino', 'Markt'],
    );
    expect(
      mergePlanGeocodeRecents(recents, null).map((e) => e.label).toList(),
      ['Markt'],
    );
  });
}
