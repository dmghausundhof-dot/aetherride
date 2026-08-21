import 'dart:io';
import 'dart:math' as math;

import 'package:aetherride_mobile/data/routing/naehe_seeds.dart';
import 'package:aetherride_mobile/domain/routing/route_shape.dart';
import 'package:aetherride_mobile/domain/routing/tour_coverage.dart';
import 'package:aetherride_mobile/domain/routing/tour_nav_geometry.dart';
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
  late String gapsRaw;

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
    gapsRaw = _readFirstExisting([
      'assets/seeds/p0-gaps-60min-naehe-v1.json',
      'mobile/assets/seeds/p0-gaps-60min-naehe-v1.json',
      '../assets/seeds/p0-gaps-60min-naehe-v1.json',
    ], label: 'Alpen/Ostsee Lücken seeds');
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
    expect(seed.poiStops.any((p) => p.whyGood != null), isTrue);
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
    final munich = dach.byId('seed-loop-munich-froettmaning-60')!;
    expect(munich.poiStops.any((p) => p.whyGood != null), isTrue);
  });

  test('catalog Baden-Baden attaches Lichtental seed track + pin', () {
    final dach = NaeheSeedsBundle.parse(dachRaw);
    final seed = dach.byId('seed-loop-baden-baden-lichtental-60');
    expect(seed, isNotNull);
    expect(seed!.hasBakedGeometry, isTrue);
    expect(isUsableMapTrack(seed.trackLngLat), isTrue);

    final hit = pickBundledSeedForCatalog(
      catalogName: 'Baden-Baden Lichtental Loop',
      catalogLat: 47.99,
      catalogLng: 7.85,
      catalogDistanceKm: 16,
      seeds: [
        for (final s in dach.routes)
          if (s.trackLngLat != null)
            (
              title: s.title,
              lat: s.centerLat,
              lng: s.centerLng,
              distanceKm: s.distanceKm,
              trackLngLat: s.trackLngLat!,
            ),
      ],
    );
    expect(hit, isNotNull);
    expect(hit!.lat, closeTo(48.761, 0.02));
    expect(hit.lng, closeTo(8.24, 0.02));
    expect(isUsableMapTrack(hit.trackLngLat), isTrue);
    expect(hit.trackLngLat.length, seed.trackLngLat!.length);
  });

  test('DACH covers broad regions plus MTB trail loops', () {
    final dach = NaeheSeedsBundle.parse(dachRaw);
    final ids = dach.loops.map((e) => e.id).toSet();
    expect(dach.loops.length, greaterThanOrEqualTo(120));
    expect(
      ids,
      containsAll([
        // Bundesländer / Kantone Ergänzungen
        'seed-loop-freiburg-dreisam-60',
        'seed-loop-hannover-eilenriede-60',
        'seed-loop-mainz-rhein-60',
        'seed-loop-erfurt-gera-60',
        'seed-loop-linz-donau-60',
        'seed-loop-geneva-lac-60',
        'seed-loop-lucerne-see-60',
        // Erweiterte Lücken (Nord/Ost/West + AT/CH)
        'seed-loop-bremen-weser-60',
        'seed-loop-kiel-foerde-60',
        'seed-loop-potsdam-havel-60',
        'seed-loop-karlsruhe-hardtwald-60',
        'seed-loop-muenster-promenade-60',
        'seed-loop-klagenfurt-woerthersee-60',
        'seed-loop-lausanne-lac-60',
        'seed-loop-st-gallen-saentisblick-60',
        // MTB / Trail Nähe
        'seed-loop-munich-perlach-mtb-60',
        'seed-loop-vienna-wienerwald-mtb-60',
        'seed-loop-zurich-uetliberg-mtb-60',
        'seed-loop-freiburg-schwarzwald-mtb-60',
        'seed-loop-innsbruck-hungerburg-60',
        'seed-loop-karlsruhe-hardt-mtb-60',
        'seed-loop-muenster-hiltrup-mtb-60',
        // BW densify 2026-08
        'seed-loop-ulm-donau-60',
        'seed-loop-tuebingen-neckar-60',
        'seed-loop-heilbronn-neckar-60',
        'seed-loop-baiersbronn-mtb-60',
        'seed-loop-titisee-feldberg-mtb-60',
        'seed-loop-loerrach-dinkelberg-60',
        // Weitere DACH
        'seed-loop-wuerzburg-main-60',
        'seed-loop-lugano-see-60',
        'seed-loop-villach-drau-60',
        'seed-loop-innsbruck-nordkette-mtb-60',
      ]),
    );
    final mtb = dach.loops
        .where((l) => l.sportTags.any((t) => t.toLowerCase() == 'mtb'))
        .toList();
    expect(mtb.length, greaterThanOrEqualTo(17));
    for (final l in mtb) {
      // Trail chip (soft-match gravel) — primary surface should be trail/root.
      expect(
        l.surfaceTag,
        contains('trail'),
        reason: '${l.id} surfaceTag=${l.surfaceTag}',
      );
      expect(l.hasBakedGeometry, isTrue, reason: l.id);
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

  test('Rhein-Neckar Nähe fallback keeps why_good', () {
    final raw = _readFirstExisting([
      'assets/seeds/p0-rhein-neckar-60min-naehe-v1.json',
      'mobile/assets/seeds/p0-rhein-neckar-60min-naehe-v1.json',
      '../assets/seeds/p0-rhein-neckar-60min-naehe-v1.json',
    ], label: 'Rhein-Neckar Nähe fallback');
    final rn = NaeheSeedsBundle.parse(raw);
    expect(rn.loops, isNotEmpty);
    for (final l in rn.loops) {
      expect(l.poiStops.any((p) => p.whyGood != null), isTrue, reason: l.id);
    }
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

  test('organic loop is closed and not a perfect circle', () {
    final track = organicLoopLngLat(
      lat: 52.473,
      lng: 13.405,
      distanceKm: 12,
      seedKey: 'seed-loop-tempelhofer-60',
    );
    expect(track.length, greaterThan(8));
    expect(routeShapeOf(track), RouteShape.loop);
    // Radii from center vary — not a synthetic circle.
    final midLat = 52.473;
    final midLng = 13.405;
    final radii = <double>[];
    for (final p in track.take(track.length - 1)) {
      final dLat = (p[1] - midLat) * 111.0;
      final dLng = (p[0] - midLng) * 111.0 * 0.6;
      radii.add(math.sqrt(dLat * dLat + dLng * dLng));
    }
    final minR = radii.reduce(math.min);
    final maxR = radii.reduce(math.max);
    expect(maxR / minR, greaterThan(1.08));
  });

  test('baked geometry preferred over synthetic for DACH/Berlin/France loops', () {
    String? franceRaw;
    for (final p in [
      'assets/seeds/p0-france-60min-naehe-v1.json',
      'mobile/assets/seeds/p0-france-60min-naehe-v1.json',
      '../assets/seeds/p0-france-60min-naehe-v1.json',
    ]) {
      final f = File(p);
      if (f.existsSync()) {
        franceRaw = f.readAsStringSync();
        break;
      }
    }
    expect(franceRaw, isNotNull, reason: 'France seed asset required');
    final berlin = NaeheSeedsBundle.parse(berlinRaw);
    final dach = NaeheSeedsBundle.parse(dachRaw);
    final france = NaeheSeedsBundle.parse(franceRaw!);
    for (final bundle in [berlin, dach, france]) {
      for (final loop in bundle.loops) {
        expect(
          loop.hasBakedGeometry,
          isTrue,
          reason: '${loop.id} should ship street geometry',
        );
        expect(loop.trackLngLat!.length, greaterThanOrEqualTo(4));
        expect(loop.geometryEngine, contains('osrm'));
        expect(routeShapeOf(loop.trackLngLat), RouteShape.loop);
      }
    }
  });

  test('parseSeedGeometryLngLat accepts GeoJSON lng/lat pairs', () {
    final g = parseSeedGeometryLngLat([
      [13.4, 52.47],
      [13.41, 52.48],
      [13.39, 52.49],
      [13.38, 52.47],
      [13.4, 52.47],
    ]);
    expect(g, isNotNull);
    expect(g!.length, greaterThanOrEqualTo(4));
    expect(g.first[0], closeTo(13.4, 1e-6));
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

  test('heroAssetForSeedId keeps explicit RN/Berlin maps', () {
    expect(
      heroAssetForSeedId('seed-loop-tempelhofer-60'),
      'assets/seeds/heroes/berlin-tempelhofer.jpg',
    );
    expect(
      heroAssetForSeedId('seed-loop-heidelberg-neckar-60'),
      'assets/seeds/heroes/rn-heidelberg.jpg',
    );
  });

  test('heroAssetForSeedId keywords do not match see inside seed', () {
    expect(heroAssetForSeedId(''), isNull);
    expect(
      heroAssetForSeedId('seed-loop-innsbruck-alpen-60'),
      'assets/seeds/heroes/wm-innsbruck.jpg',
    );
    expect(
      heroAssetForSeedId('seed-loop-bodensee-hafen-60'),
      'assets/seeds/heroes/wm-bodensee.jpg',
    );
    expect(
      heroAssetForSeedId('seed-loop-somewhere-mtb-trail-60'),
      'assets/seeds/heroes/forest.jpg',
    );
    final generic = heroAssetForSeedId('seed-loop-somewhere-60');
    expect(generic, isNotNull);
    expect(kTourHeroAssetPool, contains(generic));
    // Substring "see" in "seed" must not force every tour onto the lake hero.
    final hashed = [
      for (var i = 0; i < 24; i++) heroAssetForSeedId('seed-loop-$i'),
    ];
    expect(hashed.toSet().length, greaterThan(1));
    expect(
      hashed.every((e) => e == 'assets/seeds/heroes/lake.jpg'),
      isFalse,
    );
  });

  test('Alpen/Ostsee Lücken pack covers thin regions', () {
    final gaps = NaeheSeedsBundle.parse(gapsRaw);
    final ids = gaps.loops.map((e) => e.id).toSet();
    expect(
      ids,
      containsAll([
        'seed-loop-berlin-mueggelberge-mtb-60',
        'seed-loop-kiel-roenner-gehege-mtb-60',
        'seed-loop-rostock-heide-mtb-60',
        'seed-loop-luebeck-lauerholz-mtb-60',
        'seed-loop-ruegen-granitz-gravel-60',
        'seed-loop-innsbruck-inn-road-60',
        'seed-loop-innsbruck-igls-gravel-60',
        'seed-loop-garmisch-wank-mtb-60',
        'seed-loop-zermatt-zmutt-mtb-60',
        'seed-loop-zermatt-furi-gravel-60',
        'seed-loop-interlaken-harderwald-mtb-60',
        'seed-loop-chur-calanda-mtb-60',
        'seed-loop-st-moritz-stazerwald-mtb-60',
        'seed-loop-davos-forest-mtb-60',
        'seed-loop-soelden-oetztal-mtb-60',
        'seed-loop-kitzbuehel-hahnenkamm-mtb-60',
        'seed-loop-zurich-kaeferberg-mtb-60',
        'seed-loop-salzburg-gaisberg-gravel-60',
        'seed-loop-chur-rheinauen-gravel-60',
        'seed-loop-zermatt-dorf-road-60',
      ]),
    );
    for (final l in gaps.loops) {
      expect(l.isLoop, isTrue, reason: l.id);
      expect(l.durationBand, '60', reason: l.id);
      expect(l.durationMin, inInclusiveRange(45, 75), reason: l.id);
      expect(l.poiStops, isNotEmpty, reason: l.id);
      expect(l.hasBakedGeometry, isTrue, reason: l.id);
      expect(routeShapeOf(l.trackLngLat), RouteShape.loop, reason: l.id);
    }
    final mtb = gaps.loops
        .where((l) => l.sportTags.any((t) => t.toLowerCase() == 'mtb'))
        .toList();
    expect(mtb.length, greaterThanOrEqualTo(10));
    for (final l in mtb) {
      expect(
        l.surfaceTag,
        contains('trail'),
        reason: '${l.id} surfaceTag=${l.surfaceTag}',
      );
    }
  });

  test('Kiel/Zermatt stay regional after gaps merge — no Hamburg/Bern fill', () {
    final merged = NaeheSeedsBundle.merge(
      NaeheSeedsBundle.merge(
        NaeheSeedsBundle.parse(berlinRaw),
        NaeheSeedsBundle.parse(dachRaw),
      ),
      NaeheSeedsBundle.parse(gapsRaw),
    );
    double distKm(double lat, double lng, NaeheSeedRoute r) {
      const earth = 6371.0;
      final p1 = lat * math.pi / 180;
      final p2 = r.centerLat * math.pi / 180;
      final dLat = (r.centerLat - lat) * math.pi / 180;
      final dLng = (r.centerLng - lng) * math.pi / 180;
      final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(p1) *
              math.cos(p2) *
              math.sin(dLng / 2) *
              math.sin(dLng / 2);
      return 2 * earth * math.asin(math.sqrt(a));
    }

    final kiel = TourCoverage.pickNearbyThenFill(
      items: merged.loops,
      distanceKm: (r) => distKm(54.323, 10.139, r),
    );
    expect(kiel, isNotEmpty);
    expect(kiel.every((r) => distKm(54.323, 10.139, r) <= 90), isTrue);
    expect(kiel.map((r) => r.id), isNot(contains('seed-loop-hamburg-harburg-mtb-60')));
    expect(
      kiel.map((r) => r.id),
      containsAll([
        'seed-loop-kiel-foerde-60',
        'seed-loop-kiel-roenner-gehege-mtb-60',
      ]),
    );

    final zermatt = TourCoverage.pickNearbyThenFill(
      items: merged.loops,
      distanceKm: (r) => distKm(46.021, 7.749, r),
    );
    expect(zermatt, isNotEmpty);
    expect(zermatt.every((r) => distKm(46.021, 7.749, r) <= 90), isTrue);
    expect(
      zermatt.map((r) => r.id),
      isNot(contains('seed-loop-bern-bremgarten-mtb-60')),
    );
    expect(
      zermatt.map((r) => r.id),
      contains('seed-loop-zermatt-zmutt-mtb-60'),
    );
  });

  test('GPS Wien/München/Zürich/Hamburg do not rank Heidelberg first', () {
    final berlin = NaeheSeedsBundle.parse(berlinRaw);
    final dach = NaeheSeedsBundle.parse(dachRaw);
    final merged = NaeheSeedsBundle.merge(berlin, dach);
    double distKm(double lat, double lng, NaeheSeedRoute r) {
      final dLat = (r.centerLat - lat) * 111.0;
      final dLng = (r.centerLng - lng) * 111.0 * 0.7;
      return math.sqrt(dLat * dLat + dLng * dLng);
    }

    bool looksHd(NaeheSeedRoute r) {
      final t = '${r.id} ${r.title}'.toLowerCase();
      return t.contains('heidelberg') || t.contains('neckarwiese');
    }

    for (final city in [
      (name: 'Wien', lat: 48.208, lng: 16.373, needles: ['wien', 'vienna']),
      (name: 'München', lat: 48.137, lng: 11.575, needles: ['munich', 'muenchen']),
      (name: 'Zürich', lat: 47.376, lng: 8.541, needles: ['zurich', 'zuerich']),
      (name: 'Hamburg', lat: 53.551, lng: 9.993, needles: ['hamburg']),
    ]) {
      final picked = TourCoverage.pickNearbyThenFill(
        items: merged.loops,
        distanceKm: (r) => distKm(city.lat, city.lng, r),
      );
      expect(picked, isNotEmpty, reason: city.name);
      expect(looksHd(picked.first), isFalse, reason: '${city.name} first=${picked.first.id}');
      final id = picked.first.id.toLowerCase();
      expect(
        city.needles.any(id.contains),
        isTrue,
        reason: '${city.name} first=${picked.first.id}',
      );
    }
  });
}
