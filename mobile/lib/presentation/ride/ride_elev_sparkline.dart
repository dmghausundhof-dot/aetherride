import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/ride/ride_telemetry.dart';

/// Mini-Höhenprofil mit Neigungsfarbe — Hof, Profil, Recap.
class RideElevSparkline extends StatelessWidget {
  const RideElevSparkline({
    super.key,
    required this.telemetry,
    this.height = 36,
  });

  final RideTelemetry telemetry;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (telemetry.chart.length < 2 || !telemetry.hasElev) {
      return SizedBox(height: height);
    }
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparkPainter(telemetry),
      ),
    );
  }
}

/// Hof, Profil, Liste: dieselbe Mini-Fläche wie Web `RideTerrainPeek`.
class RideTerrainPeek extends StatelessWidget {
  const RideTerrainPeek({
    super.key,
    required this.telemetry,
    this.caption,
    this.onTap,
    this.sparkHeight = 44,
  });

  final RideTelemetry telemetry;
  final String? caption;
  final VoidCallback? onTap;
  final double sparkHeight;

  @override
  Widget build(BuildContext context) {
    if (!telemetry.hasElev || telemetry.totalDistKm <= 0) {
      return const SizedBox.shrink();
    }
    final child = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (caption != null) ...[
              Text(
                caption!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 6),
            ],
            RideElevSparkline(telemetry: telemetry, height: sparkHeight),
            const SizedBox(height: 5),
            RideGradeRibbon(telemetry: telemetry),
          ],
        ),
      ),
    );
    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: child,
    );
  }
}

class RideGradeRibbon extends StatelessWidget {
  const RideGradeRibbon({super.key, required this.telemetry, this.height = 5});

  final RideTelemetry telemetry;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (!telemetry.hasElev || telemetry.totalDistKm <= 0) {
      return const SizedBox.shrink();
    }
    final pts = telemetry.chart;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (var i = 1; i < pts.length; i++)
              if (pts[i].distKm > pts[i - 1].distKm)
                Expanded(
                  flex: ((pts[i].distKm - pts[i - 1].distKm) * 1000)
                      .round()
                      .clamp(1, 100000),
                  child: ColoredBox(color: gradeBandColor(pts[i].band)),
                ),
          ],
        ),
      ),
    );
  }
}

Color gradeBandColor(GradeBand band) {
  switch (band) {
    case GradeBand.steepUp:
      return const Color(0xFFC2410C);
    case GradeBand.up:
      return AppColors.accent;
    case GradeBand.roll:
      return AppColors.sage;
    case GradeBand.down:
      return const Color(0xFF5B8C9A);
    case GradeBand.steepDown:
      return const Color(0xFF3D6B8A);
    case GradeBand.gap:
      return const Color(0xFF6B7280);
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.t);

  final RideTelemetry t;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = t.chart.where((s) => s.elevM != null).toList();
    if (pts.length < 2 || t.totalDistKm <= 0) return;
    final elevs = [for (final p in pts) p.elevM!];
    final minE = elevs.reduce((a, b) => a < b ? a : b);
    final maxE = elevs.reduce((a, b) => a > b ? a : b);
    final span = (maxE - minE).clamp(8, 8000);
    Offset o(RideSample s) {
      final x = (s.distKm / t.totalDistKm) * size.width;
      final y = size.height - 2 - ((s.elevM! - minE) / span) * (size.height - 4);
      return Offset(x, y);
    }

    for (var i = 1; i < t.chart.length; i++) {
      final a = t.chart[i - 1];
      final b = t.chart[i];
      if (a.elevM == null || b.elevM == null) continue;
      canvas.drawLine(
        o(a),
        o(b),
        Paint()
          ..color = gradeBandColor(b.band)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) => oldDelegate.t != t;
}
