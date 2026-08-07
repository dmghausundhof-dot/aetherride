/// F-EBK-005 Assist-Modus-Protokollierung (Port assistLog.ts) — nur Schätzung.
library;

typedef AssistMode = String; // off | eco | tour | sport | turbo

class AssistSegment {
  const AssistSegment({
    required this.id,
    required this.mode,
    required this.source,
    required this.startOffsetSec,
    required this.endOffsetSec,
    required this.distanceM,
    required this.avgSpeedKmh,
    required this.label,
    this.avgRiderPowerW,
    this.estimatedWh,
  });

  final String id;
  final AssistMode mode;
  final String source; // oem | estimated | manual
  final int startOffsetSec;
  final int endOffsetSec;
  final double distanceM;
  final double avgSpeedKmh;
  final double? avgRiderPowerW;
  final double? estimatedWh;
  final String label;
}

class AssistRideSummary {
  const AssistRideSummary({
    required this.segments,
    required this.dominantMode,
    required this.modeSharePct,
    required this.estimatedTotalWh,
    required this.hasEstimates,
    required this.disclaimer,
    required this.sourceLabel,
  });

  final List<AssistSegment> segments;
  final AssistMode dominantMode;
  final Map<AssistMode, int> modeSharePct;
  final int estimatedTotalWh;
  final bool hasEstimates;
  final String disclaimer;
  final String sourceLabel;
}

const assistWhFactor = <AssistMode, double>{
  'off': 0.15,
  'eco': 0.65,
  'tour': 1.0,
  'sport': 1.45,
  'turbo': 2.1,
};

({AssistMode mode, double confidence}) estimateModeFromSignature({
  required double speedKmh,
  required double riderPowerW,
  double gradeApprox = 0.03,
}) {
  if (gradeApprox > 0.06 && speedKmh > 14 && riderPowerW < 120) {
    return (mode: 'turbo', confidence: 0.55);
  }
  if (gradeApprox > 0.04 && speedKmh > 12 && riderPowerW < 140) {
    return (mode: 'sport', confidence: 0.5);
  }
  if (speedKmh < 10 && riderPowerW > 160) {
    return (mode: 'eco', confidence: 0.45);
  }
  if (riderPowerW > 180 && speedKmh < 18) {
    return (mode: 'eco', confidence: 0.4);
  }
  return (mode: 'tour', confidence: 0.35);
}

AssistRideSummary buildEstimatedAssistLog({
  required int durationSec,
  required double distanceM,
  required double elevationGainM,
  double? avgRiderPower,
  double? avgSpeedKmh,
  AssistMode? preferredMode,
}) {
  final duration = durationSec < 60 ? 60 : durationSec;
  final dist = distanceM < 100 ? 100.0 : distanceM;
  final speed =
      avgSpeedKmh ?? (dist / 1000 / (duration / 3600));
  final power = avgRiderPower ?? 110;
  final grade = elevationGainM / (dist < 1 ? 1 : dist);
  final climbShare = (0.2 + grade * 8).clamp(0.0, 0.55);

  final segments = <AssistSegment>[];
  final t1 = (duration * 0.25).round();
  final d1 = (dist * 0.28).roundToDouble();
  final m1 = preferredMode == 'eco' ? 'eco' : 'tour';
  segments.add(
    AssistSegment(
      id: 'seg-1',
      mode: m1,
      source: 'estimated',
      startOffsetSec: 0,
      endOffsetSec: t1,
      distanceM: d1,
      avgSpeedKmh: speed * 0.95,
      avgRiderPowerW: power + 10,
      estimatedWh: (d1 / 1000) * 10 * (assistWhFactor[m1] ?? 1),
      label: 'Schätzung: ${m1.toUpperCase()} (Anfahrt)',
    ),
  );

  final climbEst = estimateModeFromSignature(
    speedKmh: speed * 0.7,
    riderPowerW: power * 0.8,
    gradeApprox: grade > 0.07 ? grade : 0.07,
  );
  final t2 = (duration * climbShare).round();
  final d2 = (dist * 0.35).roundToDouble();
  segments.add(
    AssistSegment(
      id: 'seg-2',
      mode: climbEst.mode,
      source: 'estimated',
      startOffsetSec: t1,
      endOffsetSec: t1 + t2,
      distanceM: d2,
      avgSpeedKmh: speed * 0.75,
      avgRiderPowerW: power * 0.85,
      estimatedWh:
          (d2 / 1000) * 14 * (assistWhFactor[climbEst.mode] ?? 1),
      label:
          'Schätzung: ${climbEst.mode.toUpperCase()} (Steigung, ${(climbEst.confidence * 100).round()} %)',
    ),
  );

  final d3 = dist - d1 - d2;
  segments.add(
    AssistSegment(
      id: 'seg-3',
      mode: 'tour',
      source: 'estimated',
      startOffsetSec: t1 + t2,
      endOffsetSec: duration,
      distanceM: d3 < 0 ? 0 : d3,
      avgSpeedKmh: speed,
      avgRiderPowerW: power,
      estimatedWh:
          ((d3 < 0 ? 0 : d3) / 1000) * 9 * (assistWhFactor['tour'] ?? 1),
      label: 'Schätzung: TOUR (Rest)',
    ),
  );

  return summarizeAssist(segments);
}

AssistRideSummary summarizeAssist(List<AssistSegment> segments) {
  final totals = <AssistMode, double>{
    'off': 0,
    'eco': 0,
    'tour': 0,
    'sport': 0,
    'turbo': 0,
  };
  var totalDist = 0.0;
  var wh = 0.0;
  for (final s in segments) {
    totals[s.mode] = (totals[s.mode] ?? 0) + s.distanceM;
    totalDist += s.distanceM;
    wh += s.estimatedWh ?? 0;
  }
  final share = <AssistMode, int>{};
  for (final e in totals.entries) {
    share[e.key] =
        totalDist > 0 ? ((e.value / totalDist) * 100).round() : 0;
  }
  final dominant = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return AssistRideSummary(
    segments: segments,
    dominantMode: dominant.isEmpty ? 'tour' : dominant.first.key,
    modeSharePct: share,
    estimatedTotalWh: wh.round(),
    hasEstimates: segments.any((s) => s.source == 'estimated'),
    disclaimer:
        'Schätzungen aus Leistungs-/Geschwindigkeitssignatur — kein OEM-Auslesen. Keine Motorsteuerung (F-EBK-000).',
    sourceLabel:
        'Bosch Battery Guide · BIKE Magazin · Spec F-EBK-005',
  );
}
