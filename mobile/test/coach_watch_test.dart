import 'package:aetherride_mobile/domain/ai/coach_inbox.dart';
import 'package:aetherride_mobile/domain/ai/coach_watch.dart';
import 'package:aetherride_mobile/domain/ai/chat_context.dart';
import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/component.dart';
import 'package:aetherride_mobile/domain/ride.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('leere Garage erzeugt keine Hinweise', () {
    expect(
      buildCoachWatch(
        const CoachWatchInput(
          bikes: [],
          componentsByBike: {},
          rides: [],
        ),
      ),
      isEmpty,
    );
  });

  test('überfällige Kette erscheint im Monitor', () {
    const bike = Bike(
      id: 'b1',
      name: 'Spire',
      category: BikeCategory.mtbEnduro,
      odometerKm: 2500,
      hours: 90,
      isActive: true,
    );
    final chain = BikeComponent(
      id: 'c1',
      bikeId: 'b1',
      slot: ComponentSlot.chain,
      installedAt: DateTime.utc(2025, 1, 1),
      odometerKm: 0,
    );
    final notices = buildCoachWatch(
      CoachWatchInput(
        bikes: const [bike],
        componentsByBike: {
          'b1': [chain],
        },
        rides: const [],
      ),
    );
    expect(notices, isNotEmpty);
    expect(notices.any((n) => n.kind == CoachKind.maintenance), isTrue);
  });

  test('Snooze blendet denselben Hinweis aus', () {
    const bike = Bike(
      id: 'b1',
      name: 'Spire',
      category: BikeCategory.mtbEnduro,
      odometerKm: 2500,
      hours: 90,
    );
    final chain = BikeComponent(
      id: 'c1',
      bikeId: 'b1',
      slot: ComponentSlot.chain,
      installedAt: DateTime.utc(2025, 1, 1),
    );
    final notices = buildCoachWatch(
      CoachWatchInput(
        bikes: const [bike],
        componentsByBike: {
          'b1': [chain],
        },
        rides: const [],
      ),
    );
    expect(notices, isNotEmpty);
    final snoozed = snoozeMeta({}, notices.first);
    final items = mergeCoachInbox(notices, snoozed);
    expect(items.any((i) => i.notice.id == notices.first.id), isFalse);
  });

  test('Chat-Payload mappt km und E-Bike', () {
    const bike = Bike(
      id: 'e1',
      name: 'Turbo',
      category: BikeCategory.emtb,
      odometerKm: 120,
      isEbike: true,
      isActive: true,
    );
    final json = bikeToChatJson(bike);
    expect(json['category'], 'emtb');
    expect(json['isEbike'], isTrue);
    expect(json['totalOdometerKm'], 120);
    expect(json['components'], isA<List>());

    final ride = RideRecord(
      id: 'r1',
      bikeId: 'e1',
      startedAt: DateTime.utc(2026, 8, 1),
      distanceKm: 12.5,
      movingTimeSec: 3600,
      elevationM: 400,
    );
    final rJson = rideToChatJson(ride);
    expect(rJson['distanceM'], 12500);
    expect(rJson['elevationGainM'], 400);
    expect(rJson['durationSec'], 3600);
  });

  test('Feedback-Fenster erzeugt Hinweis', () {
    const bike = Bike(
      id: 'b1',
      name: 'Spire',
      category: BikeCategory.mtbTrail,
      isActive: true,
    );
    final ride = RideRecord(
      id: 'r1',
      bikeId: 'b1',
      startedAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
      endedAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
      distanceKm: 18,
      movingTimeSec: 5400,
      elevationM: 600,
      summary: const {
        'gForcePeak': 4.2,
        'gForceRms': 1.4,
        'impactCount': 80,
        'flowScore': 48,
      },
    );
    final notices = buildCoachWatch(
      CoachWatchInput(
        bikes: const [bike],
        componentsByBike: const {'b1': []},
        rides: [ride],
      ),
    );
    expect(notices.any((n) => n.kind == CoachKind.feedback), isTrue);
  });
}
