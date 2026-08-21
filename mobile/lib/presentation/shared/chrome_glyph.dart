import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// FlowLine chrome mark — two-color by default, tinted when [color] is set.
class ChromeGlyph extends StatelessWidget {
  const ChromeGlyph(
    this.name, {
    super.key,
    this.size = 16,
    this.color,
  });

  final String name;
  final double size;
  final Color? color;

  static String assetPath(String name) {
    return switch (name) {
      'platz' => 'assets/tours/glyph-mappe.svg',
      'offline' => 'assets/weather/offline.svg',
      'photo' => 'assets/garage/glyph-photo.svg',
      'elevation' => 'assets/tours/glyph-elevation.svg',
      'check' => 'assets/garage/glyph-ready.svg',
      'care' => 'assets/garage/glyph-care.svg',
      'stimmen' => 'assets/tours/glyph-stimmen.svg',
      'lock' => 'assets/garage/glyph-lock.svg',
      'add' => 'assets/garage/glyph-add.svg',
      'meet' => 'assets/tours/glyph-meet.svg',
      'loop' => 'assets/tours/glyph-loop.svg',
      _ => 'assets/chrome/glyph-$name.svg',
    };
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath(name),
      width: size,
      height: size,
      excludeFromSemantics: true,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}
