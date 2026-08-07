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
}

class NavStep {
  const NavStep({
    required this.id,
    required this.instruction,
    required this.distanceAlongM,
  });

  final String id;
  final String instruction;
  final double distanceAlongM;
}

enum RideLiveLayer { map, data, suspension }

enum MountCheck { unknown, mounted, handheld }
