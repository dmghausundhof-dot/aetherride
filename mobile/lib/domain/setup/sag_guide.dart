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

class AirPsiEstimate {
  const AirPsiEstimate({
    required this.sag,
    required this.psiMin,
    required this.psiMax,
    required this.psiTarget,
    required this.note,
  });
  final SagPct sag;
  final int psiMin;
  final int psiMax;
  final int psiTarget;
  final String note;
}

AirPsiEstimate estimateAirPsi({
  required double riderWeightKg,
  double gearWeightKg = 0,
  required BikeCategory category,
  required String end,
  double? travelMm,
}) {
  final sag = recommendedSagPct(category, end);
  final totalKg = (riderWeightKg + gearWeightKg).clamp(40.0, 200.0);
  final base = end == 'fork'
      ? totalKg * (0.95 + (30 - sag.target) * 0.012)
      : totalKg * (1.15 + (35 - sag.target) * 0.015);
  final travelFactor = travelMm != null && travelMm > 0
      ? (150 / travelMm).clamp(0.85, 1.15)
      : 1.0;
  final psiTarget = (base * travelFactor).round();
  return AirPsiEstimate(
    sag: sag,
    psiMin: (psiTarget * 0.92).round().clamp(30, 999),
    psiMax: (psiTarget * 1.08).round(),
    psiTarget: psiTarget,
    note:
        'Richtwert zum Einstieg — am Bike messen (O-Ring), dann ±5 psi feinjustieren.',
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
