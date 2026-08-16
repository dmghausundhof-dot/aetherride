import '../active_route.dart';
import '../community/poi_from_vias.dart';
import '../routing/tour_nav_geometry.dart';
import '../saved_route.dart';

/// Meine-Play: HUD nur mit echtem Track. Kein stiller Tab ohne Autostart.
ActiveRoute? activeRouteFromSaved(SavedRouteEntry s) {
  if (s.coordinates.length < 2) return null;
  return ActiveRoute(
    id: s.id,
    name: s.name,
    distanceKm: s.distanceKm,
    elevationM: s.elevationM,
    durationMin: s.durationMin,
    coordinates: s.coordinates,
    isLoop: navGeometryIsLoop(s.coordinates),
    poiStops: poiStopsFromVias(
      vias: labeledViasFromSaved(s.waypoints),
      coordinates: s.coordinates,
      durationMin: s.durationMin,
    ),
  );
}
