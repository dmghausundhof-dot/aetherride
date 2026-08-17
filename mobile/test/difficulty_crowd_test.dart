import 'package:aetherride_mobile/domain/community/difficulty_crowd.dart';
import 'package:aetherride_mobile/domain/community/place_on_track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('aggregateDifficulty hides crowd under n=5', () {
    final thin = aggregateDifficulty([1, 1, 0, -1]);
    expect(thin.shown, isFalse);
    expect(thin.mean, isNull);
    expect(thin.n, 4);
  });

  test('aggregateDifficulty labels harder / as marked / easier', () {
    final harder = aggregateDifficulty([1, 1, 1, 1, 0, 1]);
    expect(harder.shown, isTrue);
    expect(harder.label, DifficultyCrowdLabel.harder);

    final same = aggregateDifficulty([0, 0, 0, 0, 0]);
    expect(same.label, DifficultyCrowdLabel.asMarked);

    final easy = aggregateDifficulty([-1, -1, -1, -1, 0]);
    expect(easy.label, DifficultyCrowdLabel.easier);
  });

  test('DifficultyCrowd.fromJson does not invent shown', () {
    final hidden = DifficultyCrowd.fromJson({
      'n': 3,
      'shown': true,
      'label': 'harder',
    });
    expect(hidden.shown, isFalse);

    final live = DifficultyCrowd.fromJson({
      'n': 6,
      'mean': 0.7,
      'shown': true,
      'label': 'harder',
    });
    expect(live.shown, isTrue);
    expect(live.label, DifficultyCrowdLabel.harder);
  });

  test('sampleTrackLngLat keeps first and last of a long line', () {
    final long = [
      for (var i = 0; i < 80; i++) [8.67 + i * 0.001, 49.4],
    ];
    final sampled = sampleTrackLngLat(long, max: 40);
    expect(sampled.length, lessThanOrEqualTo(40));
    expect(sampled.first, long.first);
    expect(sampled.last, long.last);
  });
}
