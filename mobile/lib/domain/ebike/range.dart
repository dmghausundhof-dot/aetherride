/// Vereinfachte F-EBK-004 Reichweitenprognose — Port von src/lib/ebike/range.ts.
library;

import 'dart:math' as math;

import '../bike.dart';

const _g = 9.81;
const _rho = 1.225;

class RangeCalibration {
  const RangeCalibration({
    required this.crr,
    required this.cdA,
    required this.riderPowerW,
    this.samples = 0,
    this.updatedAt,
  });

  final double crr;
  final double cdA;
  final double riderPowerW;
  final int samples;
  final String? updatedAt;

  Map<String, dynamic> toJson() => {
        'crr': crr,
        'cdA': cdA,
        'riderPowerW': riderPowerW,
        'samples': samples,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };

  factory RangeCalibration.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const RangeCalibration(crr: 0.015, cdA: 0.4, riderPowerW: 120);
    }
    return RangeCalibration(
      crr: (json['crr'] as num?)?.toDouble() ?? 0.015,
      cdA: (json['cdA'] as num?)?.toDouble() ?? 0.4,
      riderPowerW: (json['riderPowerW'] as num?)?.toDouble() ?? 120,
      samples: (json['samples'] as num?)?.toInt() ?? 0,
      updatedAt: json['updatedAt'] as String?,
    );
  }
}

class RangeEstimate {
  const RangeEstimate({
    required this.kmLow,
    required this.kmHigh,
    required this.whPerKmLow,
    required this.whPerKmHigh,
    required this.batteryWh,
    required this.confidence,
    required this.factors,
    required this.calibrated,
  });

  final int kmLow;
  final int kmHigh;
  final double whPerKmLow;
  final double whPerKmHigh;
  final int batteryWh;
  final String confidence; // low | medium | high
  final List<String> factors;
  final bool calibrated;
}

double _baseCrr(BikeCategory category, double tirePressurePsi) {
  var crr =
      category == BikeCategory.emtb || category == BikeCategory.mtbEnduro
          ? 0.018
          : 0.012;
  if (tirePressurePsi < 22) {
    crr += 0.004;
  } else if (tirePressurePsi > 28) {
    crr -= 0.002;
  }
  return crr;
}

double _baseCdA(BikeCategory category) {
  switch (category) {
    case BikeCategory.road:
      return 0.32;
    case BikeCategory.gravel:
      return 0.36;
    case BikeCategory.emtb:
    case BikeCategory.mtbEnduro:
    case BikeCategory.mtbAm:
      return 0.42;
    default:
      return 0.38;
  }
}

RangeCalibration defaultCalibration({
  required BikeCategory category,
  double tirePressurePsi = 24,
  int skillLevel = 2,
}) {
  return RangeCalibration(
    crr: _baseCrr(category, tirePressurePsi),
    cdA: _baseCdA(category),
    riderPowerW: 90 + skillLevel * 15.0,
  );
}

/// Kalman-artige Ein-Schritt-Anpassung nach Ride (Port calibrateFromRide).
RangeCalibration calibrateFromRide({
  required RangeCalibration prev,
  required double distanceKm,
  required double movingTimeSec,
  required double batteryWhUsed,
  double? avgRiderPowerW,
}) {
  if (distanceKm < 2 || batteryWhUsed < 10) return prev;
  final observedWhPerKm = batteryWhUsed / distanceKm;
  final speedKmh =
      movingTimeSec > 0 ? distanceKm / (movingTimeSec / 3600) : 18;
  final expected =
      prev.crr * 180 + prev.cdA * 40 + 200 / math.max(8, speedKmh);
  final err = observedWhPerKm - expected;
  final k = 1 / (prev.samples + 2);
  final nextPower = avgRiderPowerW ?? prev.riderPowerW;
  return RangeCalibration(
    crr: (prev.crr + k * err * 0.00008).clamp(0.006, 0.04),
    cdA: (prev.cdA + k * err * 0.002).clamp(0.25, 0.6),
    riderPowerW:
        (prev.riderPowerW + k * (nextPower - prev.riderPowerW)).clamp(60, 250),
    samples: prev.samples + 1,
    updatedAt: DateTime.now().toUtc().toIso8601String(),
  );
}

/// Physik: P = (Crr·m·g·cosα + ½ρ·CdA·v² + m·g·sinα) · v
RangeEstimate estimateRange({
  required BikeCategory category,
  RangeCalibration? calibration,
  double batteryWh = 500,
  double tirePressurePsi = 24,
  double riderWeightKg = 78,
  double bikeWeightKg = 22,
  double meanGrade = 0.03,
  double speedKmh = 22,
  double socPercent = 100,
  int skillLevel = 2,
}) {
  final cal = calibration ??
      defaultCalibration(
        category: category,
        tirePressurePsi: tirePressurePsi,
        skillLevel: skillLevel,
      );
  final m = riderWeightKg + bikeWeightKg + 2;
  final v = speedKmh / 3.6;
  final alpha = meanGrade;
  final crr = cal.crr;
  final cdA = cal.cdA;

  final pRoll = crr * m * _g * math.cos(alpha) * v;
  final pAero = 0.5 * _rho * cdA * v * v * v;
  final pGrade = m * _g * math.sin(alpha) * v;
  final pTotal = pRoll + pAero + pGrade;
  final pRider =
      cal.riderPowerW < pTotal * 0.55 ? cal.riderPowerW : pTotal * 0.55;
  const eta = 0.78;
  final pMotor = math.max(0.0, (pTotal - pRider) / eta);

  final whPerKm = (pMotor / v) * (1000 / 3600);
  final wh = batteryWh * (socPercent / 100);

  final spread = math.max(0.08, 0.18 - cal.samples * 0.015);
  final whLow = whPerKm * (1 - spread);
  final whHigh = whPerKm * (1 + spread);

  return RangeEstimate(
    kmLow: (wh / whHigh).round(),
    kmHigh: (wh / whLow).round(),
    whPerKmLow: (whLow * 10).round() / 10,
    whPerKmHigh: (whHigh * 10).round() / 10,
    batteryWh: wh.round(),
    confidence: cal.samples >= 5
        ? 'high'
        : cal.samples >= 2
            ? 'medium'
            : 'low',
    factors: [
      'Crr ${crr.toStringAsFixed(3)} (Reifendruck ${tirePressurePsi.toStringAsFixed(0)} psi)',
      'Cd·A ${cdA.toStringAsFixed(2)} (${category.name})',
      'Systemmasse ${m.toStringAsFixed(0)} kg · Ø-Steigung ${(alpha * 100).toStringAsFixed(1)} %',
    ],
    calibrated: cal.samples > 0,
  );
}
