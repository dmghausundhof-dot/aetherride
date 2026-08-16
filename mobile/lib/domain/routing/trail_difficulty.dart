/// MTB-Singletrail-Schwierigkeit (IMBA-ähnlich / OSM mtb_scale).
///
/// S3 und S3+ sind getrennt: OSM `3` → S3, `3+` / `4` / `5` / `6` → S3+.
enum TrailDifficulty {
  s0,
  s1,
  s2,
  s3,
  s3plus,
  open,
}

TrailDifficulty parseTrailDifficulty(String? raw) {
  if (raw == null || raw.trim().isEmpty) return TrailDifficulty.open;
  final t = raw.trim().toLowerCase();
  if (t == '—' || t == '-' || t == 'offen' || t == 'open') {
    return TrailDifficulty.open;
  }
  if (t == '0' || t.startsWith('s0')) return TrailDifficulty.s0;
  if (t == '1' || t.startsWith('s1')) return TrailDifficulty.s1;
  if (t == '2' || t.startsWith('s2')) return TrailDifficulty.s2;
  if (t.contains('s3+') ||
      t.startsWith('s4') ||
      t.startsWith('s5') ||
      t.startsWith('s6') ||
      t == '4' ||
      t == '5' ||
      t == '6') {
    return TrailDifficulty.s3plus;
  }
  if (t == '3' || t.startsWith('s3')) return TrailDifficulty.s3;
  if (t.contains('s0')) return TrailDifficulty.s0;
  if (t.contains('s1')) return TrailDifficulty.s1;
  if (t.contains('s2')) return TrailDifficulty.s2;
  if (t.contains('s3+') || t.contains('s4')) return TrailDifficulty.s3plus;
  if (t.contains('s3')) return TrailDifficulty.s3;
  return TrailDifficulty.open;
}

/// Alle S-Stufen in einem Rohwert (inkl. Range `S1–S2`, `S2+`).
Set<TrailDifficulty> trailDifficultiesIn(String? raw) {
  if (raw == null) return const {};
  final t = raw.trim().toLowerCase().replaceAll('–', '-').replaceAll('—', '-');
  if (t.isEmpty || t == '-' || t == 'offen' || t == 'open') {
    return const {};
  }

  TrailDifficulty? fromDigit(String d) {
    if (d.startsWith('0')) return TrailDifficulty.s0;
    if (d.startsWith('1')) return TrailDifficulty.s1;
    if (d.startsWith('2')) return TrailDifficulty.s2;
    if (d.startsWith('4') || d.startsWith('5') || d.startsWith('6')) {
      return TrailDifficulty.s3plus;
    }
    if (d.startsWith('3')) return TrailDifficulty.s3;
    return null;
  }

  final nums = [
    for (final m in RegExp(r's?\s*([0-6])').allMatches(t)) m.group(1)!,
  ];
  final plus = t.contains('+');
  if (nums.isEmpty) {
    final p = parseTrailDifficulty(raw);
    return p == TrailDifficulty.open ? const {} : {p};
  }

  const ranked = <TrailDifficulty>[
    TrailDifficulty.s0,
    TrailDifficulty.s1,
    TrailDifficulty.s2,
    TrailDifficulty.s3,
    TrailDifficulty.s3plus,
  ];

  TrailDifficulty? gradeOf(String d) => fromDigit(d);

  if (nums.length == 1) {
    final g = gradeOf(nums.first);
    if (g == null) return const {};
    if (!plus) return {g};
    final start = ranked.indexOf(g);
    return {for (var i = start; i < ranked.length; i++) ranked[i]};
  }

  final a = gradeOf(nums.first);
  final b = gradeOf(nums.last);
  if (a == null || b == null) {
    final p = parseTrailDifficulty(raw);
    return p == TrailDifficulty.open ? const {} : {p};
  }
  var lo = ranked.indexOf(a);
  var hi = ranked.indexOf(b);
  if (lo < 0 || hi < 0) return {a, b};
  if (hi < lo) {
    final tmp = lo;
    lo = hi;
    hi = tmp;
  }
  if (plus) hi = ranked.length - 1;
  return {for (var i = lo; i <= hi; i++) ranked[i]};
}

String trailDifficultyLabel(TrailDifficulty d) => switch (d) {
      TrailDifficulty.s0 => 'S0',
      TrailDifficulty.s1 => 'S1',
      TrailDifficulty.s2 => 'S2',
      TrailDifficulty.s3 => 'S3',
      TrailDifficulty.s3plus => 'S3+',
      TrailDifficulty.open => 'offen',
    };

/// Menschliche Übersetzung der Rohskala — das, was in Listen/Karten steht.
/// Der technische Wert ([trailDifficultyLabel]) bleibt im Detail sichtbar,
/// z. B. über [trailDifficultyFullLabel].
String trailDifficultyFriendlyLabel(TrailDifficulty d) => switch (d) {
      TrailDifficulty.s0 => 'Leicht',
      TrailDifficulty.s1 => 'Mittel',
      TrailDifficulty.s2 => 'Schwer',
      TrailDifficulty.s3 => 'Anspruchsvoll',
      TrailDifficulty.s3plus => 'Sehr schwer',
      TrailDifficulty.open => 'Nicht eingestuft',
    };

/// Ein Satz, der beide Ebenen zeigt: "Mittel (S2)" bzw. "Nicht eingestuft"
/// ohne technischen Anhang, wenn OSM keinen mtb_scale/sac_scale-Tag hat.
String trailDifficultyFullLabel(TrailDifficulty d) => d == TrailDifficulty.open
    ? trailDifficultyFriendlyLabel(d)
    : '${trailDifficultyFriendlyLabel(d)} (${trailDifficultyLabel(d)})';

/// Komoot/Trailforks-ähnliche Farben für die Karte.
String trailDifficultyColor(TrailDifficulty d) => switch (d) {
      TrailDifficulty.s0 => '#4CAF50',
      TrailDifficulty.s1 => '#8BC34A',
      TrailDifficulty.s2 => '#FFC107',
      TrailDifficulty.s3 => '#FB8C00',
      TrailDifficulty.s3plus => '#E53935',
      TrailDifficulty.open => '#90A4AE',
    };

/// Chip-Reihenfolge ohne „offen“.
const kTrailScaleFilterChips = <TrailDifficulty>[
  TrailDifficulty.s0,
  TrailDifficulty.s1,
  TrailDifficulty.s2,
  TrailDifficulty.s3,
  TrailDifficulty.s3plus,
];
