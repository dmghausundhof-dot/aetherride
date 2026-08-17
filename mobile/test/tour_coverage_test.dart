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

  test('thin nearby stays regional — never fill with another landscape', () {
    // 3 within 35 km, more within 90, rest another Bundesland / country.
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
    expect(picked.map((e) => e.id).take(3), ['hd', 'ma', 'boxberg']);
    expect(picked.map((e) => e.id), containsAll(['ka', 'mainz', 'ffm', 'stgt']));
    expect(picked.every((e) => e.km <= 90), isTrue);
    expect(picked.map((e) => e.id), isNot(contains('wien')));
    expect(picked.map((e) => e.id), isNot(contains('koeln')));
    expect(picked.length, 7);
  });

  test('zero nearby returns empty instead of a far-away landscape', () {
    final picked = TourCoverage.pickNearbyThenFill(
      items: const [
        (id: 'bern', km: 107.0),
        (id: 'lausanne', km: 102.0),
      ],
      distanceKm: (e) => e.km,
      nearbyKm: 90,
    );
    expect(picked, isEmpty);
  });

  test('nearby distance beats a farther sport match', () {
    expect(
      TourCoverage.compareNearbyThenSport(
        distanceKmA: 2,
        distanceKmB: 32,
        sportMatchA: false,
        sportMatchB: true,
      ),
      lessThan(0),
    );
    expect(
      TourCoverage.compareNearbyThenSport(
        distanceKmA: 10,
        distanceKmB: 10,
        sportMatchA: true,
        sportMatchB: false,
      ),
      lessThan(0),
    );
  });

  test('fewer nearby than minCount returns all nearby', () {
    final picked = TourCoverage.pickNearbyThenFill(
      items: const [10.0, 20.0, 30.0],
      distanceKm: (e) => e,
    );
    expect(picked, [10.0, 20.0, 30.0]);
  });
}
