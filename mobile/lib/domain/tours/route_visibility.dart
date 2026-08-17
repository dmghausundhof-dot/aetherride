import '../saved_route.dart';
import '../saved_route_note.dart';
import 'tour_akte.dart';
import '../routing/tour_filters.dart';

/// Sichtbarkeit gespeicherter Touren. Default privat. Kein stilles GPS.
abstract final class RouteVisibility {
  static const private = 'private';
  static const shared = 'shared';

  static String visibilityOf(SavedRouteMeta? meta) {
    return meta?.visibility == shared ? shared : private;
  }

  static bool isShared(SavedRouteMeta? meta) => visibilityOf(meta) == shared;

  static String? stimmenTourIdOf(String routeId, [SavedRouteMeta? meta]) {
    final m = meta ?? SavedRouteMeta.empty;
    final catalog = catalogTourIdOf(routeId, m);
    if (catalog != null) return catalog;
    if (isShared(m)) return routeId;
    return null;
  }

  static bool allowsStimmen(String routeId, [SavedRouteMeta? meta]) {
    return stimmenTourIdOf(routeId, meta) != null;
  }

  static bool visibleInPublicExplore(SavedRouteMeta? meta) => isShared(meta);

  static bool mayContributeSavedGeometry(SavedRouteMeta? meta) =>
      isShared(meta);

  /// Freeride ja; private GPX-Akte nein; Katalog-Join oder Freigabe ja.
  static bool mayContributeRide(String? routeId, SavedRouteMeta? meta) {
    if (routeId == null || routeId.trim().isEmpty) return true;
    if (isShared(meta)) return true;
    return catalogTourIdOf(routeId, meta ?? SavedRouteMeta.empty) != null;
  }

  static List<SavedRouteEntry> filter(
    List<SavedRouteEntry> routes,
    TourVisibilityKey scope,
    Map<String, SavedRouteMeta> metas,
  ) {
    if (scope == TourVisibilityKey.allMine) return routes;
    return [
      for (final r in routes)
        if (TourFilters.visibilityMatches(visibilityOf(metas[r.id]), scope)) r,
    ];
  }

  static List<String> shareableRouteIds(
    List<String> routeIds,
    Map<String, SavedRouteMeta> metas,
  ) {
    return [
      for (final id in routeIds)
        if (isShared(metas[id]) ||
            catalogTourIdOf(id, metas[id] ?? SavedRouteMeta.empty) != null)
          id,
    ];
  }

  static String shareHonesty({
    required String routeId,
    required bool hasTrack,
    SavedRouteMeta? meta,
  }) {
    final catalog = catalogTourIdOf(routeId, meta ?? SavedRouteMeta.empty);
    if (catalog != null && !hasTrack) {
      return 'Katalog-Tour ist schon freigegeben. Freigeben macht deine Tour '
          'teilbar — der Link zeigt Name und Stats, keinen privaten Extra-Track.';
    }
    if (hasTrack) {
      return 'Freigeben erzeugt einen Link. Der Link enthält eine vereinfachte '
          'Spur (Koordinaten), nicht nur den Namen. Zurück auf Privat nimmt die '
          'Tour aus Filtern und speichert den Widerruf auf dem Server, wenn du '
          'eingeloggt bist. Ohne Login gilt er nur auf diesem Gerät.';
    }
    return 'Freigeben erzeugt einen Link mit Name und Stats — ohne Track, '
        'weil keiner gespeichert ist.';
  }
}
