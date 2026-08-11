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
  late String rnRaw;

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
    rnRaw = _readFirstExisting([
      'assets/seeds/p0-rhein-neckar-60min-premium-v1.json',
      'mobile/assets/seeds/p0-rhein-neckar-60min-premium-v1.json',
      '../assets/seeds/p0-rhein-neckar-60min-premium-v1.json',
    ], label: 'Rhein-Neckar Premium-Pass seeds');
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

  test('Rhein-Neckar Premium-Pass has rn-1/2/3 with premium fields', () {
    final rn = NaeheSeedsBundle.parse(rnRaw);
    final loops = rn.loops;
    expect(loops.length, greaterThanOrEqualTo(3));
    expect(
      loops.map((e) => e.id).toSet(),
      containsAll([
        'seed-dach-60-rn-1-heidelberg-neckarwiese',
        'seed-dach-60-rn-2-mannheim-schloss-waldpark',
        'seed-dach-60-rn-3-heidelberg-boxberg-gaisberg',
      ]),
    );
    for (final l in loops) {
      expect(l.isLoop, isTrue);
      expect(l.durationBand, '60');
      expect(l.durationMin, inInclusiveRange(45, 75));
      expect(l.poiStops, isNotEmpty);
      expect(l.poiStops.every((p) => p.atMin >= 0), isTrue);
      expect(l.tip, isNotEmpty);
      expect(l.season, isNotEmpty);
      expect(l.seasonLabel, isNotEmpty);
      expect(l.highlightPoi, isNotEmpty);
      expect(l.disciplineNote, isNotEmpty);
      expect(l.corridorNote, isNotEmpty);
      expect(l.shortPitch, isNotEmpty);
      expect(l.surfaceMixLabel, isNotEmpty);
      // Canonical poi_stops: id / type / title / offset_min (+ why_good?).
      expect(l.poiStops.every((p) => p.id.isNotEmpty), isTrue);
      expect(l.poiStops.every((p) => p.title.isNotEmpty), isTrue);
      expect(l.poiStops.every((p) => p.kind.isNotEmpty), isTrue);
      expect(l.poiStops.any((p) => p.whyGood != null), isTrue);
    }
  });

  test('merge berlin+dach+RN yields ≥3 RN premium loops after load merge', () {
    final berlin = NaeheSeedsBundle.parse(berlinRaw);
    final dach = NaeheSeedsBundle.parse(dachRaw);
    final rn = NaeheSeedsBundle.parse(rnRaw);
    final merged = NaeheSeedsBundle.merge(
      NaeheSeedsBundle.merge(berlin, dach),
      rn,
    );
    expect(merged.loops.length, greaterThanOrEqualTo(12)); // 3+6+3
    final rnIds = {
      'seed-dach-60-rn-1-heidelberg-neckarwiese',
      'seed-dach-60-rn-2-mannheim-schloss-waldpark',
      'seed-dach-60-rn-3-heidelberg-boxberg-gaisberg',
    };
    expect(merged.loops.where((l) => rnIds.contains(l.id)).length, 3);
    // Wiesloch (~49.29, 8.70): HD/MA centers within ~35 km.
    const wLat = 49.29;
    const wLng = 8.70;
    double distKm(double lat1, double lng1, double lat2, double lng2) {
      // Haversine-ish approx for test
      final dLat = (lat2 - lat1) * 111.0;
      final dLng = (lng2 - lng1) * 111.0 * 0.65; // cos~49°
      return (dLat * dLat + dLng * dLng);
    }
    final hd = merged.byId('seed-dach-60-rn-1-heidelberg-neckarwiese')!;
    final ma = merged.byId('seed-dach-60-rn-2-mannheim-schloss-waldpark')!;
    expect(distKm(wLat, wLng, hd.centerLat, hd.centerLng), lessThan(35 * 35));
    expect(distKm(wLat, wLng, ma.centerLat, ma.centerLng), lessThan(35 * 35));
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

  /// D-60-LOOP-FILTER-01: Rundkurs / ~60 lens never includes linear.
  test('loops getter excludes linear; closed Tempelhofer included', () {
    final berlin = NaeheSeedsBundle.parse(berlinRaw);
    final dach = NaeheSeedsBundle.parse(dachRaw);
    final rn = NaeheSeedsBundle.parse(rnRaw);
    final merged = NaeheSeedsBundle.merge(
      NaeheSeedsBundle.merge(berlin, dach),
      rn,
    );
    final loops = merged.loops;
    expect(
      loops.any((r) => r.id == 'seed-route-spree-commute'),
      isFalse,
      reason: 'linear Spree commute must not appear under Rundkurs',
    );
    expect(
      loops.any((r) => r.id == 'seed-loop-tempelhofer-60'),
      isTrue,
      reason: 'closed Tempelhofer included',
    );
    expect(loops.every((r) => r.isLoop), isTrue);
  });
}
