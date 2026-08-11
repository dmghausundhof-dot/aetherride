import 'package:aetherride_mobile/domain/routing/upcoming_rail.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nextPoiStop', () {
    const stops = [
      RoutePoiStop(atMin: 15, title: 'Aussicht', kind: 'viewpoint'),
      RoutePoiStop(atMin: 35, title: 'Café', kind: 'cafe'),
    ];

    test('picks first ahead of progress', () {
      // 10% of 60 min ≈ 6 min elapsed → next is 15.
      final p = nextPoiStop(
        stops: stops,
        alongRouteM: 1000,
        totalDistanceM: 10000,
        durationMin: 60,
      );
      expect(p?.title, 'Aussicht');
    });

    test('skips past pois', () {
      // 50% of 60 ≈ 30 min → next is 35 Café.
      final p = nextPoiStop(
        stops: stops,
        alongRouteM: 5000,
        totalDistanceM: 10000,
        durationMin: 60,
      );
      expect(p?.title, 'Café');
    });

    test('null when all past', () {
      final p = nextPoiStop(
        stops: stops,
        alongRouteM: 9999,
        totalDistanceM: 10000,
        durationMin: 60,
      );
      expect(p, isNull);
    });
  });

  group('buildUpcomingRail (nav-hud-tokens-v1 <15 min)', () {
    test('prefers next turn when ETA under 15 min', () {
      final item = buildUpcomingRail(
        nextNextTurnInstruction: 'Rechts abbiegen',
        nextNextTurnRemainingM: 400,
        nextNextTurnEtaMin: 2,
        nextPoi: const RoutePoiStop(atMin: 20, title: 'Café'),
        nextPoiEtaMin: 14,
        remainingClimbM: 80,
      );
      expect(item?.kind, 'turn');
      expect(item?.label, 'Rechts abbiegen');
      expect(item?.detail, '400 m');
    });

    test('hides turn when ETA ≥ 15 min', () {
      final item = buildUpcomingRail(
        nextNextTurnInstruction: 'Rechts abbiegen',
        nextNextTurnRemainingM: 4000,
        nextNextTurnEtaMin: 16,
        nextPoi: null,
        nextPoiEtaMin: null,
        remainingClimbM: null,
      );
      expect(item, isNull);
    });

    test('falls back to poi under 15 min', () {
      final item = buildUpcomingRail(
        nextNextTurnInstruction: null,
        nextNextTurnRemainingM: null,
        nextNextTurnEtaMin: null,
        nextPoi: const RoutePoiStop(atMin: 20, title: 'Café am Feld'),
        nextPoiEtaMin: 9,
        remainingClimbM: 80,
      );
      expect(item?.kind, 'poi');
      expect(item?.label, 'Café am Feld');
      expect(item?.detail, 'in ~9 min');
    });

    test('hides poi when ETA ≥ 15 min', () {
      final item = buildUpcomingRail(
        nextNextTurnInstruction: null,
        nextNextTurnRemainingM: null,
        nextNextTurnEtaMin: null,
        nextPoi: const RoutePoiStop(atMin: 40, title: 'Café'),
        nextPoiEtaMin: 20,
        remainingClimbM: null,
      );
      expect(item, isNull);
    });

    test('climb stub omitted (not a timed stop)', () {
      final item = buildUpcomingRail(
        nextNextTurnInstruction: null,
        nextNextTurnRemainingM: null,
        nextNextTurnEtaMin: null,
        nextPoi: null,
        nextPoiEtaMin: null,
        remainingClimbM: 120,
      );
      expect(item, isNull);
    });
  });

  group('eta helpers', () {
    test('etaMinForDistanceM uses cruise fallback', () {
      // 3 km at 18 km/h → 10 min
      expect(etaMinForDistanceM(3000), closeTo(10, 0.01));
    });

    test('poiEtaMin remaining', () {
      final eta = poiEtaMin(
        poi: const RoutePoiStop(atMin: 20, title: 'X'),
        alongRouteM: 2000,
        totalDistanceM: 10000,
        durationMin: 60,
      );
      // progress 12 min → remain 8
      expect(eta, closeTo(8, 0.01));
    });
  });
}
