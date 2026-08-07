import 'dart:math' as math;

import '../ride.dart';

/// F-SET-003 Bracketing-Auswertung (Port src/lib/setup/bracketing.ts).

class BracketingRun {
  const BracketingRun({
    required this.configValue,
    required this.segmentTimeSec,
    required this.flowScore,
    required this.impactHardness,
    required this.subjectiveRating,
  });

  final double configValue;
  final double segmentTimeSec;
  final double flowScore;
  final double impactHardness;
  final double subjectiveRating;
}

class BracketingSeries {
  const BracketingSeries({
    required this.adjusterKey,
    required this.rangeFrom,
    required this.rangeTo,
    required this.step,
    required this.runs,
  });

  final String adjusterKey;
  final double rangeFrom;
  final double rangeTo;
  final double step;
  final List<BracketingRun> runs;
}

class ConfigStats {
  const ConfigStats({
    required this.value,
    required this.n,
    required this.meanTime,
    required this.meanFlow,
    required this.meanImpact,
    required this.meanSubjective,
    required this.sdTime,
    required this.sdFlow,
  });

  final double value;
  final int n;
  final double meanTime;
  final double meanFlow;
  final double meanImpact;
  final double meanSubjective;
  final double sdTime;
  final double sdFlow;
}

class BracketingEvaluation {
  const BracketingEvaluation({
    required this.noProvenDifference,
    required this.summary,
    required this.ready,
    required this.missingRuns,
    this.provenBestValue,
  });

  final bool noProvenDifference;
  final double? provenBestValue;
  final String summary;
  final bool ready;
  final List<({double value, int have, int need})> missingRuns;
}

double _mean(List<double> xs) {
  if (xs.isEmpty) return 0;
  return xs.reduce((a, b) => a + b) / xs.length;
}

double _sd(List<double> xs) {
  if (xs.length < 2) return 0;
  final m = _mean(xs);
  final v =
      xs.map((x) => (x - m) * (x - m)).reduce((a, b) => a + b) / (xs.length - 1);
  return math.sqrt(v);
}

ConfigStats statsForConfig(double value, List<BracketingRun> runs) {
  return ConfigStats(
    value: value,
    n: runs.length,
    meanTime: _mean(runs.map((r) => r.segmentTimeSec).toList()),
    meanFlow: _mean(runs.map((r) => r.flowScore).toList()),
    meanImpact: _mean(runs.map((r) => r.impactHardness).toList()),
    meanSubjective: _mean(runs.map((r) => r.subjectiveRating).toList()),
    sdTime: _sd(runs.map((r) => r.segmentTimeSec).toList()),
    sdFlow: _sd(runs.map((r) => r.flowScore).toList()),
  );
}

double _composite(ConfigStats s) {
  return s.meanFlow * 0.35 +
      s.meanSubjective * 20 * 0.25 +
      (1 / math.max(1, s.meanTime)) * 100 * 0.2 +
      (10 - math.min(10, s.meanImpact)) * 10 * 0.2;
}

double _pooledSdFlow(ConfigStats a, ConfigStats b) {
  final n1 = a.n;
  final n2 = b.n;
  if (n1 + n2 <= 2) return 0;
  return math.sqrt(
    ((n1 - 1) * a.sdFlow * a.sdFlow + (n2 - 1) * b.sdFlow * b.sdFlow) /
        (n1 + n2 - 2),
  );
}

/// MVP: zwei Varianten ±step um aktuellen Wert (Blind-Hinweis in UI).
BracketingSeries createBlindPair({
  required String adjusterKey,
  required double currentValue,
  double step = 2,
  List<BracketingRun> runs = const [],
}) {
  return BracketingSeries(
    adjusterKey: adjusterKey,
    rangeFrom: currentValue - step,
    rangeTo: currentValue + step,
    step: step * 2,
    runs: runs,
  );
}

/// Baut Bracketing-Runs aus gespeicherten Rides (Feedback + Summary).
/// Ordnet Runs abwechselnd A/B zu, wenn genug Rides mit Feedback vorhanden.
List<BracketingRun> runsFromRides({
  required List<RideRecord> rides,
  required double configA,
  required double configB,
  String? bikeId,
}) {
  final filtered = [
    for (final r in rides)
      if (bikeId == null || r.bikeId == bikeId)
        if (r.feedback != null && r.feedback!.skipped != true) r,
  ];
  if (filtered.isEmpty) return const [];

    final runs = <BracketingRun>[];
  for (var i = 0; i < filtered.length; i++) {
    final r = filtered[i];
    final cfg = i.isEven ? configA : configB;
    final flow = (r.summary['avgFlow'] as num?)?.toDouble() ?? 60;
    final feel = (r.feedback?.overallFeel ?? 3).toDouble();
    final harsh = r.feedback?.smallBump == 'harsh'
        ? 6.0
        : r.feedback?.frontFeel == 'too_firm'
            ? 5.0
            : 3.5;
    runs.add(
      BracketingRun(
        configValue: cfg,
        segmentTimeSec: (r.movingTimeSec > 0 ? r.movingTimeSec : 600).toDouble(),
        flowScore: flow.clamp(0, 100),
        impactHardness: harsh.clamp(1, 10),
        subjectiveRating: feel.clamp(1, 5),
      ),
    );
  }
  return runs;
}

/// Demo-Runs nur als Fallback wenn keine Ride-Daten.
List<BracketingRun> syntheticBracketRuns(double a, double b) => [
      BracketingRun(
        configValue: a,
        segmentTimeSec: 120,
        flowScore: 70,
        impactHardness: 4,
        subjectiveRating: 3,
      ),
      BracketingRun(
        configValue: a,
        segmentTimeSec: 118,
        flowScore: 72,
        impactHardness: 3.5,
        subjectiveRating: 4,
      ),
      BracketingRun(
        configValue: b,
        segmentTimeSec: 125,
        flowScore: 68,
        impactHardness: 5,
        subjectiveRating: 3,
      ),
      BracketingRun(
        configValue: b,
        segmentTimeSec: 122,
        flowScore: 69,
        impactHardness: 4.5,
        subjectiveRating: 3,
      ),
    ];

BracketingEvaluation evaluateBracketingSeries(BracketingSeries series) {
  final grouped = <double, List<BracketingRun>>{};
  for (final r in series.runs) {
    grouped.putIfAbsent(r.configValue, () => []).add(r);
  }
  final missing = <({double value, int have, int need})>[];
  final expected = <double>[];
  for (var v = series.rangeFrom; v <= series.rangeTo + 1e-9; v += series.step) {
    expected.add((v * 1000).round() / 1000);
  }
  for (final v in expected) {
    final have = grouped[v]?.length ?? 0;
    if (have < 2) missing.add((value: v, have: have, need: 2));
  }

  if (missing.isNotEmpty || grouped.keys.length < 2) {
    return BracketingEvaluation(
      noProvenDifference: false,
      ready: false,
      missingRuns: missing,
      summary: missing.isNotEmpty
          ? 'Noch nicht auswertbar: je Konfiguration ≥ 2 Runs. Fehlt: ${missing.map((m) => '${m.value} (${m.have}/2)').join(', ')}'
          : 'Mindestens zwei Konfigurationen mit je ≥ 2 Runs nötig.',
    );
  }

  final stats = [
    for (final e in grouped.entries) statsForConfig(e.key, e.value),
  ]..sort((a, b) => a.value.compareTo(b.value));

  var provenBest = stats.first;
  for (final s in stats.skip(1)) {
    if (_composite(s) > _composite(provenBest)) provenBest = s;
  }

  var anyProven = false;
  for (var i = 0; i < stats.length; i++) {
    for (var j = i + 1; j < stats.length; j++) {
      final pooled = _pooledSdFlow(stats[i], stats[j]);
      final delta = (stats[i].meanFlow - stats[j].meanFlow).abs();
      if (pooled > 0 && delta > 1.5 * pooled) anyProven = true;
    }
  }

  if (!anyProven) {
    return const BracketingEvaluation(
      noProvenDifference: true,
      ready: true,
      missingRuns: [],
      summary:
          'Kein belegbarer Unterschied (Δ ≤ 1,5× SD). Blind-Test: Setups wirkten praktisch gleich.',
    );
  }

  return BracketingEvaluation(
    noProvenDifference: false,
    provenBestValue: provenBest.value,
    ready: true,
    missingRuns: const [],
    summary:
        'Belegbarer Vorteil bei ${series.adjusterKey} = ${provenBest.value.toStringAsFixed(0)} (Composite-Score).',
  );
}
