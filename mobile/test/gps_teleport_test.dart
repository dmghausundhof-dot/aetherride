import 'package:aetherride_mobile/domain/ride/gps_teleport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normal riding is not a teleport', () {
    expect(
      isGpsTeleport(distanceM: 12, dtSec: 1.0),
      isFalse,
    );
    expect(
      isGpsTeleport(distanceM: 8, dtSec: 0.5, accuracyM: 8),
      isFalse,
    );
  });

  test('emulator city hop is a teleport', () {
    // 3.1 km in 29 s ≈ 384 km/h
    expect(
      isGpsTeleport(distanceM: 3100, dtSec: 29),
      isTrue,
    );
  });

  test('two fused streams at once look like a jump', () {
    expect(
      isGpsTeleport(distanceM: 120, dtSec: 0.02),
      isTrue,
    );
  });
}
