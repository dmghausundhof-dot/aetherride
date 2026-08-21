import '../bike.dart';

class SagPct {
  const SagPct({
    required this.min,
    required this.max,
    required this.target,
  });
  final double min;
  final double max;
  final double target;
}

class AirPsiEstimate {
  const AirPsiEstimate({
    required this.sag,
    required this.psiMin,
    required this.psiMax,
    required this.psiTarget,
    required this.note,
    this.sagMm,
    this.loadKg,
  });
  final SagPct sag;
  final int psiMin;
  final int psiMax;
  final int psiTarget;
  final String note;
  final int? sagMm;
  final double? loadKg;
}

class TravelUsageEstimate {
  const TravelUsageEstimate({
    required this.usagePct,
    required this.usageMm,
    required this.excessG,
    required this.charExcessG,
    required this.note,
  });
  final int usagePct;
  final int usageMm;
  final double excessG;
  final double charExcessG;
  final String note;
}

const double referenceBikeKg = 14;
const double endBiasFork = 0.4;
const double endBiasShock = 0.6;

SagPct recommendedSagPct(BikeCategory category, String end) {
  switch (category) {
    case BikeCategory.dh:
      return end == 'fork'
          ? const SagPct(min: 20, max: 28, target: 24)
          : const SagPct(min: 28, max: 36, target: 32);
    case BikeCategory.mtbEnduro:
      return end == 'fork'
          ? const SagPct(min: 20, max: 26, target: 23)
          : const SagPct(min: 27, max: 35, target: 31);
    case BikeCategory.mtbTrail:
    case BikeCategory.mtbAm:
      return end == 'fork'
          ? const SagPct(min: 18, max: 25, target: 22)
          : const SagPct(min: 25, max: 32, target: 28);
    case BikeCategory.emtb:
    case BikeCategory.etrekking:
      return end == 'fork'
          ? const SagPct(min: 18, max: 26, target: 22)
          : const SagPct(min: 25, max: 33, target: 29);
    default:
      return end == 'fork'
          ? const SagPct(min: 18, max: 25, target: 22)
          : const SagPct(min: 25, max: 32, target: 28);
  }
}

int targetSagMm(double travelMm, double sagPct) {
  if (travelMm <= 0 || sagPct <= 0) return 0;
  return (travelMm * (sagPct / 100)).round();
}

double equivalentRiderKg({
  required double riderWeightKg,
  double gearWeightKg = 0,
  double? bikeWeightKg,
  required String end,
}) {
  final rider = riderWeightKg.clamp(40.0, 180.0);
  final gear = gearWeightKg.clamp(0.0, 40.0);
  final bias = end == 'shock' ? endBiasShock : endBiasFork;
  final extra = bikeWeightKg != null && bikeWeightKg > referenceBikeKg
      ? (bikeWeightKg - referenceBikeKg) * bias
      : 0.0;
  return rider + gear + extra;
}

AirPsiEstimate estimateAirPsi({
  required double riderWeightKg,
  double gearWeightKg = 0,
  double? bikeWeightKg,
  required BikeCategory category,
  required String end,
  double? travelMm,
}) {
  final sag = recommendedSagPct(category, end);
  final loadKg = equivalentRiderKg(
    riderWeightKg: riderWeightKg,
    gearWeightKg: gearWeightKg,
    bikeWeightKg: bikeWeightKg,
    end: end,
  ).clamp(40.0, 220.0);
  final base = end == 'fork'
      ? loadKg * (0.95 + (30 - sag.target) * 0.012)
      : loadKg * (1.15 + (35 - sag.target) * 0.015);
  final travelFactor = travelMm != null && travelMm > 0
      ? (150 / travelMm).clamp(0.85, 1.15)
      : 1.0;
  final psiTarget = (base * travelFactor).round();
  return AirPsiEstimate(
    sag: sag,
    sagMm: travelMm != null && travelMm > 0
        ? targetSagMm(travelMm, sag.target)
        : null,
    loadKg: (loadKg * 10).round() / 10,
    psiMin: (psiTarget * 0.92).round().clamp(30, 999),
    psiMax: (psiTarget * 1.08).round(),
    psiTarget: psiTarget,
    note:
        'Richtwert zum Einstieg — am Rad messen (O-Ring), dann ±5 psi feinjustieren.',
  );
}

double remainingTravelExcessG(double sagPct) {
  final s = sagPct / 100;
  if (s <= 0.05 || s >= 0.9) return double.nan;
  return (1 - s) / s;
}

TravelUsageEstimate? estimateTravelUsage({
  required double gForcePeak,
  required double sagPct,
  required double travelMm,
}) {
  final char = remainingTravelExcessG(sagPct);
  if (char.isNaN || travelMm <= 0 || gForcePeak < 0) return null;
  final excessG = (gForcePeak - 1).clamp(0.0, 99.0);
  final usedRemaining = (excessG / char).clamp(0.0, 1.0);
  final sagFrac = sagPct / 100;
  final usageFrac = sagFrac + (1 - sagFrac) * usedRemaining;
  return TravelUsageEstimate(
    usagePct: (usageFrac * 100).round(),
    usageMm: (travelMm * usageFrac).round(),
    excessG: (excessG * 100).round() / 100,
    charExcessG: (char * 100).round() / 100,
    note:
        'Linear geschätzt aus Peak-g und SAG. Kein Schaftweg, kein Token-Progressiv.',
  );
}

List<String> sagMeasureSteps(String end) {
  final part = end == 'fork' ? 'Gabel' : 'Dämpfer';
  return [
    '$part voll ausfedern, O-Ring an die Dichtung schieben.',
    'Fahrbereit aufsteigen, 3× leicht einfedern.',
    'Vorsichtig absteigen, ohne den O-Ring zu verschieben.',
    'Negativfederweg messen ÷ Gesamtfederweg → SAG %.',
    'Luft nachpumpen oder ablassen bis Zielbereich.',
  ];
}

({double front, double rear}) tireBasePsi(BikeCategory category) {
  return switch (category) {
    BikeCategory.gravel => (front: 36, rear: 38),
    BikeCategory.road => (front: 72, rear: 76),
    BikeCategory.urban || BikeCategory.etrekking => (front: 55, rear: 58),
    BikeCategory.cargo => (front: 50, rear: 62),
    BikeCategory.folding => (front: 60, rear: 62),
    BikeCategory.kids => (front: 35, rear: 38),
    BikeCategory.mtbTrail ||
    BikeCategory.mtbAm ||
    BikeCategory.mtbEnduro ||
    BikeCategory.emtb =>
      (front: 22, rear: 24),
    BikeCategory.dh => (front: 26, rear: 28),
    _ => (front: 45, rear: 48),
  };
}

({double front, double rear}) estimateTireStart({
  required BikeCategory category,
  required double riderWeightKg,
  double? bikeWeightKg,
}) {
  final base = tireBasePsi(category);
  final extra = bikeWeightKg != null && bikeWeightKg > referenceBikeKg
      ? (bikeWeightKg - referenceBikeKg) * 0.3
      : 0.0;
  final scale = ((riderWeightKg + extra) / 78).clamp(0.8, 1.25);
  return (front: (base.front * scale).roundToDouble(), rear: (base.rear * scale).roundToDouble());
}
