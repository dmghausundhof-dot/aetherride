import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/hud_compass.dart';
import '../../../l10n/l10n_ext.dart';

/// Compact heading rose for the Ride HUD.
///
/// Tap toggles Norden-oben / Fahrtrichtung-oben. Not a Clean-Mode nav stat.
class RideCompassChip extends StatelessWidget {
  const RideCompassChip({
    super.key,
    required this.headingDeg,
    required this.northUp,
    required this.onToggle,
  });

  final double headingDeg;
  final bool northUp;
  final VoidCallback onToggle;

  static const toggleKey = Key('hud-compass-toggle');

  @override
  Widget build(BuildContext context) {
    final heading = normalizeHeadingDeg(headingDeg);
    final l10n = context.l10nOrNull;
    final cardinal =
        l10n?.compassCardinalFor(heading) ?? compassCardinalDe(heading);
    final roseRad =
        compassRoseDeg(heading, northUp: northUp) * math.pi / 180;
    final tooltip = northUp
        ? (l10n?.rideNorthUp ?? 'Norden oben')
        : (l10n?.rideHeadingUp ?? 'Fahrtrichtung oben');
    final courseLabel = l10n?.rideHeadingCourse(tooltip, cardinal) ??
        '$tooltip, Kurs $cardinal';

    return Material(
      color: Theme.of(context).cardColor.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        key: toggleKey,
        customBorder: const CircleBorder(),
        onTap: onToggle,
        child: Tooltip(
          message: tooltip,
          child: Semantics(
            button: true,
            label: courseLabel,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: roseRad,
                    child: CustomPaint(
                      size: const Size(36, 36),
                      painter: _CompassRosePainter(
                        northColor: AppColors.chromeFill(context),
                        tickColor: AppColors.meta(context),
                      ),
                    ),
                  ),
                  Text(
                    cardinal,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: northUp ? AppColors.chromeFill(context) : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompassRosePainter extends CustomPainter {
  const _CompassRosePainter({
    required this.northColor,
    required this.tickColor,
  });

  final Color northColor;
  final Color tickColor;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;
    final ring = Paint()
      ..color = tickColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(c, r - 1, ring);

    final tick = Paint()
      ..color = tickColor
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final rad = i * math.pi / 4;
      final inner = r - (i % 2 == 0 ? 7 : 5);
      final outer = r - 2;
      canvas.drawLine(
        c + Offset(math.sin(rad), -math.cos(rad)) * inner,
        c + Offset(math.sin(rad), -math.cos(rad)) * outer,
        tick,
      );
    }

    final n = Path()
      ..moveTo(c.dx, c.dy - r + 1)
      ..lineTo(c.dx - 4.5, c.dy - r + 11)
      ..lineTo(c.dx + 4.5, c.dy - r + 11)
      ..close();
    canvas.drawPath(n, Paint()..color = northColor);
  }

  @override
  bool shouldRepaint(covariant _CompassRosePainter old) =>
      old.northColor != northColor || old.tickColor != tickColor;
}
