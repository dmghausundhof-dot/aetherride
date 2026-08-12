import 'dart:math' as math;

import '../active_route.dart';

/// Spec F-NAV-003: Ansagen 400 / 150 / 30 m; bei v>25 km/h zeitbasiert.
const announceDistancesM = [400, 150, 30];

List<int> announceDistancesForSpeed(double speedKmh) {
  if (speedKmh > 25) {
    final ms = (speedKmh * 1000) / 3600;
    return [
      (ms * 8).round(),
      (ms * 4).round(),
      (ms * 1.5).round(),
    ];
  }
  return List<int>.from(announceDistancesM);
}

String announceKey(String stepId, int tierM) => '$stepId@$tierM';

/// Welche Ansage-Stufe gerade fällig ist (Port `pickAnnounce`).
String? pickAnnounce({
  required String stepId,
  required String instruction,
  required bool isArrive,
  required double remainingM,
  required double speedKmh,
  required Set<String> spoken,
  String? street,
}) {
  final tiers = announceDistancesForSpeed(speedKmh)
    ..sort((a, b) => b.compareTo(a));
  for (final tier in tiers) {
    if (remainingM <= tier + 20 &&
        remainingM >= math.max(0, tier - 55)) {
      final key = announceKey(stepId, tier);
      if (spoken.contains(key)) continue;
      spoken.add(key);
      if (isArrive) return instruction;
      final streetBit = (street != null && street.trim().isNotEmpty)
          ? ' auf ${street.trim()}'
          : '';
      final maneuver = instruction.contains(' auf ') ||
              instruction.contains(' onto ')
          ? instruction
          : '$instruction$streetBit';
      return '$maneuver in ${remainingM.round()} Metern';
    }
  }
  return null;
}

/// Nächster Engine-Schritt voraus der aktuellen Distanz entlang der Route.
({NavStep step, double remainingM})? nextRouteStep(
  List<NavStep> steps,
  double distanceAlongM,
) {
  for (final step in steps) {
    final remaining = step.distanceAlongM - distanceAlongM;
    if (remaining > 12) {
      return (step: step, remainingM: remaining);
    }
  }
  return null;
}
