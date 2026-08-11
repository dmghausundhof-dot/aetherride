import 'package:aetherride_mobile/domain/routing/camera_follow_smooth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bearing smooth', () {
    test('shortest delta wraps around north', () {
      expect(shortestBearingDeltaDeg(350, 10), closeTo(20, 0.01));
      expect(shortestBearingDeltaDeg(10, 350), closeTo(-20, 0.01));
    });

    test('lerp does not spin the long way', () {
      final mid = lerpBearingDeg(350, 10, 0.5);
      expect(mid, closeTo(0, 0.5));
    });

    test('smooth moves toward measured', () {
      final s = smoothBearingDeg(previous: 0, measured: 90, alpha: 0.5);
      expect(s, closeTo(45, 0.01));
    });
  });

  group('shouldUpdateFollowCamera', () {
    final t0 = DateTime.utc(2026, 1, 1, 12);

    test('first update always true', () {
      expect(
        shouldUpdateFollowCamera(
          lastLat: null,
          lastLng: null,
          nextLat: 52.5,
          nextLng: 13.4,
          lastBearing: 0,
          nextBearing: 10,
          lastUpdateAt: null,
          now: t0,
        ),
        isTrue,
      );
    });

    test('throttles tiny moves inside interval', () {
      expect(
        shouldUpdateFollowCamera(
          lastLat: 52.5,
          lastLng: 13.4,
          nextLat: 52.500001,
          nextLng: 13.400001,
          lastBearing: 10,
          nextBearing: 12,
          lastUpdateAt: t0,
          now: t0.add(const Duration(milliseconds: 200)),
        ),
        isFalse,
      );
    });

    test('allows large heading change even inside interval', () {
      expect(
        shouldUpdateFollowCamera(
          lastLat: 52.5,
          lastLng: 13.4,
          nextLat: 52.5,
          nextLng: 13.4,
          lastBearing: 0,
          nextBearing: 90,
          lastUpdateAt: t0,
          now: t0.add(const Duration(milliseconds: 200)),
        ),
        isTrue,
      );
    });
  });
}
