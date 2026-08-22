/// Honest surface + mtb:scale on a live route.
///
/// Weather is weather. ORS traildifficulty is SAC-like. Neither becomes S-grade.
library;

class HonestyBand {
  const HonestyBand({
    required this.fromKm,
    required this.toKm,
    this.surface,
    this.scale,
  });

  final double fromKm;
  final double toKm;
  final String? surface;
  final String? scale;
}

/// Wetter bleibt Wetter — nie eine Trail-Schwierigkeit.
String? scaleFromConditionHint(String? hint) {
  return null;
}

/// ORS traildifficulty is SAC-like. Never map onto S0–S3+.
String? scaleFromOrsTrailDifficulty(num? value) {
  return null;
}

bool isHonestOsmSGrade(String? raw) {
  final s = (raw ?? '').trim();
  return s == 'S0' || s == 'S1' || s == 'S2' || s == 'S3' || s == 'S3+';
}

List<HonestyBand> parseHonestyBands(Object? raw, {required bool scale}) {
  if (raw is! List) return const [];
  final out = <HonestyBand>[];
  for (final row in raw) {
    if (row is! Map) continue;
    final from = row['fromKm'] ?? row['from_km'];
    final to = row['toKm'] ?? row['to_km'];
    if (from is! num || to is! num || to.toDouble() <= from.toDouble()) {
      continue;
    }
    final surface = row['surface'];
    final sc = row['scale'] ?? row['mtbScale'];
    out.add(
      HonestyBand(
        fromKm: from.toDouble(),
        toKm: to.toDouble(),
        surface: surface is String && surface.trim().isNotEmpty
            ? surface.trim().toLowerCase()
            : null,
        scale: scale && sc is String && isHonestOsmSGrade(sc.trim())
            ? sc.trim()
            : null,
      ),
    );
  }
  return out;
}

String? dominantHonestScale(Iterable<HonestyBand> bands) {
  final kmBy = <String, double>{};
  var known = 0.0;
  for (final b in bands) {
    final s = b.scale;
    if (!isHonestOsmSGrade(s)) continue;
    final km = b.toKm - b.fromKm;
    if (km <= 0) continue;
    kmBy[s!] = (kmBy[s] ?? 0) + km;
    known += km;
  }
  if (known < 0.08) return null;
  String? best;
  var bestKm = 0.0;
  kmBy.forEach((k, km) {
    if (km > bestKm) {
      best = k;
      bestKm = km;
    }
  });
  return best;
}

/// Auto-recompute owns A+B. Manual CTA only after a failed pass.
bool planManualComputeVisible({
  required bool hasStart,
  required bool hasEnd,
  required bool routingBusy,
  required bool hasComputed,
}) {
  return hasStart && hasEnd && !routingBusy && !hasComputed;
}
