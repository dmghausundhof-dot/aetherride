import '../../data/routing/geocode_client.dart';

/// Browse search: tour-name filter while typing, place fly on submit.
abstract final class BrowsePlaceSearch {
  /// Submit should geocode when the query is a place (or coords), not only
  /// when it already matches a visible tour title.
  static bool shouldFlyToPlace({
    required String query,
    required Iterable<String> visibleTourNames,
  }) {
    final q = query.trim();
    if (q.length < 2) return false;
    if (geocodeHitFromCoordinates(q) != null) return true;
    final lower = q.toLowerCase();
    var strong = 0;
    for (final name in visibleTourNames) {
      final n = name.toLowerCase();
      if (n == lower || n.startsWith(lower)) strong++;
    }
    // Exact / prefix tour hit → keep the list; still fly if nothing matches.
    return strong == 0;
  }

  /// While typing, still offer place hits alongside tour-name filtering.
  static bool shouldOfferPlaceHits(String query) {
    final q = query.trim();
    if (q.length < 3) return false;
    return geocodeHitFromCoordinates(q) == null;
  }
}
