/// Crowd-Schwierigkeit. Unter n=5 kein Label — kein erfundener Konsens.
const kDifficultyMinN = 5;

enum DifficultyCrowdLabel { easier, asMarked, harder }

class DifficultyCrowd {
  const DifficultyCrowd({
    required this.n,
    this.mean,
    required this.shown,
    this.label,
  });

  final int n;
  final double? mean;
  final bool shown;
  final DifficultyCrowdLabel? label;

  /// API-Feld `difficulty`. `shown` nur wenn die Cloud n≥5 gemeldet hat.
  static DifficultyCrowd fromJson(Object? raw) {
    if (raw is! Map) return const DifficultyCrowd(n: 0, shown: false);
    final n = (raw['n'] as num?)?.round() ?? 0;
    final shown = raw['shown'] == true && n >= kDifficultyMinN;
    final meanRaw = raw['mean'];
    final mean = meanRaw is num && meanRaw.isFinite ? meanRaw.toDouble() : null;
    final label = switch (raw['label']) {
      'easier' => DifficultyCrowdLabel.easier,
      'as_marked' => DifficultyCrowdLabel.asMarked,
      'harder' => DifficultyCrowdLabel.harder,
      _ => null,
    };
    return DifficultyCrowd(
      n: n,
      mean: shown ? mean : null,
      shown: shown,
      label: shown ? label : null,
    );
  }
}

int? parseDifficultyDelta(Object? raw) {
  if (raw is! num || !raw.isFinite) return null;
  final v = raw.round();
  if (v < -2 || v > 2) return null;
  return v;
}

DifficultyCrowd aggregateDifficulty(
  Iterable<Object?> deltas, {
  int minN = kDifficultyMinN,
}) {
  final nums = <int>[];
  for (final d in deltas) {
    final v = parseDifficultyDelta(d);
    if (v != null) nums.add(v);
  }
  final n = nums.length;
  if (n < minN) {
    return DifficultyCrowd(n: n, shown: false);
  }
  final mean = nums.reduce((a, b) => a + b) / n;
  final label = mean < -0.35
      ? DifficultyCrowdLabel.easier
      : mean > 0.35
          ? DifficultyCrowdLabel.harder
          : DifficultyCrowdLabel.asMarked;
  return DifficultyCrowd(n: n, mean: mean, shown: true, label: label);
}
