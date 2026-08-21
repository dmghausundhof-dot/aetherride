import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/ride/ride_telemetry.dart';
import '../../l10n/app_localizations.dart';
import '../ride/ride_elev_sparkline.dart';

class PostRideTelemetryCard extends StatelessWidget {
  const PostRideTelemetryCard({
    super.key,
    required this.telemetry,
    this.map,
    this.onPickSample,
  });

  final RideTelemetry telemetry;
  final Widget? map;
  final ValueChanged<RideSample>? onPickSample;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = telemetry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.postRideTerrainTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          t.hasElev ? l10n.postRideTerrainHint : l10n.postRideNoElevation,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.m),
        _StatGrid(telemetry: t),
        if (map != null || t.chart.length >= 2) ...[
          const SizedBox(height: AppSpacing.m),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  if (map != null) map!,
                  if (t.hasElev) RideGradeRibbon(telemetry: t, height: 5),
                  if (t.chart.length >= 2)
                    SizedBox(
                      width: double.infinity,
                      height: 128,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                        child: LayoutBuilder(
                          builder: (context, box) {
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: onPickSample == null || t.totalDistKm <= 0
                                  ? null
                                  : (d) {
                                      final x = (d.localPosition.dx / box.maxWidth)
                                          .clamp(0.0, 1.0);
                                      final sample = nearestSample(
                                        t,
                                        x * t.totalDistKm,
                                      );
                                      if (sample != null) onPickSample!(sample);
                                    },
                              child: CustomPaint(
                                painter: _ElevPainter(t),
                                child: const SizedBox.expand(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _GradeLegend(),
        ],
        if (_sensorLines(t).isNotEmpty) ...[
          const SizedBox(height: AppSpacing.m),
          for (final line in _sensorLines(t))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SensorStrip(label: line.$1, values: line.$2, color: line.$3),
            ),
        ],
      ],
    );
  }

  List<(String, List<double?>, Color)> _sensorLines(RideTelemetry t) {
    final out = <(String, List<double?>, Color)>[];
    if (t.channels.speed) {
      out.add((
        'km/h',
        [for (final s in t.chart) s.speedKmh],
        const Color(0xFFE8A87C),
      ));
    }
    if (t.channels.hr) {
      out.add((
        'bpm',
        [for (final s in t.chart) s.hr?.toDouble()],
        const Color(0xFFEF4444),
      ));
    }
    if (t.channels.cad) {
      out.add((
        'rpm',
        [for (final s in t.chart) s.cad?.toDouble()],
        AppColors.sage,
      ));
    }
    if (t.channels.power) {
      out.add((
        'W',
        [for (final s in t.chart) s.power?.toDouble()],
        AppColors.accent,
      ));
    }
    if (t.channels.lean) {
      out.add((
        '°',
        [for (final s in t.chart) s.lean?.abs()],
        const Color(0xFF5B8C9A),
      ));
    }
    return out;
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.telemetry});

  final RideTelemetry telemetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = telemetry;
    final items = <(String, String)>[];
    if (t.hasElev) {
      items.add((l10n.postRideStatElevation, '${t.climbM} hm'));
      items.add((l10n.postRideStatDescent, '${t.descentM} hm'));
      if (t.maxGradePct != null) {
        final g = t.maxGradePct!;
        items.add((
          l10n.postRideStatMaxGrade,
          '${g > 0 ? '+' : ''}${g.toStringAsFixed(1)} %',
        ));
      }
    }
    if (t.maxSpeedKmh != null) {
      items.add((
        l10n.postRideStatMaxSpeed,
        '${t.maxSpeedKmh!.toStringAsFixed(1)} km/h',
      ));
    }
    if (t.avgHr != null) items.add((l10n.postRideSensorHr, '${t.avgHr} bpm'));
    if (t.avgCad != null) items.add((l10n.postRideSensorCad, '${t.avgCad} rpm'));
    if (t.avgPower != null) {
      items.add((l10n.postRideSensorPower, '${t.avgPower} W'));
    }
    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final it in items)
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 96),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(AppRadius.chip),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    it.$2,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    it.$1,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _GradeLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = [
      (GradeBand.steepUp, l10n.postRideGradeSteepUp),
      (GradeBand.up, l10n.postRideGradeUp),
      (GradeBand.roll, l10n.postRideGradeRoll),
      (GradeBand.down, l10n.postRideGradeDown),
      (GradeBand.steepDown, l10n.postRideGradeSteepDown),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      children: [
        for (final r in rows)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: gradeBandColor(r.$1),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                r.$2,
                style: const TextStyle(fontSize: 10, color: AppColors.muted),
              ),
            ],
          ),
      ],
    );
  }
}

class _SensorStrip extends StatelessWidget {
  const _SensorStrip({
    required this.label,
    required this.values,
    required this.color,
  });

  final String label;
  final List<double?> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final known = [for (final v in values) if (v != null) v];
    final min = known.isEmpty ? 0.0 : known.reduce((a, b) => a < b ? a : b);
    final max = known.isEmpty ? 1.0 : known.reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
            const Spacer(),
            Text(
              known.isEmpty
                  ? '—'
                  : '${min.round()}–${max.round()} $label',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.muted,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 36,
          width: double.infinity,
          child: CustomPaint(
            painter: _StripPainter(values: values, color: color),
          ),
        ),
      ],
    );
  }
}

class _ElevPainter extends CustomPainter {
  _ElevPainter(this.t);

  final RideTelemetry t;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = t.chart.where((s) => s.elevM != null).toList();
    if (pts.length < 2 || t.totalDistKm <= 0) return;
    final elevs = [for (final p in pts) p.elevM!];
    final minE = elevs.reduce((a, b) => a < b ? a : b) - 6;
    final maxE = elevs.reduce((a, b) => a > b ? a : b) + 6;
    final span = (maxE - minE).clamp(8, 8000);
    Offset o(RideSample s) {
      final x = (s.distKm / t.totalDistKm) * size.width;
      final y = size.height - ((s.elevM! - minE) / span) * size.height;
      return Offset(x, y);
    }

    final fill = Path();
    fill.moveTo(o(pts.first).dx, size.height);
    fill.lineTo(o(pts.first).dx, o(pts.first).dy);
    for (final p in pts.skip(1)) {
      fill.lineTo(o(p).dx, o(p).dy);
    }
    fill.lineTo(o(pts.last).dx, size.height);
    fill.close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x47FF6A00), Color(0x107A8B73)],
        ).createShader(Offset.zero & size),
    );

    for (var i = 1; i < t.chart.length; i++) {
      final a = t.chart[i - 1];
      final b = t.chart[i];
      if (a.elevM == null || b.elevM == null) continue;
      canvas.drawLine(
        o(a),
        o(b),
        Paint()
          ..color = gradeBandColor(b.band)
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }

    final impactPaint = Paint()..color = AppColors.accent;
    for (final p in t.chart) {
      if (!p.impact || p.elevM == null) continue;
      canvas.drawCircle(o(p), 3.2, impactPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ElevPainter oldDelegate) =>
      oldDelegate.t != t;
}

class _StripPainter extends CustomPainter {
  _StripPainter({required this.values, required this.color});

  final List<double?> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final known = [for (final v in values) if (v != null) v];
    if (known.length < 2) return;
    final min = known.reduce((a, b) => a < b ? a : b);
    final max = known.reduce((a, b) => a > b ? a : b);
    final span = (max - min).clamp(1, 1e6);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < values.length; i++) {
      final a = values[i - 1];
      final b = values[i];
      if (a == null || b == null) continue;
      final x1 = (i - 1) / (values.length - 1) * size.width;
      final x2 = i / (values.length - 1) * size.width;
      final y1 = size.height - 2 - ((a - min) / span) * (size.height - 4);
      final y2 = size.height - 2 - ((b - min) / span) * (size.height - 4);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StripPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

