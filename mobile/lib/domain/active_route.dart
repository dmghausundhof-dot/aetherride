/// Lightweight POI stop on an active nav route (seed / Discover → Ride).
class ActiveRoutePoi {
  const ActiveRoutePoi({
    required this.atMin,
    required this.title,
    this.kind = 'poi',
  });

  final int atMin;
  final String title;
  final String kind;
}

/// Aktive Navigationsroute — Bridge Discover → Ride (Web-Analog).
class ActiveRoute {
  const ActiveRoute({
    required this.id,
    required this.name,
    required this.distanceKm,
    required this.elevationM,
    required this.durationMin,
    required this.coordinates,
    this.mtbScale,
    this.steps = const [],
    this.poiStops = const [],
    this.isLoop = false,
    this.joinAlongM = 0,
    this.gravitySession = false,
  });

  final String id;
  final String name;
  final double distanceKm;
  final double elevationM;
  final int durationMin;
  final String? mtbScale;

  /// [lng, lat] pairs
  final List<List<double>> coordinates;
  final List<NavStep> steps;

  /// Optional seed POIs for upcoming rail (N-07).
  final List<ActiveRoutePoi> poiStops;

  /// True when [coordinates] form a closed loop (Start≈Ziel) at handoff.
  final bool isLoop;

  /// Metres along [coordinates] where the street approach meets the tour.
  /// 0 = no approach (the whole line is the tour).
  final double joinAlongM;

  /// DH-Session: Abfahrt folgen, kein Straßen-Reroute nach dem Join.
  final bool gravitySession;
}

class NavStep {
  const NavStep({
    required this.id,
    required this.instruction,
    required this.distanceAlongM,
    this.streetName,
  });

  final String id;
  final String instruction;
  final double distanceAlongM;

  /// Optional street / road name for glanceable HUD (OSRM `name`, parse, …).
  final String? streetName;
}

enum RideLiveLayer { map, data, suspension }

enum MountCheck { unknown, mounted, handheld }
