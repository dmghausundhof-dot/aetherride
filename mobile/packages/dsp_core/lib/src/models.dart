class DspSample {
  const DspSample({
    required this.tMs,
    required this.ax,
    required this.ay,
    required this.az,
    required this.gx,
    required this.gy,
    required this.gz,
  });

  final int tMs;
  final double ax;
  final double ay;
  final double az;
  final double gx;
  final double gy;
  final double gz;
}

class DspFused {
  const DspFused({
    required this.timestampMs,
    required this.gForcePeak,
    required this.gForceRms,
    required this.leanAngleDeg,
    required this.impactDetected,
    required this.impactMagnitude,
    required this.flowContribution,
  });

  final int timestampMs;
  final double gForcePeak;
  final double gForceRms;
  final double leanAngleDeg;
  final bool impactDetected;
  final double impactMagnitude;
  final double flowContribution;
}
