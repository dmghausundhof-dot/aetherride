import 'package:aetherride_mobile/data/local/user_profile_store.dart';
import 'package:aetherride_mobile/data/routing/routing_client.dart';
import 'package:aetherride_mobile/data/sync/sync_payload.dart';
import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/sport/discipline_ux.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfileStore preferred sports', () {
    test('legacy load: only preferredSport fills the list', () {
      final store = UserProfileStore();
      store.applyPreferredFromJson({'preferredSport': 'mtbAm'});
      expect(store.preferredSport, BikeCategory.mtbAm);
      expect(store.preferredSports, [BikeCategory.mtbAm]);
    });

    test('load both fields keeps haupt first and in the list', () {
      final store = UserProfileStore();
      store.applyPreferredFromJson({
        'preferredSport': 'road',
        'preferredSports': ['gravel', 'road', 'urban'],
      });
      expect(store.preferredSport, BikeCategory.road);
      expect(store.preferredSports, contains(BikeCategory.road));
      expect(store.preferredSports.first, BikeCategory.road);
      expect(
          store.preferredSports,
          containsAll([
            BikeCategory.gravel,
            BikeCategory.urban,
          ]));
    });

    test('legacy missing list with null haupt stays empty', () {
      final store = UserProfileStore();
      store.applyPreferredFromJson({});
      expect(store.preferredSport, isNull);
      expect(store.preferredSports, isEmpty);
    });

    test('toggle adds and cannot remove the last', () {
      final store = UserProfileStore();
      expect(store.togglePreferredSport(BikeCategory.mtbAm), isTrue);
      expect(store.preferredSport, BikeCategory.mtbAm);
      expect(store.preferredSports, [BikeCategory.mtbAm]);

      expect(store.togglePreferredSport(BikeCategory.mtbAm), isFalse);
      expect(store.preferredSports, [BikeCategory.mtbAm]);

      expect(store.togglePreferredSport(BikeCategory.road), isTrue);
      expect(store.preferredSports, [
        BikeCategory.mtbAm,
        BikeCategory.road,
      ]);
      expect(store.togglePreferredSport(BikeCategory.road), isTrue);
      expect(store.preferredSports, [BikeCategory.mtbAm]);
      expect(store.preferredSport, BikeCategory.mtbAm);
    });

    test('removing haupt switches to another chosen sport', () {
      final store = UserProfileStore();
      store.setPrimarySport(BikeCategory.mtbAm);
      store.togglePreferredSport(BikeCategory.gravel);
      expect(store.preferredSport, BikeCategory.mtbAm);

      expect(store.togglePreferredSport(BikeCategory.mtbAm), isTrue);
      expect(store.preferredSport, BikeCategory.gravel);
      expect(store.preferredSports, [BikeCategory.gravel]);
    });

    test('adoptBikeCategory sets haupt when empty, else only adds', () {
      final store = UserProfileStore();
      store.adoptBikeCategory(BikeCategory.gravel, makePrimary: true);
      expect(store.preferredSport, BikeCategory.gravel);
      expect(store.preferredSports, [BikeCategory.gravel]);

      store.adoptBikeCategory(BikeCategory.road, makePrimary: false);
      expect(store.preferredSport, BikeCategory.gravel);
      expect(store.preferredSports, contains(BikeCategory.road));

      store.adoptBikeCategory(BikeCategory.mtbAm, makePrimary: true);
      expect(store.preferredSport, BikeCategory.mtbAm);
      expect(store.preferredSports.first, BikeCategory.mtbAm);
    });

    test('setPrimary adds missing sport and moves it first', () {
      final store = UserProfileStore();
      store.setPrimarySport(BikeCategory.urban);
      store.setPrimarySport(BikeCategory.road);
      expect(store.preferredSport, BikeCategory.road);
      expect(store.preferredSports.first, BikeCategory.road);
      expect(store.preferredSports, contains(BikeCategory.urban));
    });

    test('save json writes both fields', () {
      final store = UserProfileStore();
      store.setPrimarySport(BikeCategory.mtbAm);
      store.togglePreferredSport(BikeCategory.road);
      final json = store.preferredSportsJson();
      expect(json['preferredSport'], 'mtbAm');
      expect(json['preferredSports'], ['mtbAm', 'road']);
    });

    test('onboarding sets haupt plus single-item list', () {
      final store = UserProfileStore();
      store.preferredSport = BikeCategory.gravel;
      store.preferredSports = [BikeCategory.gravel];
      store.normalizePreferredSports();
      expect(store.preferredSports, [BikeCategory.gravel]);
    });

    test('clear empties both', () {
      final store = UserProfileStore();
      store.setPrimarySport(BikeCategory.emtb);
      store.togglePreferredSport(BikeCategory.etrekking);
      store.preferredSport = null;
      store.preferredSports = [];
      store.normalizePreferredSports();
      expect(store.preferredSport, isNull);
      expect(store.preferredSports, isEmpty);
    });
  });

  group('preferredSportsSummaryLine', () {
    test('haupt only and also-list', () {
      expect(
        preferredSportsSummaryLine(
          primary: BikeCategory.mtbAm,
          sports: [BikeCategory.mtbAm],
        ),
        'Haupt: MTB',
      );
      expect(
        preferredSportsSummaryLine(
          primary: BikeCategory.mtbAm,
          sports: [BikeCategory.mtbAm, BikeCategory.road, BikeCategory.gravel],
        ),
        'Haupt: MTB · auch Rennrad, Gravel',
      );
    });
  });

  group('discoverProfileMenuForSports', () {
    test('empty list uses fallback including hiking', () {
      final menu = discoverProfileMenuForSports();
      expect(menu, kDiscoverProfileMenuFallback);
      expect(menu, contains(RoutingProfile.hiking));
    });

    test('haupt first then remaining, no hiking unless chosen', () {
      final menu = discoverProfileMenuForSports(
        primary: BikeCategory.mtbAm,
        sports: [BikeCategory.mtbAm, BikeCategory.road, BikeCategory.gravel],
      );
      expect(menu.first, RoutingProfile.mtbTrail);
      expect(menu, [
        RoutingProfile.mtbTrail,
        RoutingProfile.road,
        RoutingProfile.gravel,
      ]);
      expect(menu, isNot(contains(RoutingProfile.hiking)));
    });

    test('mtbAm and mtbTrail collapse to one routing profile', () {
      final menu = discoverProfileMenuForSports(
        primary: BikeCategory.mtbAm,
        sports: [BikeCategory.mtbAm, BikeCategory.mtbTrail],
      );
      expect(menu, [RoutingProfile.mtbTrail]);
      expect(discoverNavProfileChipVisible(menu), isFalse);
    });

    test('nav profile chip stays when there is a real choice', () {
      expect(
        discoverNavProfileChipVisible(
          discoverProfileMenuForSports(
            primary: BikeCategory.mtbAm,
            sports: [BikeCategory.mtbAm, BikeCategory.road],
          ),
        ),
        isTrue,
      );
      expect(
        discoverNavProfileChipVisible(kDiscoverProfileMenuFallback),
        isTrue,
      );
    });

    test('Enduro garage maps to MTB chip, not a fake Enduro nav mode', () {
      expect(
        discoverNavProfile(RoutingProfile.mtbEnduro),
        RoutingProfile.mtbTrail,
      );
      expect(discoverChipFamilyId(RoutingProfile.mtbEnduro), 'mtb');
      expect(discoverChipFamilyId(RoutingProfile.mtbTrail), 'mtb');
      expect(
        discoverProfileMenuForSports(
          primary: BikeCategory.mtbEnduro,
          sports: [BikeCategory.mtbEnduro, BikeCategory.road],
        ),
        [RoutingProfile.mtbTrail, RoutingProfile.road],
      );
      expect(kDiscoverProfileMenuFallback, isNot(contains(RoutingProfile.mtbEnduro)));
      expect(routingProfileSharesGhBasicBike(RoutingProfile.road), isTrue);
      expect(routingProfileSharesGhBasicBike(RoutingProfile.hiking), isFalse);
    });
  });

  test('SyncPayload roundtrip keeps preferredSports', () {
    final p = const SyncPayload(
      preferredSport: 'mtbAm',
      preferredSports: ['mtbAm', 'road'],
    );
    final back = SyncPayload.fromJson(p.toJson());
    expect(back.preferredSport, 'mtbAm');
    expect(back.preferredSports, ['mtbAm', 'road']);
  });
}
