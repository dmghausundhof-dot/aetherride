import '../../domain/routing/tour_filters.dart';
import '../../domain/routing/trail_difficulty.dart';

/// Komoot/AllTrails-ähnliche Streckendarstellung für Discover-MapLibre.
///
/// Selected = helleres Band der Sportfarbe; Unselected = dunkler, aber lesbar.
/// MTB/DH mit ehrlicher S-Skala färben nach Grade, nicht alles minzgrün.
class DiscoverMapLineStyle {
  DiscoverMapLineStyle._();

  /// Max Tour-Polylines / Warm-Targets / pending Pins auf der Karte.
  static const int mapTourCap = 40;

  /// Parallel Warm-Routing-Jobs (OSRM schonen).
  static const int warmBatchSize = 5;

  /// Gewählt: FlowLine-Orange — nicht Mint, das wie ein Radweg wirkt.
  static const String selectedRouted = '#FF6A00';
  static const String unselectedRouted = '#E65100';
  static const String selectedApprox = '#78909C';
  static const String unselectedApprox = '#90A4AE';

  /// Eigene Strecken (Import / Recorded) — Accent, klar von Katalog-Grün getrennt.
  static const String ownTrack = '#1565C0';
  static const String ownTrackSelected = '#42A5F5';
  static const String ownTrackCasing = '#0D47A1';

  static const String activeCasing = '#0A1A12';
  static const String mutedCasing = '#1B3A2F';
  /// Soft halo under the selected ribbon — reads as “live”, not a second route.
  static const String selectedGlow = '#FF8A3D';
  static const double selectedGlowWidth = 18.4;
  static const double selectedGlowOpacity = 0.22;

  /// Anfahrt zur Tour — cyan, nicht dasselbe Grün wie die Runde (HUD-Parität).
  static const String approachCore = '#29B6F6';
  static const String approachCasing = '#0A1A2A';

  /// Live plan outside the loaded pack bbox — sage, like out-of-graph pins.
  static const String packOutside = '#7A8B73';
  static const String packOutsideCasing = '#5E6F58';
  static const double packOutsideWidth = 5.2;
  static const List<double> packOutsideDash = [2.4, 1.8];

  /// GPS→Pin ghost while live streets are still computing.
  static const String pendingAb = '#FF8A3D';
  static const double pendingAbWidth = 3.6;
  static const double pendingAbOpacity = 0.68;
  static const double pendingAbBlur = 0.85;
  static const List<double> pendingAbDash = [2.2, 1.6];

  /// Komoot pull while dragging a pin or reshape disc — solid, not a GPS ghost.
  static const String planRubber = '#FF6A00';
  static const double planRubberWidth = 5.6;
  static const double planRubberOpacity = 0.92;

  /// Unused native fat-hit line. Pointers go through [PlanLineGrabLayer].
  static const String planGrabHalo = '#FF8A3D';
  static const double planGrabHaloWidth = 36;
  static const double planGrabHaloOpacity = 0;

  /// Steep climb/descent overlay on the live plan ribbon (Komoot Höhenfarbe).
  static const String planSteep = '#C2410C';
  static const double planSteepWidth = 6.4;
  /// Surface core on the live ribbon (AllTrails tint; orange casing stays).
  static const String planPaved = '#5C8FBF';
  static const String planGravel = '#E0B04A';
  static const String planTrail = '#C47B3A';
  static const double planSurfaceWidth = 5.2;
  static const String planUnpaved = planTrail;
  static const double planUnpavedWidth = planSurfaceWidth;
  static const double planUnpavedOpacity = 0.94;
  static const List<double> planUnpavedDash = [1.8, 1.2];

  static const double activeWidth = 5.9;
  static const double inactiveWidth = 4.2;
  static const double activeOpacity = 1.0;
  static const double inactiveOpacity = 0.86;
  static const double activeCasingWidth = 11.6;
  static const double mutedCasingWidth = 8.4;
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
      TourSportKey.gravel => selected ? selectedRouted : unselectedGravel,
      TourSportKey.road => selected ? selectedRouted : unselectedRoad,
      TourSportKey.urban => selected ? selectedRouted : unselectedUrban,
      TourSportKey.hiking => selected ? selectedRouted : unselectedHiking,
      TourSportKey.dh => selected ? selectedRouted : unselectedDh,
      TourSportKey.emtb => selected ? selectedRouted : unselectedEmtb,
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
