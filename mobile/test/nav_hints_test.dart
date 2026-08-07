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
