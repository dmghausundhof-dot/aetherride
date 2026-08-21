import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Trail-surface weather mark — dry / damp / wet / offline.
class WeatherGlyph extends StatelessWidget {
  const WeatherGlyph(
    this.trailHint, {
    super.key,
    this.size = 16,
    this.offline = false,
  });

  /// `dry_likely` | `damp_possible` | `wet_likely`
  final String? trailHint;
  final double size;
  final bool offline;

  static String assetPath({String? trailHint, bool offline = false}) {
    if (offline) return 'assets/weather/offline.svg';
    return switch (trailHint) {
      'wet_likely' => 'assets/weather/wet.svg',
      'damp_possible' => 'assets/weather/damp.svg',
      _ => 'assets/weather/dry.svg',
    };
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath(trailHint: trailHint, offline: offline),
      width: size,
      height: size,
      excludeFromSemantics: true,
    );
  }
}
