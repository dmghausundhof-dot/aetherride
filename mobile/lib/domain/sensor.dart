// Contract-Spiegel von src/lib/sensor/SensorFusion.ts.
// Native Übergabe: nur 1-s-Blöcke (Spec §5.1) — kein Sample-für-Sample.

class RawSensorSample {
  const RawSensorSample({
    required this.tMs,
    required this.ax,
    required this.ay,
    required this.az,
    required this.gx,
    required this.gy,
    required this.gz,
    this.pressureHpa,
  });

  final int tMs;
  final double ax;
  final double ay;
  final double az;
  final double gx;
  final double gy;
  final double gz;
  final double? pressureHpa;
}

class FusedMetrics {
  const FusedMetrics({
    required this.timestampMs,
    required this.gForcePeak,
    required this.gForceRms,
    required this.leanAngleDeg,
    required this.impactDetected,
    required this.impactMagnitude,
    required this.flowContribution,
    this.estimatedTravelUsagePct,
  });

  final int timestampMs;
  final double gForcePeak;
  final double gForceRms;
  final double leanAngleDeg;
  final bool impactDetected;
  final double impactMagnitude;
  final double flowContribution;
  final double? estimatedTravelUsagePct;
}

/// Ein 1-s-Block vom nativen `sensor_core` (Ringpuffer → Dart).
class SensorBlock {
  const SensorBlock({
    required this.windowStartMs,
    required this.windowEndMs,
    required this.sampleRateHz,
    required this.samples,
    this.fused,
  });

  final int windowStartMs;
  final int windowEndMs;
  final int sampleRateHz;
  final List<RawSensorSample> samples;
  final FusedMetrics? fused;
}
