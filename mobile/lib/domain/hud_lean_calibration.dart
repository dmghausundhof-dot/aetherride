/// Mount-zero for HUD lean. Every phone clamp sits at a different rest angle.
///
/// Display lean = raw IMU minus the stored offset, wrapped to (−180, 180].
/// Does not rewrite recorded chunks — HUD / peek only.
abstract final class HudLeanCalibration {
  static const double resetEpsilonDeg = 0.5;

  /// Rolling faster than this makes a rest-angle zero meaningless.
  static const double maxCalibrateSpeedKmh = 4;

  /// Gauge bar clamp — the numeral still shows the real display lean.
  static const double gaugeVisualMaxAbsDeg = 50;

  /// HUD lean after subtracting the rider's mount zero.
  static double displayDeg(double rawDeg, double offsetDeg) {
    var d = rawDeg - offsetDeg;
    while (d > 180) {
      d -= 360;
    }
    while (d <= -180) {
      d += 360;
    }
    return d;
  }

  /// Current raw sample becomes 0° on the HUD.
  static double offsetFromRaw(double rawDeg) => rawDeg;

  static bool isCalibrated(double offsetDeg) =>
      offsetDeg.abs() >= resetEpsilonDeg;

  static String formatDeg(double displayDeg, {int fractionDigits = 1}) {
    return '${displayDeg.toStringAsFixed(fractionDigits)}°';
  }

  /// Zero only when the IMU has a sample and the bike is nearly still.
  static bool canCalibrate({
    required double? rawLeanDeg,
    required double speedKmh,
  }) {
    if (rawLeanDeg == null) return false;
    return speedKmh < maxCalibrateSpeedKmh;
  }

  static double gaugeVisualDeg(double displayDeg) =>
      displayDeg.clamp(-gaugeVisualMaxAbsDeg, gaugeVisualMaxAbsDeg);

  /// Any fused sample is enough to show the Fahrwerk row (mount is not a gate).
  static bool hasLiveSample({
    double? leanDeg,
    double? gPeak,
    double? flow,
  }) {
    return leanDeg != null || gPeak != null || flow != null;
  }
}
