import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/ride.dart';

void main() {
  test('Bike isActive and categoryLabel', () {
    const bike = Bike(
      id: '1',
      name: 'Trail',
      category: BikeCategory.emtb,
      isActive: true,
    );
    expect(bike.isActive, isTrue);
    expect(bike.categoryLabel, 'E-MTB');
    expect(bike.copyWith(isActive: false).isActive, isFalse);
  });

  test('RideFeedback JSON roundtrip', () {
    const fb = RideFeedback(
      overallFeel: 4,
      frontFeel: 'too_firm',
      brakeDive: 'neutral',
      smallBump: 'ok',
    );
    final again = RideFeedback.fromJson(fb.toJson());
    expect(again.overallFeel, 4);
    expect(again.frontFeel, 'too_firm');
    expect(again.skipped, isFalse);
  });

  test('TrackPoint JSON', () {
    const p = TrackPoint(lat: 48.1, lng: 8.2, timeMs: 1000, elev: 400);
    expect(p.toJson()['lat'], 48.1);
    expect(p.toJson()['lng'], 8.2);
    expect(p.toJson()['elev'], 400);
    expect(p.toJson().containsKey('hr'), isFalse);
  });
}
