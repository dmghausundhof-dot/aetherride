/// Live-nav map ribbon + follow framing (N-MAP-02).
///
/// Discover browse stays loud (`DiscoverMapLineStyle`). The ride map is
/// narrower so junctions stay readable, and follow looks ahead on the
/// remaining line instead of centering the puck.
library;

import 'route_progress.dart';

class NavFollowFraming {
  const NavFollowFraming({
    required this.zoom,
    required this.tilt,
    required this.lookAheadM,
  });

  final double zoom;
  final double tilt;

  /// Metres along the remaining route used as camera target (0 = puck).
  final double lookAheadM;
}

/// Heading-up looks ~100 m ahead; trail zoom is slightly wider.
NavFollowFraming navFollowFraming({
  required bool northUp,
  required bool trailish,
}) {
  if (northUp) {
    return NavFollowFraming(
      zoom: trailish ? 15.2 : 16.0,
      tilt: 0,
      lookAheadM: 0,
    );
  }
  return NavFollowFraming(
    zoom: trailish ? 15.4 : 16.2,
    tilt: 48,
    lookAheadM: trailish ? 140 : 110,
  );
}

class NavRibbonWidths {
  const NavRibbonWidths({
    required this.remainingCasing,
    required this.remainingCore,
    required this.traveledCasing,
    required this.traveledCore,
    required this.gpsCasing,
    required this.gpsCore,
  });

  final double remainingCasing;
  final double remainingCore;
  final double traveledCasing;
  final double traveledCore;
  final double gpsCasing;
  final double gpsCore;
}

/// Scale line width with zoom. At z16 remaining core ≈ Discover active (6.5).
NavRibbonWidths navRibbonWidths(double zoom) {
  final z = zoom.clamp(12.0, 18.0);
  final t = ((z - 14.0) / 4.0).clamp(0.0, 1.0);
  final s = 0.75 + t * 0.43;
  return NavRibbonWidths(
    remainingCasing: 13 * s,
    remainingCore: 6.5 * s,
    traveledCasing: 7.5 * s,
    traveledCore: 3.4 * s,
    gpsCasing: 8 * s,
    gpsCore: 4.5 * s,
  );
}

abstract final class NavMapColors {
  static const remainingCasing = '#0A1A12';
  static const remainingCore = '#00E676';
  static const traveledCasing = '#263238';
  static const traveledCore = '#78909C';
  static const gpsCasing = '#BF360C';
  static const gpsCore = '#FF6A00';

  /// Street approach to the tour join — not the same green as the round.
  static const approachCasing = '#0A1A2A';
  static const approachCore = '#29B6F6';
}

/// Remaining ribbon split at [joinAlongM] so Anfahrt ≠ Runde.
class NavPhaseRibbons {
  const NavPhaseRibbons({
    required this.traveled,
    required this.approachRemaining,
    required this.tourRemaining,
    this.joinLngLat,
  });

  final List<List<double>> traveled;
  final List<List<double>> approachRemaining;
  final List<List<double>> tourRemaining;
  final List<double>? joinLngLat;
}

/// Cut traveled / approach-remaining / tour-remaining from one merged polyline.
NavPhaseRibbons navPhaseRibbons({
  required List<List<double>> coordinates,
  required double alongRouteM,
  required double joinAlongM,
}) {
  final slice = sliceRouteAtAlongM(coordinates, alongRouteM);
  final joinPt = joinAlongM > 0 && coordinates.length >= 2
      ? pointAlongRoute(coordinates, joinAlongM)
      : null;

  if (joinAlongM <= 8 || joinAlongM <= alongRouteM + 8) {
    return NavPhaseRibbons(
      traveled: slice.traveled,
      approachRemaining: const [],
      tourRemaining: slice.remaining,
      joinLngLat: joinAlongM > 0 ? joinPt : null,
    );
  }

  final remSplit = sliceRouteAtAlongM(
    slice.remaining,
    joinAlongM - alongRouteM,
  );
  return NavPhaseRibbons(
    traveled: slice.traveled,
    approachRemaining: remSplit.traveled,
    tourRemaining: remSplit.remaining,
    joinLngLat: joinPt,
  );
}
