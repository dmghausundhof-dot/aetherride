import 'package:aetherride_mobile/data/routing/naehe_seeds.dart';
import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/home/hof_gate.dart';
import 'package:aetherride_mobile/domain/home/hof_pack.dart';
import 'package:aetherride_mobile/domain/home/hof_title.dart';
import 'package:aetherride_mobile/domain/ride.dart';
import 'package:aetherride_mobile/domain/saved_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('hofTitleFor', () {
    test('language, not country', () {
      expect(hofTitleFor(countryCode: 'DE', languageCode: 'de'), 'Start');
      expect(hofTitleFor(countryCode: 'AT', languageCode: 'de'), 'Start');
      expect(hofTitleFor(countryCode: 'CH', languageCode: 'de'), 'Start');
      expect(hofTitleFor(countryCode: 'US', languageCode: 'de'), 'Start');
      expect(hofTitleFor(languageCode: 'de'), 'Start');
    });

    test('English chrome → Start', () {
      expect(hofTitleFor(countryCode: 'DE', languageCode: 'en'), 'Start');
      expect(hofTitleFor(countryCode: 'US', languageCode: 'en'), 'Start');
      expect(hofTitleFor(languageCode: 'en'), 'Start');
    });

    test('French / Italian / Dutch', () {
      expect(hofTitleFor(countryCode: 'CH', languageCode: 'fr'), 'Accueil');
      expect(hofTitleFor(countryCode: 'FR', languageCode: 'fr'), 'Accueil');
      expect(hofTitleFor(countryCode: 'CH', languageCode: 'it'), 'Inizio');
      expect(hofTitleFor(countryCode: 'IT', languageCode: 'it'), 'Inizio');
      expect(hofTitleFor(countryCode: 'NL', languageCode: 'nl'), 'Start');
      expect(hofTitleFor(countryCode: 'BE', languageCode: 'nl'), 'Start');
    });
  });

  group('countryFromSeedId', () {
    test('maps DACH cities', () {
      expect(countryFromSeedId('seed-loop-zurich-seefeld-60'), 'CH');
      expect(countryFromSeedId('seed-loop-vienna-prater-60'), 'AT');
      expect(countryFromSeedId('seed-loop-hamburg-alster-60'), 'DE');
      expect(countryFromSeedId('seed-loop-konstanz-mainau-60'), 'DE');
      expect(countryFromSeedId('seed-loop-paris-vincennes-60'), 'FR');
      expect(countryFromSeedId('seed-loop-zermatt-zmutt-mtb-60'), 'CH');
      expect(countryFromSeedId('seed-loop-soelden-oetztal-mtb-60'), 'AT');
      expect(countryFromSeedId('seed-loop-garmisch-wank-mtb-60'), 'DE');
      expect(countryFromSeedId('seed-loop-luebeck-lauerholz-mtb-60'), 'DE');
    });
  });

  group('pickHofGate', () {
    NaeheSeedRoute loop({
      required String id,
      required double lat,
      required double lng,
      int durationMin = 58,
      String surface = 'asphalt/paved',
      List<String> sportTags = const ['urban'],
    }) {
      return NaeheSeedRoute(
        id: id,
        title: id,
        distanceKm: 18,
        ascentM: 120,
        durationMin: durationMin,
        effortLabel: 'Mittel',
        sportTags: sportTags,
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
      expect(
        hofGateEmptyTitle(
          honesty: pick.honesty,
          wetClosed:
              'Trails nass — kein ehrlicher Asphalt-Rundkurs in der Nähe',
          noLoop: 'Kein ehrlicher Trail-Rundkurs',
        ),
        'Trails nass — kein ehrlicher Asphalt-Rundkurs in der Nähe',
      );
    });

    test('preferred MTB picks a trail over nearer asphalt', () {
      final pick = pickHofGate(
        loops: [
          loop(
            id: 'seed-loop-innsbruck-inn-road-60',
            lat: 47.27,
            lng: 11.40,
            sportTags: const ['road'],
          ),
          loop(
            id: 'seed-loop-innsbruck-nordkette-mtb-60',
            lat: 47.29,
            lng: 11.41,
            surface: 'trail/root',
            sportTags: const ['mtb'],
          ),
        ],
        lat: 47.269,
        lng: 11.404,
        preferred: BikeCategory.mtbAm,
      );
      expect(pick.seed?.id, 'seed-loop-innsbruck-nordkette-mtb-60');
    });

    test('preferred road picks asphalt when a trail is nearer', () {
      final pick = pickHofGate(
        loops: [
          loop(
            id: 'seed-loop-innsbruck-nordkette-mtb-60',
            lat: 47.28,
            lng: 11.40,
            surface: 'trail/root',
            sportTags: const ['mtb'],
          ),
          loop(
            id: 'seed-loop-innsbruck-inn-road-60',
            lat: 47.26,
            lng: 11.39,
            sportTags: const ['road'],
          ),
        ],
        lat: 47.269,
        lng: 11.404,
        preferred: BikeCategory.road,
      );
      expect(pick.seed?.id, 'seed-loop-innsbruck-inn-road-60');
    });

    test('loop beyond 15 km is not the hour at the gate', () {
      final pick = pickHofGate(
        loops: [
          loop(
            id: 'seed-loop-far-43',
            lat: 53.55,
            lng: 10.65,
          ),
        ],
        lat: 53.55,
        lng: 9.99,
      );
      expect(pick.hasLoop, isFalse);
      expect(pick.honesty, HofGateHonesty.none);
    });

    test('loop under 15 km stays at the gate', () {
      final pick = pickHofGate(
        loops: [
          loop(
            id: 'seed-loop-near-11',
            lat: 53.55,
            lng: 10.12,
          ),
        ],
        lat: 53.55,
        lng: 9.99,
      );
      expect(pick.hasLoop, isTrue);
      expect(pick.seed?.id, 'seed-loop-near-11');
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
      expect(r.rideId, 'r1');
      expect(r.usedGps, isFalse);
    });

    test('stub ride under 1 km does not hide the gate', () {
      final now = DateTime(2026, 8, 12, 20);
      final r = rideReturnForBike(
        bikeId: 'b1',
        now: now,
        rides: [
          RideRecord(
            id: 'r-stub',
            bikeId: 'b1',
            startedAt: now.subtract(const Duration(minutes: 5)),
            endedAt: now.subtract(const Duration(minutes: 4)),
            distanceKm: 0.2,
            movingTimeSec: 60,
          ),
        ],
      );
      expect(r.kind, RideReturnKind.atHof);
      expect(r.hidesGate, isFalse);
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

    test('justBack without GPS hides 0 km', () {
      const ret = RideReturn(
        kind: RideReturnKind.justBack,
        rideId: 'r0',
        distanceKm: 0,
        movingTimeSec: 0,
      );
      expect(
        formatHofResidentMeta(
          ret: ret,
          sport: 'E-MTB',
          justBackLabel: 'gerade reingekommen',
          atHofLabel: 'am Hof',
          notYetOutLabel: 'noch nicht draußen',
          sinceOneDay: 'seit 1 Tag',
          sinceDays: (d) => 'seit $d Tagen',
          noGpsLabel: 'ohne GPS-Track — kein erfundener Verlauf',
        ),
        'gerade reingekommen · ohne GPS-Track — kein erfundener Verlauf',
      );
    });

    test('justBack includes ago when given', () {
      const ret = RideReturn(
        kind: RideReturnKind.justBack,
        rideId: 'r0',
        distanceKm: 0,
        movingTimeSec: 0,
      );
      expect(
        formatHofResidentMeta(
          ret: ret,
          sport: 'E-MTB',
          justBackLabel: 'gerade reingekommen',
          atHofLabel: 'am Hof',
          notYetOutLabel: 'noch nicht draußen',
          sinceOneDay: 'seit 1 Tag',
          sinceDays: (d) => 'seit $d Tagen',
          noGpsLabel: 'ohne GPS-Track — kein erfundener Verlauf',
          ago: const HofAgo('vor 12 min', underHour: true),
        ),
        'gerade reingekommen · vor 12 min · ohne GPS-Track — kein erfundener Verlauf',
      );
    });

    test('justBack after an hour drops gerade', () {
      const ret = RideReturn(
        kind: RideReturnKind.justBack,
        rideId: 'r0',
        distanceKm: 0,
        movingTimeSec: 0,
      );
      expect(
        formatHofResidentMeta(
          ret: ret,
          sport: 'E-MTB',
          justBackLabel: 'gerade reingekommen',
          atHofLabel: 'am Hof',
          notYetOutLabel: 'noch nicht draußen',
          sinceOneDay: 'seit 1 Tag',
          sinceDays: (d) => 'seit $d Tagen',
          noGpsLabel: 'ohne GPS-Track — kein erfundener Verlauf',
          ago: const HofAgo('vor 3 Std.', underHour: false),
        ),
        'vor 3 Std. · ohne GPS-Track — kein erfundener Verlauf',
      );
    });

    test('atHof under a day uses hours, not seit 1 Tag', () {
      const ret = RideReturn(
        kind: RideReturnKind.atHof,
        rideId: 'r0',
        daysSince: 1,
      );
      expect(
        formatHofResidentMeta(
          ret: ret,
          sport: 'MTB',
          justBackLabel: 'gerade reingekommen',
          atHofLabel: 'am Hof',
          notYetOutLabel: 'noch nicht draußen',
          sinceOneDay: 'seit 1 Tag',
          sinceDays: (d) => 'seit $d Tagen',
          noGpsLabel: 'ohne GPS-Track — kein erfundener Verlauf',
          ago: const HofAgo('vor 4 Std.', underHour: false),
        ),
        'MTB · am Hof · vor 4 Std. · ohne GPS-Track — kein erfundener Verlauf',
      );
      expect(
        formatHofResidentMeta(
          ret: ret,
          sport: 'Enduro',
          garageTypeLabel: 'Typ Enduro',
          justBackLabel: 'gerade reingekommen',
          atHofLabel: 'am Hof',
          notYetOutLabel: 'noch nicht draußen',
          sinceOneDay: 'seit 1 Tag',
          sinceDays: (d) => 'seit $d Tagen',
          noGpsLabel: 'ohne GPS-Track — kein erfundener Verlauf',
        ),
        'Typ Enduro · am Hof · seit 1 Tag · ohne GPS-Track — kein erfundener Verlauf',
      );
    });

    test('justBack with GPS keeps km', () {
      const ret = RideReturn(
        kind: RideReturnKind.justBack,
        rideId: 'r1',
        distanceKm: 18.2,
        movingTimeSec: 72 * 60,
        usedGps: true,
      );
      expect(
        formatHofResidentMeta(
          ret: ret,
          sport: 'E-MTB',
          justBackLabel: 'gerade reingekommen',
          atHofLabel: 'am Hof',
          notYetOutLabel: 'noch nicht draußen',
          sinceOneDay: 'seit 1 Tag',
          sinceDays: (d) => 'seit $d Tagen',
          noGpsLabel: 'ohne GPS-Track — kein erfundener Verlauf',
        ),
        'gerade reingekommen · 18.2 km · 1:12',
      );
    });
  });

  group('hofAgoLabel', () {
    final now = DateTime(2026, 8, 15, 15);

    test('under an hour uses minutes', () {
      expect(
        hofAgoLabel(
          endedAt: now.subtract(const Duration(minutes: 12)),
          now: now,
          minutes: (m) => 'vor $m min',
          hours: (h) => 'vor $h Std.',
        )?.label,
        'vor 12 min',
      );
    });

    test('under a day uses hours, not days', () {
      expect(
        hofAgoLabel(
          endedAt: now.subtract(const Duration(hours: 4)),
          now: now,
          minutes: (m) => 'vor $m min',
          hours: (h) => 'vor $h Std.',
        )?.label,
        'vor 4 Std.',
      );
    });

    test('after 24 hours falls back to days', () {
      expect(
        hofAgoLabel(
          endedAt: now.subtract(const Duration(hours: 25)),
          now: now,
          minutes: (m) => 'vor $m min',
          hours: (h) => 'vor $h Std.',
        ),
        isNull,
      );
    });
  });

  group('hofResidentSport', () {
    const lacuba = Bike(
      id: 'lacuba',
      name: 'Bulls Lacuba EVO 10',
      category: BikeCategory.mtbAm,
    );

    test('MTB stays MTB without motor or flag', () {
      expect(hofResidentSport(lacuba), 'MTB');
    });

    test('motor in the workshop is E-MTB, without inventing the flag', () {
      expect(hofResidentSport(lacuba, hasMotor: true), 'E-MTB');
      expect(lacuba.isEbike, isFalse);
    });
  });

  group('hofMissingPack', () {
    test('unknown region stays quiet', () {
      expect(
        hofMissingPack(regionId: null, regionName: null, packReady: false),
        isNull,
      );
    });

    test('ready pack is not a Hof line', () {
      expect(
        hofMissingPack(
          regionId: 'karlsruhe',
          regionName: 'Karlsruhe / Hardt',
          packReady: true,
        ),
        isNull,
      );
    });

    test('missing pack names the region', () {
      final hint = hofMissingPack(
        regionId: 'karlsruhe',
        regionName: 'Karlsruhe / Hardt',
        packReady: false,
      );
      expect(hint?.regionId, 'karlsruhe');
      expect(hint?.regionName, 'Karlsruhe / Hardt');
    });

    test('envelope stubs stay quiet', () {
      expect(
        hofMissingPack(
          regionId: 'de-bayern',
          regionName: 'Bayern',
          packReady: false,
          isEnvelope: true,
        ),
        isNull,
      );
    });
  });

  group('hofHintForLocation', () {
    test('overlay city wins over a larger catalog pack', () {
      final hint = hofHintForLocation(
        overlayId: 'karlsruhe',
        overlayName: 'Karlsruhe / Hardt',
        overlayIsEnvelope: false,
        suggestedId: 'karlsruhe',
        suggestedName: 'Karlsruhe / Hardt',
        packReady: false,
      );
      expect(hint?.regionId, 'karlsruhe');
    });

    test('ready catalog pack wins over an overlay stub', () {
      final hint = hofHintForLocation(
        overlayId: 'karlsruhe',
        overlayName: 'Karlsruhe / Hardt',
        overlayIsEnvelope: false,
        suggestedId: 'rhein-neckar',
        suggestedName: 'Rhein-Neckar / Heidelberg',
        packReady: false,
      );
      expect(hint?.regionId, 'rhein-neckar');
    });

    test('overlay city is used when catalog has no suggestion', () {
      final hint = hofHintForLocation(
        overlayId: 'karlsruhe',
        overlayName: 'Karlsruhe / Hardt',
        overlayIsEnvelope: false,
        suggestedId: null,
        suggestedName: null,
        packReady: false,
      );
      expect(hint?.regionId, 'karlsruhe');
    });

    test('rural GPS uses the smallest ready catalog pack', () {
      final hint = hofHintForLocation(
        overlayId: null,
        overlayName: null,
        overlayIsEnvelope: false,
        suggestedId: 'de-saarland',
        suggestedName: 'Saarland',
        packReady: false,
      );
      expect(hint?.regionId, 'de-saarland');
      expect(hint?.regionName, 'Saarland');
    });

    test('envelope overlay falls through to a ready catalog pack', () {
      final hint = hofHintForLocation(
        overlayId: 'de-bayern',
        overlayName: 'Bayern',
        overlayIsEnvelope: true,
        suggestedId: 'muenchen',
        suggestedName: 'München & Umland',
        packReady: false,
      );
      expect(hint?.regionId, 'muenchen');
    });

    test('ready pack stays quiet without a name', () {
      expect(
        hofHintForLocation(
          overlayId: 'karlsruhe',
          overlayName: 'Karlsruhe / Hardt',
          overlayIsEnvelope: false,
          suggestedId: 'de-saarland',
          suggestedName: 'Saarland',
          packReady: true,
        ),
        isNull,
      );
    });

    test('ready pack with a name is status, not a download', () {
      final hint = hofHintForLocation(
        overlayId: 'karlsruhe',
        overlayName: 'Karlsruhe / Hardt',
        overlayIsEnvelope: false,
        suggestedId: 'de-saarland',
        suggestedName: 'Saarland',
        packReady: true,
        readyId: 'karlsruhe',
        readyName: 'Karlsruhe / Hardt',
      );
      expect(hint?.ready, isTrue);
      expect(hint?.regionId, 'karlsruhe');
      expect(hint?.regionName, 'Karlsruhe / Hardt');
    });
  });

  group('formatHofGateAway', () {
    test('unknown or zero stays quiet', () {
      expect(
        formatHofGateAway(
          distanceKm: null,
          underOne: 'unter 1 km',
          km: (n) => '$n km',
        ),
        isNull,
      );
      expect(
        formatHofGateAway(
          distanceKm: 0,
          underOne: 'unter 1 km',
          km: (n) => '$n km',
        ),
        isNull,
      );
    });

    test('under a kilometre is honest, not 0 km', () {
      expect(
        formatHofGateAway(
          distanceKm: 0.4,
          underOne: 'unter 1 km',
          km: (n) => '$n km',
        ),
        'unter 1 km',
      );
    });

    test('GPS distance to the loop, not loop length', () {
      expect(
        formatHofGateAway(
          distanceKm: 6.4,
          underOne: 'unter 1 km',
          km: (n) => '$n km',
        ),
        '6 km',
      );
    });
  });
}
