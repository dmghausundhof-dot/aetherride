import 'package:aetherride_mobile/domain/ride_auto_lock.dart';
import 'package:aetherride_mobile/domain/routing/ride_nav_honesty.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('showTurnByTurn', () {
    test('keeps TBT on the line and just off it', () {
      expect(showTurnByTurn(crossTrackM: 0), isTrue);
      expect(showTurnByTurn(crossTrackM: 35), isTrue);
      expect(showTurnByTurn(crossTrackM: 80), isTrue);
    });

    test('hides TBT when the body is far from the seed line', () {
      expect(showTurnByTurn(crossTrackM: 80.1), isFalse);
      expect(showTurnByTurn(crossTrackM: 14800), isFalse);
    });

    test('keeps TBT before the first GPS projection', () {
      expect(showTurnByTurn(crossTrackM: double.infinity), isTrue);
    });
  });

  group('RideAutoLockPolicy.shouldAutoRejoin', () {
    const base = (
      enabled: true,
      userChoseStay: false,
      offRoute: true,
      paused: false,
    );

    test('fires while moving with a near-miss gap', () {
      expect(
        RideAutoLockPolicy.shouldAutoRejoin(
          enabled: base.enabled,
          userChoseStay: base.userChoseStay,
          offRoute: base.offRoute,
          paused: base.paused,
          speedKmh: 18,
          crossTrackM: 120,
        ),
        isTrue,
      );
    });

    test('does not fire at speed 0', () {
      expect(
        RideAutoLockPolicy.shouldAutoRejoin(
          enabled: base.enabled,
          userChoseStay: base.userChoseStay,
          offRoute: base.offRoute,
          paused: base.paused,
          speedKmh: 0,
          crossTrackM: 120,
        ),
        isFalse,
      );
      expect(
        RideAutoLockPolicy.shouldAutoRejoin(
          enabled: base.enabled,
          userChoseStay: base.userChoseStay,
          offRoute: base.offRoute,
          paused: base.paused,
          speedKmh: 2.9,
          crossTrackM: 400,
        ),
        isFalse,
      );
    });

    test('does not fire on a 12–15 km gap even while moving', () {
      expect(
        RideAutoLockPolicy.shouldAutoRejoin(
          enabled: base.enabled,
          userChoseStay: base.userChoseStay,
          offRoute: base.offRoute,
          paused: base.paused,
          speedKmh: 22,
          crossTrackM: 14800,
        ),
        isFalse,
      );
      expect(
        RideAutoLockPolicy.shouldAutoRejoin(
          enabled: base.enabled,
          userChoseStay: base.userChoseStay,
          offRoute: base.offRoute,
          paused: base.paused,
          speedKmh: 22,
          crossTrackM: 800,
        ),
        isFalse,
      );
      expect(
        RideAutoLockPolicy.shouldAutoRejoin(
          enabled: base.enabled,
          userChoseStay: base.userChoseStay,
          offRoute: base.offRoute,
          paused: base.paused,
          speedKmh: 22,
          crossTrackM: 799,
        ),
        isTrue,
      );
    });

    test('respects stay / pause / disabled', () {
      expect(
        RideAutoLockPolicy.shouldAutoRejoin(
          enabled: false,
          userChoseStay: false,
          offRoute: true,
          paused: false,
          speedKmh: 18,
          crossTrackM: 120,
        ),
        isFalse,
      );
      expect(
        RideAutoLockPolicy.shouldAutoRejoin(
          enabled: true,
          userChoseStay: true,
          offRoute: true,
          paused: false,
          speedKmh: 18,
          crossTrackM: 120,
        ),
        isFalse,
      );
      expect(
        RideAutoLockPolicy.shouldAutoRejoin(
          enabled: true,
          userChoseStay: false,
          offRoute: true,
          paused: true,
          speedKmh: 18,
          crossTrackM: 120,
        ),
        isFalse,
      );
      expect(
        RideAutoLockPolicy.shouldAutoRejoin(
          enabled: true,
          userChoseStay: false,
          offRoute: false,
          paused: false,
          speedKmh: 18,
          crossTrackM: 120,
        ),
        isFalse,
      );
    });
  });

  group('rideRestSplit', () {
    test('on-route uses a single rest-km', () {
      final s = rideRestSplit(
        routeDistanceKm: 16,
        alongRouteM: 5000,
        joinAlongM: 0,
        crossTrackM: 4,
      );
      expect(s.mode, RideRestHudMode.alongRoute);
      expect(s.restKm, closeTo(11, 0.01));
      expect(s.untilJoinKm, isNull);
    });

    test('approach before join splits until-join vs rest loop', () {
      final s = rideRestSplit(
        routeDistanceKm: 21,
        alongRouteM: 2000,
        joinAlongM: 15000,
        crossTrackM: 12,
      );
      expect(s.mode, RideRestHudMode.splitToJoin);
      expect(s.untilJoinKm, closeTo(13, 0.01));
      expect(s.restLoopKm, closeTo(6, 0.01));
    });

    test('far off-route does not show seed-rest as the only number', () {
      final s = rideRestSplit(
        routeDistanceKm: 16.2,
        alongRouteM: 10100,
        joinAlongM: 0,
        crossTrackM: 14800,
      );
      expect(s.mode, RideRestHudMode.splitToJoin);
      expect(s.untilJoinKm, closeTo(14.8, 0.05));
      expect(s.restLoopKm, closeTo(6.1, 0.05));
      expect(s.restKm, isNull);
    });

    test('far off with a known join uses rest of loop after join', () {
      final s = rideRestSplit(
        routeDistanceKm: 21,
        alongRouteM: 100,
        joinAlongM: 15000,
        crossTrackM: 14800,
      );
      expect(s.untilJoinKm, closeTo(14.8, 0.05));
      expect(s.restLoopKm, closeTo(6, 0.01));
    });
  });

  test('formatHudKm keeps 14.8 readable', () {
    expect(formatHudKm(14.8), '14.8');
    expect(formatHudKm(6.12), '6.1');
    expect(formatHudKm(120.4), '120');
  });
}
