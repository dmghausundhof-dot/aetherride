import 'dart:io';
import 'dart:math' as math;

import 'package:aetherride_mobile/data/routing/naehe_seeds.dart';
import 'package:flutter_test/flutter_test.dart';

String _read(String rel) {
  for (final p in [rel, 'mobile/$rel', '../$rel']) {
    final f = File(p);
    if (f.existsSync()) return f.readAsStringSync();
  }
  fail('missing $rel');
}

double _hav(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * r * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
}

void main() {
  test('Wiesloch ~60 Rundkurs: ≥3 loop seeds with hero thumbnails', () {
    final berlin = NaeheSeedsBundle.parse(
      _read('assets/seeds/naehe-peek-seeds-berlin-v1.json'),
    );
    final dach = NaeheSeedsBundle.parse(
      _read('assets/seeds/p0-dach-60min-naehe-v1.json'),
    );
    final premium = NaeheSeedsBundle.parse(
      _read('assets/seeds/p0-rhein-neckar-60min-premium-v1.json'),
    );
    final merged = NaeheSeedsBundle.merge(
      NaeheSeedsBundle.merge(berlin, dach),
      premium,
    );

    const wLat = 49.295;
    const wLng = 8.698;
    final nearby = merged.loops.where((r) {
      if (r.durationMin < 45 || r.durationMin > 75) return false;
      return _hav(wLat, wLng, r.centerLat, r.centerLng) <= 35;
    }).toList();

    expect(nearby.length, greaterThanOrEqualTo(3));
    for (final r in nearby) {
      expect(r.isLoop, isTrue);
      final thumb = r.thumbnailUrl ?? heroAssetForSeedId(r.id);
      expect(thumb, isNotNull, reason: '${r.id} needs hero');
      expect(thumb!.startsWith('assets/seeds/heroes/'), isTrue);
      expect(File('mobile/$thumb').existsSync() || File(thumb).existsSync(),
          isTrue,
          reason: 'hero file missing for ${r.id}: $thumb');
    }
  });

  test('Tempelhofer start=1 seed still in Berlin bundle (#23)', () {
    final berlin = NaeheSeedsBundle.parse(
      _read('assets/seeds/naehe-peek-seeds-berlin-v1.json'),
    );
    final seed = berlin.byId('seed-loop-tempelhofer-60');
    expect(seed, isNotNull);
    expect(seed!.isLoop, isTrue);
    final ar = seed.toActiveRoute();
    expect(ar.coordinates.length, greaterThanOrEqualTo(4));
    expect(ar.id, 'seed-loop-tempelhofer-60');
  });

  test('linear Spree excluded from loops; premium heroes present', () {
    final berlin = NaeheSeedsBundle.parse(
      _read('assets/seeds/naehe-peek-seeds-berlin-v1.json'),
    );
    expect(
      berlin.loops.any((r) => r.id == 'seed-route-spree-commute'),
      isFalse,
    );
    final premium = NaeheSeedsBundle.parse(
      _read('assets/seeds/p0-rhein-neckar-60min-premium-v1.json'),
    );
    expect(premium.loops.length, greaterThanOrEqualTo(3));
    expect(
      premium.loops.every(
        (r) => (r.thumbnailUrl ?? heroAssetForSeedId(r.id)) != null,
      ),
      isTrue,
    );
  });
}
