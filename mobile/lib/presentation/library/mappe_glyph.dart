import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MappeGlyph extends StatelessWidget {
  const MappeGlyph(this.name, {super.key, this.size = 16});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/tours/glyph-$name.svg',
      width: size,
      height: size,
      excludeFromSemantics: true,
    );
  }
}
