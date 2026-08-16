/// In-app privacy lock during a ride (not the Android lock screen).
///
/// Arms only when the phone is likely sitting idle — pause or standstill —
/// so glanceable nav is not covered while moving.
abstract final class RideAutoLockPolicy {
  static const Duration idleTimeout = Duration(seconds: 20);

  /// Below this, the rider is treated as standing / stopped.
  static const double movingKmh = 3;

  /// Whether the idle timer may show the overlay.
  static bool shouldArm({
    required bool riding,
    required bool paused,
    required double speedKmh,
  }) {
    if (!riding) return false;
    if (paused) return true;
    return speedKmh < movingKmh;
  }

  /// Overlay must leave when the rider is moving again (HUD needed).
  static bool shouldUnlockForMotion({
    required bool locked,
    required bool paused,
    required double speedKmh,
  }) {
    if (!locked || paused) return false;
    return speedKmh >= movingKmh;
  }

  /// Auto-rejoin only while moving and the gap is a near miss (< 800 m).
  /// Speed 0 + 12–15 km is a conscious approach (banner CTA), not a 45 s loop.
  static const double autoRejoinMaxGapM = 800;

  static bool shouldAutoRejoin({
    required bool enabled,
    required bool userChoseStay,
    required bool offRoute,
    required bool paused,
    required double speedKmh,
    required double crossTrackM,
  }) {
    if (!enabled || userChoseStay || !offRoute || paused) return false;
    if (!crossTrackM.isFinite) return false;
    if (speedKmh < movingKmh) return false;
    if (crossTrackM >= autoRejoinMaxGapM) return false;
    return true;
  }
}
