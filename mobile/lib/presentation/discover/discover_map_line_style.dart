/// Komoot/AllTrails-ähnliche Streckendarstellung für Discover-MapLibre.
///
/// Selected = helles Grün + dickes Casing; Unselected routed = dunkleres Grün,
/// gedämpft aber noch als Ribbon lesbar (nicht „unsichtbar“).
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
}
