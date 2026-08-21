import '../../domain/routing/bike_overlay_class.dart';
import '../../domain/routing/browse_map_paint.dart';
import '../../domain/tours/add_route_start.dart';

/// Discover-Chrome: Umkreis und Filter sind zwei Flächen.
///
/// Der Chip „in 35 km“ gehört zur Distanz. Filter trägt Form, Sport, Dauer,
/// S-Skala — nicht noch einmal dieselbe Distanz als erstes.
/// Eine vom Hof gepinnte Tour gewinnt: Chip zeigt den Abstand zum Loop,
/// nicht den 35-km-Default.
abstract final class DiscoverExploreChromeLogic {
  /// Anzeige am Chip, solange kein Distanz-Max gesetzt ist.
  static const defaultAroundKm = 35;

  static int aroundDisplayKm(
    double? maxDistanceKm, {
    double? selectedAwayKm,
  }) {
    if (maxDistanceKm != null && maxDistanceKm > 0) {
      return maxDistanceKm.round();
    }
    if (usesSelectedAway(maxDistanceKm, selectedAwayKm)) {
      return formatAwayKm(selectedAwayKm!);
    }
    return defaultAroundKm;
  }

  /// Umkreis-km nur mit GPS/Start oder lokaler, echter Kartenmitte.
  ///
  /// DACH-Übersicht (47.2, 6.5) und Zoom unter 9 sind kein Origin —
  /// sonst filtert „≤40 km“ um die Jura und liefert 0 Touren.
  static bool aroundOriginIsUsable({
    required bool hasGpsOrStart,
    double? browseLat,
    double? browseLng,
    required double mapZoom,
  }) {
    if (hasGpsOrStart) return true;
    if (browseLat == null || browseLng == null) return false;
    if (isPlaceholderDiscoverCenter(browseLat, browseLng)) return false;
    return isLocalDiscoverZoom(mapZoom);
  }

  /// Distanz-Max sitzt am Umkreis-Chip, nicht im Filter-Badge.
  static bool aroundIsSet(
    double? maxDistanceKm, {
    double? selectedAwayKm,
  }) =>
      (maxDistanceKm != null && maxDistanceKm > 0) ||
      usesSelectedAway(maxDistanceKm, selectedAwayKm);

  /// Hof-/Auswahl-Abstand statt 35-km-Placeholder.
  static bool usesSelectedAway(
    double? maxDistanceKm,
    double? selectedAwayKm,
  ) {
    if (maxDistanceKm != null && maxDistanceKm > 0) return false;
    return selectedAwayKm != null &&
        selectedAwayKm.isFinite &&
        selectedAwayKm > 0;
  }

  /// Loop-Länge für Peek/Liste — nicht der GPS-Abstand.
  static String formatLoopKm(double km) {
    if (!km.isFinite || km <= 0) return '0';
    if (km < 10) return km.toStringAsFixed(1);
    return km.round().toString();
  }

  /// GPS-Abstand zum Loop. 0 = unter 1 km.
  static int formatAwayKm(double km) {
    if (!km.isFinite || km <= 0) return 0;
    if (km < 1) return 0;
    return km.round().clamp(1, 90);
  }

  /// Peek nur bei Hof-Pin oder bewusster Auswahl — nie die erste Nähe-Karte.
  static bool showIdlePeek(String? selectedTourId) =>
      selectedTourId != null && selectedTourId.isNotEmpty;

  /// Nur die Suche klappt die Leiste ein — eine gewählte Tour nicht.
  static bool compactExploreChrome({
    required bool hasSelection,
    required bool searching,
  }) =>
      searching;

  /// Wort „Filter“ bleibt. Die Chip-Zeile scrollt, statt den Text zu kürzen.
  static bool filterChipIconOnly({
    required bool compact,
    required bool aroundUsesAway,
  }) =>
      false;

  /// Kompakte Farblegende unter der Leiste — Layer sitzen im Karteninhalt.
  static bool showExploreLayerRow({
    required bool hasSelection,
    required bool planning,
  }) =>
      !planning;

  /// Layer-Chip markiert, wenn etwas vom Default versteckt ist.
  static bool mapContentsCustomized({
    required bool toursOn,
    required bool trailsOn,
    required bool waysOn,
    required bool hillshadeOn,
    required bool placesOn,
    required bool heatOn,
    required bool heatConsent,
    bool photosOn = true,
    bool satelliteOn = false,
  }) {
    if (!toursOn ||
        !trailsOn ||
        !waysOn ||
        !hillshadeOn ||
        !placesOn ||
        !photosOn) {
      return true;
    }
    if (satelliteOn) return true;
    return !heatOn;
  }

  /// Unter 360 dp eigene Zeile für die Suche — „Route planen“ quetscht sie nicht.
  static bool stackSearchOnOwnRow(double width) => width < 360;

  /// Navigieren bleibt in der Leiste — gleiche Form mit und ohne Tour.
  static bool chromeShowsPlanCta(bool hasSelection) => true;

  /// Suchfeld + Filterchips. Legende sitzt darunter, Layer im Sheet.
  static const double exploreChromeTopPad = 8;
  static const double exploreChromeToLayersGap = 6;
  static const double exploreChromeBodyHeight = 112;

  /// Extra Höhe, wenn Suche und Plan-CTA untereinander stehen.
  static const double exploreChromeStackedExtra = 48;

  static double exploreChromeBodyHeightFor(double width) =>
      exploreChromeBodyHeight +
      (stackSearchOnOwnRow(width) ? exploreChromeStackedExtra : 0);

  /// Vor dem ersten Measure: schmale Leiste nicht mit 112 unter den Ornaments.
  static double resolvedChromeHeight({
    required double measured,
    required double width,
  }) {
    if ((measured - exploreChromeBodyHeight).abs() < 0.5) {
      return exploreChromeBodyHeightFor(width);
    }
    return measured;
  }

  static const double exploreLegendHeight = BrowseMapPaint.legendHeight;
  static const double exploreOrnamentGap = 8;

  /// Extra unter SafeArea für Kompass/Location — unter Leiste + Legende.
  static double ornamentExtraBelowSafe(double chromeHeight) =>
      exploreChromeTopPad +
      chromeHeight +
      exploreChromeToLayersGap +
      exploreLegendHeight +
      exploreOrnamentGap -
      8;

  static double layerRowTop({
    required double statusTop,
    required double chromeHeight,
  }) =>
      statusTop + exploreChromeTopPad + chromeHeight + exploreChromeToLayersGap;

  /// Zweiter Zurück-Schritt im Peek: Auswahl lösen, echter Leerlauf.
  static bool backClearsSelection({
    required String? selectedTourId,
    required bool atPeek,
  }) =>
      atPeek && showIdlePeek(selectedTourId);

  /// Explore-Default: alle Dauer, nicht still ~60 vom Rad.
  static const int defaultDurationMin = 0;

  static const List<int> mapDurationChips = [30, 60, 90, 0];

  /// Trails (S-Skala, Pfad, Schotter) — getrennt von Radwegen.
  static const trailOverlayClasses = {
    BikeOverlayClass.mtb,
    BikeOverlayClass.mtbUnrated,
    BikeOverlayClass.gravel,
  };

  /// Radwege / Asphalt / City — getrennt von Trails.
  static const wayOverlayClasses = {
    BikeOverlayClass.road,
    BikeOverlayClass.urban,
  };

  static Set<BikeOverlayClass> overlayClassesForLayers({
    required bool trailsOn,
    required bool waysOn,
  }) =>
      {
        if (trailsOn) ...trailOverlayClasses,
        if (waysOn) ...wayOverlayClasses,
      };

  /// Asphalt-Punkt nur wenn Radwege an sind.
  static bool legendShowsPaved({required bool waysOn}) => waysOn;

  /// Schotter + Pfad nur wenn Trails an sind.
  static bool legendShowsTrailFamily({required bool trailsOn}) => trailsOn;

  /// ICN-Wand nur ausgeklappt, nie dauerhaft im Leerlauf.
  static bool legendShowsMeshNote({
    required bool isMesh,
    required bool expanded,
  }) =>
      isMesh && expanded;

  /// GPS darf die Kamera nicht vom Hof-Pin auf den Standort ziehen.
  static bool gpsMayRecenterOnUser({
    required String? hofPinLoopId,
    required String? selectedTourId,
  }) {
    if (hofPinLoopId != null && hofPinLoopId.isNotEmpty) return false;
    return !showIdlePeek(selectedTourId);
  }

  /// Hof-/Deep-Link-Pin bleibt stehen, bis die Tour da ist.
  ///
  /// Nähe-Ranking darf die ID nicht löschen, nur weil Seeds noch fehlen
  /// oder die Tour nicht in der gefilterten Liste steht. Nur eine gefundene
  /// Tour außerhalb des Nähe-Radius darf weichen.
  static bool keepHofPin({
    required String? selectedTourId,
    required bool selectedFound,
    required bool selectedNearby,
    required bool loopsAvailable,
  }) {
    if (selectedTourId == null || selectedTourId.isEmpty) return false;
    if (!selectedFound) return true;
    if (!loopsAvailable) return true;
    return selectedNearby;
  }
}
