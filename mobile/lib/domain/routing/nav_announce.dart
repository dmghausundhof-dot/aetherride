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
/// Glue follows chrome language: DE auf/Metern, EN onto/meters,
/// FR sur/mètres, IT su/metri, NL op/meter.
String? pickAnnounce({
  required String stepId,
  required String instruction,
  required bool isArrive,
  required double remainingM,
  required double speedKmh,
  required Set<String> spoken,
  String? street,
  String languageCode = 'de',
}) {
  final lang = languageCode.toLowerCase();
  final glue = lang.startsWith('en')
      ? _AnnounceGlue.en
      : lang.startsWith('fr')
          ? _AnnounceGlue.fr
          : lang.startsWith('it')
              ? _AnnounceGlue.it
              : lang.startsWith('nl')
                  ? _AnnounceGlue.nl
                  : _AnnounceGlue.de;
  final tiers = announceDistancesForSpeed(speedKmh)
    ..sort((a, b) => b.compareTo(a));
  for (final tier in tiers) {
    if (remainingM <= tier + 20 &&
        remainingM >= math.max(0, tier - 55)) {
      final key = announceKey(stepId, tier);
      if (spoken.contains(key)) continue;
      spoken.add(key);
      if (isArrive) return instruction;
      final name = street?.trim();
      final hasStreet = name != null && name.isNotEmpty;
      final alreadyNamed = glue.alreadyNamed(instruction);
      final streetBit =
          hasStreet && !alreadyNamed ? '${glue.onto} $name' : '';
      final maneuver = alreadyNamed ? instruction : '$instruction$streetBit';
      final dist = remainingM.round();
      return '$maneuver in $dist ${glue.meters}';
    }
  }
  return null;
}

class _AnnounceGlue {
  const _AnnounceGlue({
    required this.onto,
    required this.meters,
    required this.namedNeedles,
  });

  final String onto;
  final String meters;
  final List<String> namedNeedles;

  bool alreadyNamed(String instruction) =>
      namedNeedles.any(instruction.contains);

  static const de = _AnnounceGlue(
    onto: ' auf',
    meters: 'Metern',
    namedNeedles: [' auf '],
  );
  static const en = _AnnounceGlue(
    onto: ' onto',
    meters: 'meters',
    namedNeedles: [' onto ', ' on '],
  );
  static const fr = _AnnounceGlue(
    onto: ' sur',
    meters: 'mètres',
    namedNeedles: [' sur '],
  );
  static const it = _AnnounceGlue(
    onto: ' su',
    meters: 'metri',
    namedNeedles: [' su '],
  );
  static const nl = _AnnounceGlue(
    onto: ' op',
    meters: 'meter',
    namedNeedles: [' op ', ' naar '],
  );
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
