import 'package:aetherride_mobile/domain/routing/tour_coverage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty stays empty', () {
    expect(
      TourCoverage.pickNearbyThenFill<int>(
        items: const [],
        distanceKm: (i) => i.toDouble(),
      ),
      isEmpty,
    );
  });

  test('nearby ≥ minCount keeps nearby only (capped)', () {
    final items = List<int>.generate(40, (i) => i); // km = index
    final picked = TourCoverage.pickNearbyThenFill(
      items: items,
      distanceKm: (i) => i.toDouble(),
      nearbyKm: 90,
      minCount: 12,
      maxItems: 32,
    );
    expect(picked.length, 32);
    expect(picked.first, 0);
    expect(picked.last, 31);
  });

  test('thin nearby fills with next-closest so Touren is not a 3-card stub', () {
    // 3 within 35 km, rest farther — Heidelberg/Wiesloch pattern.
    final items = <({String id, double km})>[
      (id: 'hd', km: 12),
      (id: 'ma', km: 18),
      (id: 'boxberg', km: 22),
      (id: 'ka', km: 48),
      (id: 'mainz', km: 72),
      (id: 'ffm', km: 80),
      (id: 'stgt', km: 88),
      (id: 'wue', km: 95),
      (id: 'koeln', km: 180),
      (id: 'muc', km: 270),
      (id: 'berlin', km: 530),
      (id: 'wien', km: 620),
    ];
    final picked = TourCoverage.pickNearbyThenFill(
      items: items,
      distanceKm: (e) => e.km,
      nearbyKm: 90,
      minCount: 12,
      maxItems: 32,
    );
    expect(picked.length, 12);
    expect(picked.map((e) => e.id).take(3), ['hd', 'ma', 'boxberg']);
    expect(picked.map((e) => e.id), containsAll(['ka', 'mainz', 'ffm', 'stgt']));
    expect(picked.last.id, 'wien');
  });

  test('fewer items than minCount returns all', () {
    final picked = TourCoverage.pickNearbyThenFill(
      items: const [10.0, 20.0, 30.0],
      distanceKm: (e) => e,
    );
    expect(picked, [10.0, 20.0, 30.0]);
  });
}
