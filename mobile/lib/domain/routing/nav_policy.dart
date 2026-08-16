import '../bike.dart';
import 'trail_difficulty.dart';

/// Session from the active garage bike — not a single A→B costing profile.
enum NavSessionMode {
  /// Rennrad / City: bicycle costing, turn-by-turn.
  street,

  /// Trail / Enduro / E-MTB: bicycle to the trail, then follow.
  pedal,

  /// DH: Auto/Fuß zum Einstieg, Abfahrt folgen, kein Pedal-up.
  gravity,
}

/// How the rider reaches the trailhead. Bike sets the default; sheet can override.
enum ApproachKind {
  auto,
  walk,
  bicycle,
  atStart,
}

/// Walk instead of driving when the trailhead is this close (km).
const double kGravityWalkMaxKm = 1.5;

/// Skip approach entirely when already at the entry.
const double kGravityAtStartMaxKm = 0.08;

class NavPolicy {
  const NavPolicy({
    required this.session,
    required this.orientByElevation,
    required this.allowPedalConnectors,
    required this.stayOnDescent,
    required this.skipEngineTrackReroute,
  });

  final NavSessionMode session;
  final bool orientByElevation;
  final bool allowPedalConnectors;

  /// Off-trail on the descent: stay in the corridor, do not rejoin via roads.
  final bool stayOnDescent;

  /// Do not replace trail geometry with a live bicycle A→B (`planNavAlongTrack`).
  final bool skipEngineTrackReroute;

  bool get isGravity => session == NavSessionMode.gravity;
}

NavPolicy navPolicyForBike(BikeCategory category) => switch (category) {
      BikeCategory.dh => const NavPolicy(
          session: NavSessionMode.gravity,
          orientByElevation: true,
          allowPedalConnectors: false,
          stayOnDescent: true,
          skipEngineTrackReroute: true,
        ),
      BikeCategory.mtbEnduro => const NavPolicy(
          session: NavSessionMode.pedal,
          orientByElevation: true,
          allowPedalConnectors: true,
          stayOnDescent: true,
          skipEngineTrackReroute: true,
        ),
      BikeCategory.mtbTrail ||
      BikeCategory.mtbAm ||
      BikeCategory.emtb =>
        const NavPolicy(
          session: NavSessionMode.pedal,
          orientByElevation: false,
          allowPedalConnectors: true,
          stayOnDescent: false,
          skipEngineTrackReroute: false,
        ),
      BikeCategory.hiking => const NavPolicy(
          session: NavSessionMode.pedal,
          orientByElevation: false,
          allowPedalConnectors: false,
          stayOnDescent: false,
          skipEngineTrackReroute: false,
        ),
      BikeCategory.road ||
      BikeCategory.urban ||
      BikeCategory.cargo ||
      BikeCategory.folding ||
      BikeCategory.kids ||
      BikeCategory.gravel ||
      BikeCategory.etrekking =>
        const NavPolicy(
          session: NavSessionMode.street,
          orientByElevation: false,
          allowPedalConnectors: true,
          stayOnDescent: false,
          skipEngineTrackReroute: false,
        ),
    };

ApproachKind suggestedApproachKind({
  required NavPolicy policy,
  required double distanceKm,
}) {
  if (!policy.isGravity) return ApproachKind.bicycle;
  if (!distanceKm.isFinite || distanceKm < 0) return ApproachKind.walk;
  if (distanceKm <= kGravityAtStartMaxKm) return ApproachKind.atStart;
  if (distanceKm <= kGravityWalkMaxKm) return ApproachKind.walk;
  return ApproachKind.auto;
}

/// True when the rider is already on the descent (past the approach join).
bool gravityOnDescent({
  required bool gravitySession,
  required double alongRouteM,
  required double joinAlongM,
}) {
  if (!gravitySession) return false;
  if (joinAlongM <= 8) return true;
  return alongRouteM >= joinAlongM - 20;
}

/// Street bikes must not be secretly MTB-routed onto technical trails.
/// Unrated OSM ways stay browsable; known S2+ on a road bike is a refuse.
bool trailFitsBike({
  required BikeCategory bike,
  required TrailDifficulty scale,
}) {
  if (scale == TrailDifficulty.open) return true;
  switch (bike) {
    case BikeCategory.road:
    case BikeCategory.urban:
    case BikeCategory.cargo:
    case BikeCategory.folding:
    case BikeCategory.kids:
      return scale == TrailDifficulty.s0;
    case BikeCategory.gravel:
    case BikeCategory.etrekking:
      return scale != TrailDifficulty.s3 && scale != TrailDifficulty.s3plus;
    default:
      return true;
  }
}
