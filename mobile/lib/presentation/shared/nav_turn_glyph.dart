import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Maps [navTurnIconName] tokens to FlowLine manoeuvre SVGs.
String? navTurnAssetPath(String? iconName) {
  return switch (iconName) {
    'flag' => 'assets/nav/arrive.svg',
    'turn_left' => 'assets/nav/turn-left.svg',
    'turn_right' => 'assets/nav/turn-right.svg',
    'turn_slight_left' => 'assets/nav/slight-left.svg',
    'turn_slight_right' => 'assets/nav/slight-right.svg',
    'turn_sharp_left' => 'assets/nav/sharp-left.svg',
    'turn_sharp_right' => 'assets/nav/sharp-right.svg',
    'straight' => 'assets/nav/straight.svg',
    'u_turn_left' => 'assets/nav/u-turn.svg',
    _ => null,
  };
}

class NavTurnGlyph extends StatelessWidget {
  const NavTurnGlyph(
    this.iconName, {
    super.key,
    this.size = 24,
    this.color,
  });

  final String iconName;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final asset = navTurnAssetPath(iconName);
    if (asset == null) return SizedBox(width: size, height: size);
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      excludeFromSemantics: true,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}
