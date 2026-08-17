import 'dart:math' as math;

/// Welche Seed-/Katalog-Touren auf Karte und Touren-Liste landen.
///
/// Nur echte Nähe — nie Wien für Heidelberg, nie Hamburg für Kiel.
/// Ist die Region dünn, bleibt die Liste kurz statt mit fremder Landschaft
/// auf 12 Karten aufgefüllt.
class TourCoverage {
  TourCoverage._();

  /// Soft-Nähe (Wiesloch→HD/MA plus Karlsruhe/Mainz/Frankfurt).
  static const double nearbyRadiusKm = 90;

  /// Untergrenze, sobald mehr Seeds *in der Nähe* existieren.
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
    final nearby = items.where((e) => distanceKm(e) <= nearbyKm).toList()
      ..sort((a, b) => distanceKm(a).compareTo(distanceKm(b)));
    if (nearby.isEmpty) return const [];
    // minCount is kept for call-site compatibility; we never invent
    // out-of-radius cards to reach it.
    final want = math.min(maxItems, nearby.length);
    return nearby.take(want).toList();
  }

  /// Nähe zuerst — Sport nur als Tie-Break bei gleichem Abstand.
  ///
  /// Sonst verdeckt eine 32-km-MTB-Runde eine 2-km-Feierabendrunde,
  /// nur weil das aktive Rad E-MTB ist.
  static int compareNearbyThenSport({
    required double distanceKmA,
    required double distanceKmB,
    required bool sportMatchA,
    required bool sportMatchB,
  }) {
    final d = distanceKmA.compareTo(distanceKmB);
    if (d != 0) return d;
    final sa = sportMatchA ? 0 : 1;
    final sb = sportMatchB ? 0 : 1;
    return sa.compareTo(sb);
  }
}
