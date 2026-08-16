import '../../domain/routing/tour_filters.dart';
import '../../domain/routing/trail_difficulty.dart';

/// Komoot/AllTrails-ähnliche Streckendarstellung für Discover-MapLibre.
///
/// Selected = helleres Band der Sportfarbe; Unselected = dunkler, aber lesbar.
/// MTB/DH mit ehrlicher S-Skala färben nach Grade, nicht alles minzgrün.
class DiscoverMapLineStyle {
  DiscoverMapLineStyle._();

  /// Max Tour-Polylines / Warm-Targets / pending Pins auf der Karte.
  static const int mapTourCap = 32;

  /// Parallel Warm-Routing-Jobs (OSRM schonen).
  static const int warmBatchSize = 5;

  static const String selectedRouted = '#00E676';
  static const String unselectedRouted = '#2E7D32';
  static const String selectedApprox = '#78909C';
  static const String unselectedApprox = '#90A4AE';

  /// Eigene Strecken (Import / Recorded) — Accent, klar von Katalog-Grün getrennt.
  static const String ownTrack = '#1565C0';
  static const String ownTrackSelected = '#42A5F5';
  static const String ownTrackCasing = '#0D47A1';

  static const String activeCasing = '#0A1A12';
  static const String mutedCasing = '#1B3A2F';

  /// Anfahrt zur Tour — cyan, nicht dasselbe Grün wie die Runde (HUD-Parität).
  static const String approachCore = '#29B6F6';
  static const String approachCasing = '#0A1A2A';

  static const double activeWidth = 6.5;
  static const double inactiveWidth = 3.4;
  static const double activeOpacity = 1.0;
  static const double inactiveOpacity = 0.72;
  static const double activeCasingWidth = 14;
  static const double mutedCasingWidth = 7.5;
  static const double activeCasingOpacity = 0.95;
  static const double mutedCasingOpacity = 0.42;

  /// Trailnetz unselected — unter Tour-Ribbons halten.
  static const double trailUnselectedOpacity = 0.28;
  static const double trailUnselectedWidth = 2.2;
  static const double trailFilteredOpacity = 0.58;

  static const String selectedGravel = '#E0B04A';
  static const String unselectedGravel = '#C49A3C';
  static const String selectedRoad = '#42A5F5';
  static const String unselectedRoad = '#1565C0';
  static const String selectedUrban = '#26A69A';
  static const String unselectedUrban = '#00897B';
  static const String selectedHiking = '#A1887F';
  static const String unselectedHiking = '#6D4C41';
  static const String selectedDh = '#EF5350';
  static const String unselectedDh = '#C62828';
  static const String selectedEmtb = '#66BB6A';
  static const String unselectedEmtb = '#2E7D32';

  static String ribbonForTour({
    required TourSportKey sport,
    required TrailDifficulty scale,
    required bool selected,
    required bool routed,
  }) {
    if (!routed) {
      return selected ? selectedApprox : unselectedApprox;
    }
    final trailish = sport == TourSportKey.mtb ||
        sport == TourSportKey.emtb ||
        sport == TourSportKey.dh;
    if (trailish && scale != TrailDifficulty.open) {
      return trailDifficultyColor(scale);
    }
    return switch (sport) {
      TourSportKey.gravel => selected ? selectedGravel : unselectedGravel,
      TourSportKey.road => selected ? selectedRoad : unselectedRoad,
      TourSportKey.urban => selected ? selectedUrban : unselectedUrban,
      TourSportKey.hiking => selected ? selectedHiking : unselectedHiking,
      TourSportKey.dh => selected ? selectedDh : unselectedDh,
      TourSportKey.emtb => selected ? selectedEmtb : unselectedEmtb,
      TourSportKey.mtb => selected ? selectedRouted : unselectedRouted,
    };
  }

  static String casingForSport(TourSportKey sport, {required bool active}) {
    if (active) return activeCasing;
    return switch (sport) {
      TourSportKey.gravel => '#4E342E',
      TourSportKey.road => '#0D47A1',
      TourSportKey.urban => '#004D40',
      TourSportKey.hiking => '#3E2723',
      TourSportKey.dh => '#4A0000',
      TourSportKey.mtb || TourSportKey.emtb => mutedCasing,
    };
  }
}
