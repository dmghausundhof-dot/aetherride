import '../../data/routing/geocode_client.dart';

/// Web-Parität: Navigieren öffnet A→B mit Ziel-Pick.
class BeginNavigateIntent {
  const BeginNavigateIntent({
    required this.pickEnd,
    this.destination,
  });

  final bool pickEnd;
  final GeocodeHit? destination;
}

/// Orts-Chip im Plan wird Ziel, sonst nur Kartenflug.
bool placeHitAppliesAsDestination({required bool navigating}) => navigating;

/// Explore long-press opens Plan with a browse pin (Web `discoverExploreMapTapOpensPlan`).
/// Short-tap stays trail/tour inspect — not A→B.
bool discoverExploreMapTapOpensPlan({
  required bool planning,
  required bool picking,
}) =>
    !picking && !planning;

/// Navigieren: Ziel tippen/suchen, optional letzter Ort als B.
BeginNavigateIntent beginNavigateIntent({
  required bool hasEnd,
  GeocodeHit? lastPlace,
  List<GeocodeHit> pendingHits = const [],
}) {
  final pending = pendingHits.isEmpty ? null : pendingHits.first;
  return BeginNavigateIntent(
    pickEnd: true,
    destination: hasEnd ? null : lastPlace ?? pending,
  );
}
