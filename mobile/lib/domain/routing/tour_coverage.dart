import 'dart:math' as math;

/// Welche Seed-/Katalog-Touren auf Karte und Touren-Liste landen.
///
/// Nähe zuerst; wenn die Nähe dünn ist, mit den nächstgelegenen füllen —
/// kein 3-Karten-Stub, keine erfundenen Tracks.
class TourCoverage {
  TourCoverage._();

  /// Soft-Nähe (Wiesloch→HD/MA plus Karlsruhe/Mainz/Frankfurt).
  static const double nearbyRadiusKm = 90;

  /// Untergrenze, sobald mehr Seeds existieren.
  static const int minListCount = 12;

  /// Obere Grenze für Liste + Map-Pins (MapLibre-Cap).
  static const int maxCount = 32;

  static List<T> pickNearbyThenFill<T>({
    required List<T> items,
    required double Function(T item) distanceKm,
    double nearbyKm = nearbyRadiusKm,
    int minCount = minListCount,
    int maxItems = maxCount,
  }) {
    if (items.isEmpty) return const [];
    final ranked = List<T>.from(items)
      ..sort((a, b) => distanceKm(a).compareTo(distanceKm(b)));
    final nearbyN = ranked.where((e) => distanceKm(e) <= nearbyKm).length;
    final want = math.min(
      maxItems,
      math.max(minCount, nearbyN),
    );
    return ranked.take(math.min(want, ranked.length)).toList();
  }
}
