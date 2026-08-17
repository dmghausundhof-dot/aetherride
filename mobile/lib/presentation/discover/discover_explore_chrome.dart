/// Discover-Chrome: Umkreis und Filter sind zwei Flächen.
///
/// Der Chip „in 35 km“ gehört zur Distanz. Filter trägt Form, Sport, Dauer,
/// S-Skala — nicht noch einmal dieselbe Distanz als erstes.
abstract final class DiscoverExploreChromeLogic {
  /// Anzeige am Chip, solange kein Distanz-Max gesetzt ist.
  static const defaultAroundKm = 35;

  static int aroundDisplayKm(double? maxDistanceKm) {
    if (maxDistanceKm != null && maxDistanceKm > 0) {
      return maxDistanceKm.round();
    }
    return defaultAroundKm;
  }

  /// Distanz-Max sitzt am Umkreis-Chip, nicht im Filter-Badge.
  static bool aroundIsSet(double? maxDistanceKm) =>
      maxDistanceKm != null && maxDistanceKm > 0;
}
