import 'package:aetherride_mobile/data/routing/naehe_seeds.dart';
import 'package:aetherride_mobile/domain/home/hof_gate.dart';
import 'package:aetherride_mobile/domain/home/hof_title.dart';
import 'package:aetherride_mobile/domain/ride.dart';
import 'package:aetherride_mobile/domain/saved_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('hofTitleFor', () {
    test('DE / AT → Der Hof', () {
      expect(hofTitleFor(countryCode: 'DE', languageCode: 'de'), 'Der Hof');
      expect(hofTitleFor(countryCode: 'AT', languageCode: 'de'), 'Der Hof');
    });

    test('English in Germany → Der Hof (country, not UI language)', () {
      expect(hofTitleFor(countryCode: 'DE', languageCode: 'en'), 'Der Hof');
    });

    test('German in Zürich → Velokeller', () {
      expect(hofTitleFor(countryCode: 'CH', languageCode: 'de'), 'Velokeller');
    });

    test('CH language regions', () {
      expect(hofTitleFor(countryCode: 'CH', languageCode: 'fr'), 'Le local vélo');
      expect(hofTitleFor(countryCode: 'CH', languageCode: 'it'), 'La rimessa');
      expect(hofTitleFor(countryCode: 'CH', languageCode: 'en'), 'Velokeller');
    });

    test('FR / IT / EN countries', () {
      expect(hofTitleFor(countryCode: 'FR', languageCode: 'fr'), 'La remise');
      expect(hofTitleFor(countryCode: 'IT', languageCode: 'it'), 'La rimessa');
      expect(hofTitleFor(countryCode: 'US', languageCode: 'en'), 'The Stand');
      expect(hofTitleFor(countryCode: 'GB', languageCode: 'en'), 'The Stand');
    });

    test('German UI in the US → The Stand', () {
      expect(hofTitleFor(countryCode: 'US', languageCode: 'de'), 'The Stand');
    });

    test('DE default when country missing', () {
      expect(hofTitleFor(languageCode: 'de'), 'Der Hof');
      expect(hofTitleFor(languageCode: 'en'), 'The Stand');
    });
  });

  group('countryFromSeedId', () {
    test('maps DACH cities', () {
      expect(countryFromSeedId('seed-loop-zurich-seefeld-60'), 'CH');
      expect(countryFromSeedId('seed-loop-vienna-prater-60'), 'AT');
      expect(countryFromSeedId('seed-loop-hamburg-alster-60'), 'DE');
      expect(countryFromSeedId('seed-loop-konstanz-mainau-60'), 'DE');
      expect(countryFromSeedId('seed-loop-paris-vincennes-60'), 'FR');
    });
  });

  group('pickHofGate', () {
    NaeheSeedRoute loop({
      required String id,
      required double lat,
      required double lng,
      int durationMin = 58,
      String surface = 'asphalt/paved',
    }) {
      return NaeheSeedRoute(
        id: id,
        title: id,
        distanceKm: 18,
        ascentM: 120,
        durationMin: durationMin,
        effortLabel: 'Mittel',
        sportTags: const ['urban'],
        centerLat: lat,
        centerLng: lng,
        isLoop: true,
        surfaceMixText: surface,
      );
    }

    test('Hamburg GPS does not pick Innsbruck', () {
      final pick = pickHofGate(
        loops: [
          loop(
            id: 'seed-loop-hamburg-alster-60',
            lat: 53.57,
            lng: 10.0,
          ),
          loop(
            id: 'seed-loop-innsbruck-hungerburg-60',
            lat: 47.28,
            lng: 11.4,
            surface: 'trail/root',
          ),
        ],
        lat: 53.55,
        lng: 9.99,
      );
      expect(pick.honesty, HofGateHonesty.loop);
      expect(pick.seed?.id, 'seed-loop-hamburg-alster-60');
    });

    test('without GPS seeds are skipped (no RN default)', () {
      final pick = pickHofGate(
        loops: [
          loop(
            id: 'seed-loop-heidelberg-neckar-60',
            lat: 49.41,
            lng: 8.68,
          ),
        ],
      );
      expect(pick.hasLoop, isFalse);
      expect(pick.honesty, HofGateHonesty.none);
    });

    test('wet trails refuse a muddy loop', () {
      final pick = pickHofGate(
        loops: [
          loop(
            id: 'seed-loop-zurich-uetliberg-mtb-60',
            lat: 47.35,
            lng: 8.52,
            surface: 'trail/root',
          ),
        ],
        lat: 47.37,
        lng: 8.54,
        trailsWet: true,
      );
      expect(pick.hasLoop, isFalse);
      expect(pick.honesty, HofGateHonesty.wetClosed);
    });

    test('saved route fills the gate when no nearby seed', () {
      final pick = pickHofGate(
        loops: const [],
        saved: [
          SavedRouteEntry(
            id: 'saved-1',
            name: 'Feierabend',
            distanceKm: 18,
            elevationM: 80,
            durationMin: 55,
            savedAt: DateTime(2026, 8, 1),
          ),
        ],
      );
      expect(pick.saved?.id, 'saved-1');
      expect(pick.honesty, HofGateHonesty.loop);
    });
  });

  group('rideReturnForBike', () {
    test('no ride is neverOut, not 0 km', () {
      final r = rideReturnForBike(bikeId: 'b1', rides: const []);
      expect(r.kind, RideReturnKind.neverOut);
      expect(r.hidesGate, isFalse);
    });

    test('recent finished ride is just back', () {
      final now = DateTime(2026, 8, 12, 20);
      final r = rideReturnForBike(
        bikeId: 'b1',
        now: now,
        rides: [
          RideRecord(
            id: 'r1',
            bikeId: 'b1',
            startedAt: now.subtract(const Duration(hours: 2)),
            endedAt: now.subtract(const Duration(minutes: 20)),
            distanceKm: 18.2,
            movingTimeSec: 72 * 60,
          ),
        ],
      );
      expect(r.kind, RideReturnKind.justBack);
      expect(r.hidesGate, isTrue);
      expect(r.distanceKm, 18.2);
      expect(r.usedGps, isFalse);
    });

    test('summary usingGps true is recorded on return', () {
      final now = DateTime(2026, 8, 12, 20);
      final r = rideReturnForBike(
        bikeId: 'b1',
        now: now,
        rides: [
          RideRecord(
            id: 'r1',
            bikeId: 'b1',
            startedAt: now.subtract(const Duration(hours: 1)),
            endedAt: now.subtract(const Duration(minutes: 5)),
            distanceKm: 4.2,
            movingTimeSec: 20 * 60,
            summary: const {'usingGps': true},
          ),
        ],
      );
      expect(r.kind, RideReturnKind.justBack);
      expect(r.usedGps, isTrue);
    });
  });
}
