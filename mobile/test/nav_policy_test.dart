import 'package:aetherride_mobile/data/routing/routing_client.dart';
import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/routing/nav_policy.dart';
import 'package:aetherride_mobile/domain/routing/trail_difficulty.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('navPolicyForBike', () {
    test('DH is gravity: auto/walk, no pedal connectors, follow descent', () {
      final p = navPolicyForBike(BikeCategory.dh);
      expect(p.session, NavSessionMode.gravity);
      expect(p.orientByElevation, isTrue);
      expect(p.allowPedalConnectors, isFalse);
      expect(p.stayOnDescent, isTrue);
      expect(p.skipEngineTrackReroute, isTrue);
    });

    test('Enduro may pedal, still follows descents', () {
      final p = navPolicyForBike(BikeCategory.mtbEnduro);
      expect(p.session, NavSessionMode.pedal);
      expect(p.allowPedalConnectors, isTrue);
      expect(p.orientByElevation, isTrue);
      expect(p.skipEngineTrackReroute, isTrue);
    });

    test('Trail/AM keeps bicycle A→B', () {
      final p = navPolicyForBike(BikeCategory.mtbAm);
      expect(p.session, NavSessionMode.pedal);
      expect(p.orientByElevation, isFalse);
      expect(p.skipEngineTrackReroute, isFalse);
    });

    test('Road is street session', () {
      expect(
        navPolicyForBike(BikeCategory.road).session,
        NavSessionMode.street,
      );
    });
  });

  group('suggestedApproachKind', () {
    final gravity = navPolicyForBike(BikeCategory.dh);
    final pedal = navPolicyForBike(BikeCategory.mtbAm);

    test('DH far away → auto', () {
      expect(
        suggestedApproachKind(policy: gravity, distanceKm: 12),
        ApproachKind.auto,
      );
    });

    test('DH under 1.5 km → walk', () {
      expect(
        suggestedApproachKind(policy: gravity, distanceKm: 0.4),
        ApproachKind.walk,
      );
    });

    test('DH at entry → atStart', () {
      expect(
        suggestedApproachKind(policy: gravity, distanceKm: 0.04),
        ApproachKind.atStart,
      );
    });

    test('Trail bike always bicycle default', () {
      expect(
        suggestedApproachKind(policy: pedal, distanceKm: 20),
        ApproachKind.bicycle,
      );
    });
  });

  group('approachRoutingProfile', () {
    test('DH auto is driving, never downhill bicycle', () {
      expect(
        approachRoutingProfile(BikeCategory.dh, ApproachKind.auto),
        RoutingProfile.driving,
      );
      expect(
        approachRoutingProfile(BikeCategory.dh, ApproachKind.walk),
        RoutingProfile.hiking,
      );
      expect(
        approachRoutingProfile(BikeCategory.dh, ApproachKind.bicycle),
        RoutingProfile.mtbTrail,
      );
    });

    test('AM bicycle stays mtbTrail', () {
      expect(
        approachRoutingProfile(BikeCategory.mtbAm, ApproachKind.bicycle),
        RoutingProfile.mtbTrail,
      );
    });
  });

  group('garage overlay vs costing', () {
    test('DH overlay chip is MTB, costing for A→B is not downhill', () {
      expect(routingProfileForBike(BikeCategory.dh), RoutingProfile.downhill);
      expect(
        discoverNavProfile(RoutingProfile.downhill),
        RoutingProfile.mtbTrail,
      );
      expect(
        discoverProfileMenuForSports(primary: BikeCategory.dh),
        [RoutingProfile.mtbTrail],
      );
      expect(kDiscoverProfileMenuFallback, isNot(contains(RoutingProfile.downhill)));
      expect(kDiscoverProfileMenuFallback, isNot(contains(RoutingProfile.driving)));
    });
  });

  test('gravityOnDescent after join', () {
    expect(
      gravityOnDescent(
        gravitySession: true,
        alongRouteM: 500,
        joinAlongM: 400,
      ),
      isTrue,
    );
    expect(
      gravityOnDescent(
        gravitySession: true,
        alongRouteM: 100,
        joinAlongM: 400,
      ),
      isFalse,
    );
    expect(
      gravityOnDescent(
        gravitySession: false,
        alongRouteM: 500,
        joinAlongM: 400,
      ),
      isFalse,
    );
  });

  group('trailFitsBike', () {
    test('road refuses S3, allows unrated', () {
      expect(
        trailFitsBike(bike: BikeCategory.road, scale: TrailDifficulty.s3),
        isFalse,
      );
      expect(
        trailFitsBike(bike: BikeCategory.road, scale: TrailDifficulty.s2),
        isFalse,
      );
      expect(
        trailFitsBike(bike: BikeCategory.road, scale: TrailDifficulty.open),
        isTrue,
      );
    });

    test('DH and trail bikes accept S3', () {
      expect(
        trailFitsBike(bike: BikeCategory.dh, scale: TrailDifficulty.s3),
        isTrue,
      );
      expect(
        trailFitsBike(bike: BikeCategory.mtbAm, scale: TrailDifficulty.s3),
        isTrue,
      );
    });
  });
}
