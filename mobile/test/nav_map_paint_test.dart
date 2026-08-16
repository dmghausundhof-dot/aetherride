import 'package:aetherride_mobile/domain/routing/nav_map_paint.dart';
import 'package:aetherride_mobile/domain/routing/route_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// ~1 km east along lat 49.4 (lng delta ≈ 0.0137).
  final line = <List<double>>[
    [8.70, 49.40],
    [8.7137, 49.40],
  ];

  test('slice at start keeps the full remaining ribbon', () {
    final s = sliceRouteAtAlongM(line, 0);
    expect(s.traveled, isEmpty);
    expect(s.remaining.length, 2);
    expect(s.remaining.first[0], closeTo(8.70, 1e-6));
  });

  test('slice mid-route shares the cut and dims the tail', () {
    final total = routeLengthM(line);
    expect(total, closeTo(1000, 80));
    final s = sliceRouteAtAlongM(line, total * 0.4);
    expect(s.traveled.length, greaterThanOrEqualTo(2));
    expect(s.remaining.length, greaterThanOrEqualTo(2));
    expect(s.traveled.last[0], closeTo(s.remaining.first[0], 1e-8));
    expect(s.traveled.last[0], greaterThan(8.70));
    expect(s.traveled.last[0], lessThan(8.7137));
    expect(routeLengthM(s.traveled), closeTo(total * 0.4, 25));
    expect(routeLengthM(s.remaining), closeTo(total * 0.6, 25));
  });

  test('slice past the end leaves no remaining', () {
    final s = sliceRouteAtAlongM(line, 50000);
    expect(s.remaining, isEmpty);
    expect(s.traveled.length, 2);
  });

  test('look-ahead sits ahead of the rider on remaining', () {
    final along = 200.0;
    final rider = pointAlongRoute(line, along);
    final ahead = pointAlongRoute(line, along + 110);
    expect(ahead[0], greaterThan(rider[0]));
    expect(haversineM(rider[1], rider[0], ahead[1], ahead[0]), closeTo(110, 8));
  });

  test('heading-up framing looks ahead; north-up does not', () {
    final city = navFollowFraming(northUp: false, trailish: false);
    expect(city.lookAheadM, 110);
    expect(city.tilt, 48);
    expect(city.zoom, closeTo(16.2, 0.01));

    final trail = navFollowFraming(northUp: false, trailish: true);
    expect(trail.lookAheadM, 140);
    expect(trail.zoom, lessThan(city.zoom));

    final north = navFollowFraming(northUp: true, trailish: false);
    expect(north.lookAheadM, 0);
    expect(north.tilt, 0);
  });

  test('nav ribbon at z16 is Discover-narrow, not the old 10/18', () {
    final w = navRibbonWidths(16);
    expect(w.remainingCore, closeTo(6.5, 0.6));
    expect(w.remainingCasing, lessThan(16));
    expect(w.remainingCore, lessThan(9));
    final overview = navRibbonWidths(14);
    expect(overview.remainingCore, lessThan(w.remainingCore));
  });

  test('approach vs tour ribbons split at join', () {
    final approach = <List<double>>[
      [8.67, 49.28],
      [8.68, 49.34],
      [8.70, 49.40],
    ];
    final tour = <List<double>>[
      [8.70, 49.40],
      [8.7137, 49.40],
    ];
    final coords = [...approach, ...tour.sublist(1)];
    final joinM = routeLengthM(approach);
    final layers = navPhaseRibbons(
      coordinates: coords,
      alongRouteM: 0,
      joinAlongM: joinM,
    );
    expect(layers.approachRemaining, isNotEmpty);
    expect(layers.tourRemaining, isNotEmpty);
    expect(layers.joinLngLat, isNotNull);
    expect(layers.joinLngLat![0], closeTo(8.70, 1e-4));
    expect(
      layers.approachRemaining.last[0],
      closeTo(layers.tourRemaining.first[0], 1e-6),
    );
    expect(NavMapColors.approachCore, isNot(NavMapColors.remainingCore));
  });

  test('after join the remaining ribbon is tour-green only', () {
    final coords = <List<double>>[
      [8.67, 49.28],
      [8.70, 49.40],
      [8.7137, 49.40],
    ];
    final joinM = routeLengthM([coords[0], coords[1]]);
    final total = routeLengthM(coords);
    final layers = navPhaseRibbons(
      coordinates: coords,
      alongRouteM: joinM + 10,
      joinAlongM: joinM,
    );
    expect(layers.approachRemaining, isEmpty);
    expect(layers.tourRemaining, isNotEmpty);
    expect(routeLengthM(layers.tourRemaining), closeTo(total - joinM - 10, 80));
  });
}
