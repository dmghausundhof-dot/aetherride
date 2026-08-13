import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Thin Hof-ground strip so light system icons stay readable on OSM tiles.
/// Map stays edge-to-edge; this is cutout/status-bar height, not a header.
class StatusBarScrim extends StatelessWidget {
  const StatusBarScrim({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    if (pad.top <= 0 && pad.left <= 0 && pad.right <= 0) {
      return const SizedBox.shrink();
    }
    const ground = AppColors.hofGround;
    return IgnorePointer(
      child: Stack(
        children: [
          if (pad.top > 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: pad.top + 12,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xEB0A1210),
                      Color(0x8C0A1210),
                      Color(0x000A1210),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          if (pad.left > 0)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: pad.left,
              child: ColoredBox(color: ground.withValues(alpha: 0.88)),
            ),
          if (pad.right > 0)
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: pad.right,
              child: ColoredBox(color: ground.withValues(alpha: 0.88)),
            ),
        ],
      ),
    );
  }
}
