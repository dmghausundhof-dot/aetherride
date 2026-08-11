import 'dart:io';

import 'package:aetherride_mobile/data/routing/naehe_seeds.dart';
import 'package:aetherride_mobile/domain/routing/route_shape.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late String raw;

  setUpAll(() {
    // Repo-Root oder mobile/ — beide Pfade versuchen.
    final candidates = [
      'assets/seeds/naehe-peek-seeds-berlin-v1.json',
      'mobile/assets/seeds/naehe-peek-seeds-berlin-v1.json',
      '../assets/seeds/naehe-peek-seeds-berlin-v1.json',
      'naehe-peek-seeds-berlin-v1.json',
      '../naehe-peek-seeds-berlin-v1.json',
    ];
    for (final p in candidates) {
      final f = File(p);
      if (f.existsSync()) {
        raw = f.readAsStringSync();
        return;
      }
    }
    fail('Berlin seeds JSON not found for unit test');
  });

  test('parse yields ≥3 is_loop routes in ~60 band', () {
    final bundle = NaeheSeedsBundle.parse(raw);
    expect(bundle.labelWithoutLocation, 'In deiner Region');
    final loops = bundle.loops;
    expect(loops.length, greaterThanOrEqualTo(3));
    for (final l in loops) {
      expect(l.isLoop, isTrue);
      expect(l.durationMin, inInclusiveRange(45, 75));
      expect(l.poiStops, isNotEmpty);
    }
    expect(
      loops.map((e) => e.id).toSet(),
      containsAll([
        'seed-loop-tempelhofer-60',
        'seed-loop-spree-feierabend-60',
        'seed-loop-grunewald-kurz-60',
      ]),
    );
  });

  test('synthetic loop track is RouteShape.loop', () {
    final track = syntheticLoopLngLat(
      lat: 52.473,
      lng: 13.405,
      distanceKm: 12,
    );
    expect(track.length, greaterThan(4));
    expect(routeShapeOf(track), RouteShape.loop);
  });

  test('seed toActiveRoute has coordinates', () {
    final bundle = NaeheSeedsBundle.parse(raw);
    final seed = bundle.byId('seed-loop-tempelhofer-60')!;
    final ar = seed.toActiveRoute();
    expect(ar.id, seed.id);
    expect(ar.coordinates.length, greaterThanOrEqualTo(4));
    expect(ar.durationMin, 50);
  });

  test('non-loop seed is not forced loop', () {
    final bundle = NaeheSeedsBundle.parse(raw);
    final spree = bundle.byId('seed-route-spree-commute');
    expect(spree, isNotNull);
    expect(spree!.isLoop, isFalse);
    expect(spree.trackLngLat, isNull);
  });
}
