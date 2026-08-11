import 'dart:io';

import 'package:aetherride_mobile/data/routing/naehe_seeds.dart';
import 'package:aetherride_mobile/domain/routing/route_shape.dart';
import 'package:flutter_test/flutter_test.dart';

String _readFirstExisting(List<String> candidates, {required String label}) {
  for (final p in candidates) {
    final f = File(p);
    if (f.existsSync()) return f.readAsStringSync();
  }
  fail('$label JSON not found for unit test');
}

void main() {
  late String berlinRaw;
  late String dachRaw;

  setUpAll(() {
    // Repo-Root oder mobile/ — beide Pfade versuchen.
    berlinRaw = _readFirstExisting([
      'assets/seeds/naehe-peek-seeds-berlin-v1.json',
      'mobile/assets/seeds/naehe-peek-seeds-berlin-v1.json',
      '../assets/seeds/naehe-peek-seeds-berlin-v1.json',
      'naehe-peek-seeds-berlin-v1.json',
      '../naehe-peek-seeds-berlin-v1.json',
    ], label: 'Berlin seeds');
    dachRaw = _readFirstExisting([
      'assets/seeds/p0-dach-60min-naehe-v1.json',
      'mobile/assets/seeds/p0-dach-60min-naehe-v1.json',
      '../assets/seeds/p0-dach-60min-naehe-v1.json',
    ], label: 'DACH Nähe seeds');
  });

  test('parse yields ≥3 is_loop routes in ~60 band', () {
    final bundle = NaeheSeedsBundle.parse(berlinRaw);
    expect(bundle.labelWithoutLocation, '~60 Min in deiner Region');
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

  test('tempelhofer seed enriched from DACH Bike Knowledge', () {
    final bundle = NaeheSeedsBundle.parse(berlinRaw);
    final seed = bundle.byId('seed-loop-tempelhofer-60')!;
    expect(seed.distanceKm, 18);
    expect(seed.durationMin, 55);
    expect(seed.poiStops.length, greaterThanOrEqualTo(4));
    expect(
      seed.poiStops.any((p) => p.title.contains('Landwehrkanal')),
      isTrue,
    );
    // Canonical offset_min / type shape accepted by parser.
    expect(seed.poiStops.first.atMin, greaterThan(0));
    expect(seed.poiStops.first.kind, isNotEmpty);
  });

  test('DACH Nähe bundle has ≥6 non-Berlin loops', () {
    final dach = NaeheSeedsBundle.parse(dachRaw);
    final loops = dach.loops;
    expect(loops.length, greaterThanOrEqualTo(6));
    expect(
      loops.map((e) => e.id).toSet(),
      containsAll([
        'seed-loop-munich-froettmaning-60',
        'seed-loop-vienna-prater-60',
        'seed-loop-innsbruck-hungerburg-60',
        'seed-loop-cologne-rhein-60',
        'seed-loop-zurich-seefeld-60',
        'seed-loop-konstanz-mainau-60',
      ]),
    );
    for (final l in loops) {
      expect(l.isLoop, isTrue);
      expect(l.durationBand, '60');
      expect(l.poiStops, isNotEmpty);
      expect(l.poiStops.every((p) => p.atMin > 0), isTrue);
    }
  });

  test('merge berlin+dach dedupes by id and keeps Tempelhof enrich', () {
    final berlin = NaeheSeedsBundle.parse(berlinRaw);
    final dach = NaeheSeedsBundle.parse(dachRaw);
    final merged = NaeheSeedsBundle.merge(berlin, dach);
    expect(merged.loops.length, greaterThanOrEqualTo(9)); // 3 berlin + 6 dach
    final ids = merged.routes.map((e) => e.id).toList();
    expect(ids.toSet().length, ids.length);
    final tempel = merged.byId('seed-loop-tempelhofer-60')!;
    expect(tempel.distanceKm, 18);
    expect(merged.byId('seed-loop-munich-froettmaning-60'), isNotNull);
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
    final bundle = NaeheSeedsBundle.parse(berlinRaw);
    final seed = bundle.byId('seed-loop-tempelhofer-60')!;
    final ar = seed.toActiveRoute();
    expect(ar.id, seed.id);
    expect(ar.coordinates.length, greaterThanOrEqualTo(4));
    expect(ar.durationMin, 55);
  });

  test('non-loop seed is not forced loop', () {
    final bundle = NaeheSeedsBundle.parse(berlinRaw);
    final spree = bundle.byId('seed-route-spree-commute');
    expect(spree, isNotNull);
    expect(spree!.isLoop, isFalse);
    expect(spree.trackLngLat, isNull);
  });
}
