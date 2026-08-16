import 'dart:math' show Point, max;

import 'package:flutter/widgets.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Native MapLibre-Ornamente (Kompass) liegen im Platform-View, nicht im
/// Flutter-SafeArea. Default ist oben rechts mit ~8 dp — auf Edge-to-Edge
/// (Galaxy S25 u. a.) genau unter Uhr/Batterie.
///
/// Discover: rechter Rand, Kompass über Location, unter Suchleiste/Chips,
/// nicht am unteren Rand hinter Hof-Tabs oder über der Scale-Bar.
abstract final class MapOrnaments {
  static const CompassViewPosition compassPosition =
      CompassViewPosition.topRight;

  /// Abstand zum rechten Rand (bzw. Cutout).
  static const double sideMin = 12;

  /// Luft unter Statusleiste / Punch-Hole.
  static const double gapBelowStatus = 8;

  /// Discover-Suchleiste + Chip-Zeile — Kompass sitzt darunter, nicht auf Mehr.
  static const double discoverHeaderClearance = 128;

  /// Pre-Ride-Routenchip (ohne SafeArea, ~72 dp ab top: 12).
  static const double ridePreStartClearance = 80;

  /// Native Kompass-Slot (MapLibre ~48 dp).
  static const double compassSlot = 48;

  /// Luft zwischen Kompass und Location-FAB.
  static const double controlGap = 10;

  static Point compassMargins(
    BuildContext context, {
    double extraBelowSafe = 0,
  }) {
    final pad = MediaQuery.paddingOf(context);
    final x = max(pad.right, sideMin);
    final y = pad.top + gapBelowStatus + extraBelowSafe;
    return Point(x, y);
  }

  /// Location-FAB: dieselbe rechte Schiene, direkt unter dem Kompass.
  static Point locateMargins(
    BuildContext context, {
    double extraBelowSafe = 0,
  }) {
    final c = compassMargins(context, extraBelowSafe: extraBelowSafe);
    return Point(c.x, c.y + compassSlot + controlGap);
  }
}
