/// MTB-Singletrail-Schwierigkeit (IMBA-ähnlich / OSM mtb_scale).
enum TrailDifficulty {
  s0,
  s1,
  s2,
  s3plus,
  open,
}

TrailDifficulty parseTrailDifficulty(String? raw) {
  if (raw == null || raw.trim().isEmpty) return TrailDifficulty.open;
  final t = raw.trim().toLowerCase();
  if (t == '0' || t.startsWith('s0')) return TrailDifficulty.s0;
  if (t == '1' || t.startsWith('s1')) return TrailDifficulty.s1;
  if (t == '2' || t.startsWith('s2')) return TrailDifficulty.s2;
  if (t == '3' ||
      t == '4' ||
      t == '5' ||
      t == '6' ||
      t.startsWith('s3') ||
      t.startsWith('s4') ||
      t.startsWith('s5')) {
    return TrailDifficulty.s3plus;
  }
  if (t.contains('s0')) return TrailDifficulty.s0;
  if (t.contains('s1')) return TrailDifficulty.s1;
  if (t.contains('s2')) return TrailDifficulty.s2;
  if (t.contains('s3') || t.contains('s4')) return TrailDifficulty.s3plus;
  return TrailDifficulty.open;
}

String trailDifficultyLabel(TrailDifficulty d) => switch (d) {
      TrailDifficulty.s0 => 'S0',
      TrailDifficulty.s1 => 'S1',
      TrailDifficulty.s2 => 'S2',
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
      TrailDifficulty.s3plus => '#E53935',
      TrailDifficulty.open => '#90A4AE',
    };
