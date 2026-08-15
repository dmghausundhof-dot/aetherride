import 'package:flutter_test/flutter_test.dart';
import 'package:aetherride_mobile/domain/routing/nav_announce.dart';
import 'package:aetherride_mobile/domain/sensor/live_hints.dart';

void main() {
  test('announceDistancesForSpeed uses 400/150/30 under 25 km/h', () {
    expect(announceDistancesForSpeed(20), [400, 150, 30]);
  });

  test('pickAnnounce fires once per tier', () {
    final spoken = <String>{};
    final first = pickAnnounce(
      stepId: 's1',
      instruction: 'Links abbiegen',
      isArrive: false,
      remainingM: 390,
      speedKmh: 18,
      spoken: spoken,
    );
    expect(first, contains('Links abbiegen'));
    final again = pickAnnounce(
      stepId: 's1',
      instruction: 'Links abbiegen',
      isArrive: false,
      remainingM: 385,
      speedKmh: 18,
      spoken: spoken,
    );
    expect(again, isNull);
  });

  test('pickAnnounce hängt Straßenname an, ohne ihn zu verdoppeln', () {
    final spoken = <String>{};
    final withStreet = pickAnnounce(
      stepId: 's2',
      instruction: 'Rechts abbiegen',
      isArrive: false,
      remainingM: 145,
      speedKmh: 18,
      spoken: spoken,
      street: 'Hauptstraße',
    );
    expect(withStreet, contains('auf Hauptstraße'));
    expect(withStreet, contains('Metern'));

    final alreadyNamed = pickAnnounce(
      stepId: 's3',
      instruction: 'Links abbiegen auf Neckarstaden',
      isArrive: false,
      remainingM: 145,
      speedKmh: 18,
      spoken: <String>{},
      street: 'Neckarstaden',
    );
    expect(alreadyNamed, isNot(contains('auf Neckarstaden auf')));
    expect(alreadyNamed, contains('Links abbiegen auf Neckarstaden'));
  });

  test('hintsFromMetrics stand and impact streak', () {
    final hints = hintsFromMetrics(
      speedKmh: 1,
      standSeconds: 12,
      impactJustDetected: true,
      hardImpactStreak: 3,
    );
    expect(hints.map((h) => h.id), containsAll(['stand-setup', 'impact-streak']));
  });

  test('clampHint limits to 6 words', () {
    expect(
      clampHint('eins zwei drei vier fünf sechs sieben acht'),
      'eins zwei drei vier fünf sechs',
    );
  });
}
