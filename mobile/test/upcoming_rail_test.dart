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

  group('buildUpcomingRail', () {
    test('prefers next turn when available', () {
      final item = buildUpcomingRail(
        nextNextTurnInstruction: 'Rechts abbiegen',
        nextNextTurnRemainingM: 400,
        nextPoi: const RoutePoiStop(atMin: 20, title: 'Café'),
        remainingClimbM: 80,
      );
      expect(item?.kind, 'turn');
      expect(item?.label, 'Rechts abbiegen');
      expect(item?.detail, '400 m');
    });

    test('falls back to poi', () {
      final item = buildUpcomingRail(
        nextNextTurnInstruction: null,
        nextNextTurnRemainingM: null,
        nextPoi: const RoutePoiStop(atMin: 20, title: 'Café am Feld'),
        remainingClimbM: 80,
      );
      expect(item?.kind, 'poi');
      expect(item?.label, 'Café am Feld');
    });

    test('climb stub last', () {
      final item = buildUpcomingRail(
        nextNextTurnInstruction: null,
        nextNextTurnRemainingM: null,
        nextPoi: null,
        remainingClimbM: 120,
      );
      expect(item?.kind, 'climb');
      expect(item?.detail, contains('120'));
    });
  });
}
