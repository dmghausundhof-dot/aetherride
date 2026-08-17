import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'app_theme.dart';

/// Official FlowLine mountain + wave mark (`assets/brand/logo-mark.svg`).
class FlowLineMark extends StatelessWidget {
  const FlowLineMark({super.key, this.size = 72, this.onDark = true});

  final double size;
  final bool onDark;

  static const double _aspect = 652 / 356;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * _aspect,
      height: size,
      child: SvgPicture.asset(
        onDark
            ? 'assets/brand/logo-mark-on-dark.svg'
            : 'assets/brand/logo-mark.svg',
        fit: BoxFit.contain,
        alignment: Alignment.center,
        excludeFromSemantics: true,
      ),
    );
  }
}

class FlowLineWordmark extends StatelessWidget {
  const FlowLineWordmark({
    super.key,
    this.fontSize = 22,
    this.onDark = true,
    this.showMark = true,
    this.markSize = 28,
  });

  final double fontSize;
  final bool onDark;
  final bool showMark;
  final double markSize;

  @override
  Widget build(BuildContext context) {
    final flow = onDark ? const Color(0xFFF2F2F2) : AppColors.charcoal;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showMark) ...[
          FlowLineMark(size: markSize, onDark: onDark),
          SizedBox(width: fontSize * 0.35),
        ],
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Flow',
                style: TextStyle(
                  color: flow,
                  fontWeight: FontWeight.w800,
                  fontSize: fontSize,
                  letterSpacing: 0.2,
                ),
              ),
              TextSpan(
                text: 'Line',
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: fontSize,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
