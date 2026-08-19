/// Mount-zero for HUD lean. Every phone clamp sits at a different rest angle.
///
/// Display lean = raw IMU minus the stored offset, wrapped to (−180, 180].
/// Does not rewrite recorded chunks — HUD / peek only.
abstract final class HudLeanCalibration {
  static const double resetEpsilonDeg = 0.5;

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
}
