import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/routing/tour_nav_geometry.dart';

/// Interactive plan elevation — scrub reports 0..1 along the line.
/// A short tap (little movement) commits a via; a pan only scrubs.
class PlanElevationChart extends StatefulWidget {
  const PlanElevationChart({
    super.key,
    required this.samples,
    this.sampleKm,
    this.onScrub,
    this.onTap,
    this.scrubT,
    this.totalKm,
    this.surfaceBands,
    this.height = 118,
  });

  final List<double> samples;
  final List<double>? sampleKm;
  final ValueChanged<double>? onScrub;
  final ValueChanged<double>? onTap;
  final double? scrubT;
  final double? totalKm;
  final List<({double fromKm, double toKm, String? surface})>? surfaceBands;
  final double height;

  @override
  State<PlanElevationChart> createState() => _PlanElevationChartState();
}

class _PlanElevationChartState extends State<PlanElevationChart> {
  Offset? _down;
  bool _dragged = false;
  double _lastT = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.samples.length < 2) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: GestureDetector(
        onPanDown: (d) {
          _down = d.localPosition;
          _dragged = false;
          _emitScrub(context, d.localPosition.dx);
        },
        onPanUpdate: (d) {
          if (_down != null && (d.localPosition - _down!).distance > 10) {
            _dragged = true;
          }
          _emitScrub(context, d.localPosition.dx);
        },
        onPanEnd: (_) {
          if (!_dragged) {
            widget.onTap?.call(_lastT);
          }
        },
        child: CustomPaint(
          painter: PlanElevPainter(
            widget.samples,
            sampleKm: widget.sampleKm,
            scrubT: widget.scrubT,
            totalKm: widget.totalKm,
            surfaceBands: widget.surfaceBands,
            axisColor: AppColors.meta(context),
          ),
        ),
      ),
    );
  }

  void _emitScrub(BuildContext context, double dx) {
    final w = context.size?.width ?? 1;
    _lastT = ((dx - 28) / (w - 28)).clamp(0.0, 1.0);
    widget.onScrub?.call(_lastT);
  }
}

class PlanElevPainter extends CustomPainter {
  PlanElevPainter(
    this.samples, {
    this.sampleKm,
    this.scrubT,
    this.totalKm,
    this.surfaceBands,
    required this.axisColor,
  });

  final List<double> samples;
  final List<double>? sampleKm;
  final double? scrubT;
  final double? totalKm;
  final List<({double fromKm, double toKm, String? surface})>? surfaceBands;
  final Color axisColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2 || size.width <= 0 || size.height <= 0) return;
    var minV = samples.first;
    var maxV = samples.first;
    for (final v in samples) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    final range = (maxV - minV).abs() < 1 ? 1.0 : (maxV - minV);
    const left = 28.0;
    const bottom = 16.0;
    final chartW = size.width - left;
    final chartH = size.height - bottom;
    if (chartW <= 0 || chartH <= 0) return;

    final kmAlong = sampleKm != null &&
            sampleKm!.length == samples.length &&
            sampleKm!.last > 0
        ? sampleKm!
        : null;
    double xOf(int i) {
      if (kmAlong != null) {
        return left + chartW * (kmAlong[i] / kmAlong.last);
      }
      return left + chartW * i / (samples.length - 1);
    }

    final uniformDistM = totalKm != null && totalKm! > 0 && samples.length > 1
        ? (totalKm! * 1000) / (samples.length - 1)
        : 40.0;
    for (var i = 1; i < samples.length; i++) {
      final x0 = xOf(i - 1);
      final y0 =
          chartH - ((samples[i - 1] - minV) / range) * (chartH - 4) - 2;
      final x1 = xOf(i);
      final y1 = chartH - ((samples[i] - minV) / range) * (chartH - 4) - 2;
      final distM = kmAlong != null
          ? (kmAlong[i] - kmAlong[i - 1]) * 1000
          : uniformDistM;
      final kind = planGradeKind(
        fromM: samples[i - 1],
        toM: samples[i],
        distM: distM,
      );
      final fill = Color(planGradeColorArgb(kind)).withValues(alpha: 0.20);
      canvas.drawPath(
        Path()
          ..moveTo(x0, y0)
          ..lineTo(x1, y1)
          ..lineTo(x1, chartH)
          ..lineTo(x0, chartH)
          ..close(),
        Paint()..color = fill,
      );
      canvas.drawLine(
        Offset(x0, y0),
        Offset(x1, y1),
        Paint()
          ..color = Color(planGradeColorArgb(kind))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }
    final km = totalKm;
    final bands = surfaceBands;
    if (bands != null && km != null && km > 0) {
      for (final b in bands) {
        if (!planSurfaceIsUnpaved(b.surface)) continue;
        final x0 = left + chartW * (b.fromKm / km).clamp(0.0, 1.0);
        final x1 = left + chartW * (b.toKm / km).clamp(0.0, 1.0);
        if (x1 - x0 < 2) continue;
        canvas.drawRect(
          Rect.fromLTRB(x0, chartH - 3, x1, chartH),
          Paint()..color = const Color(0xFF6D4C41).withValues(alpha: 0.72),
        );
      }
    }
    if (scrubT != null) {
      final x = left + chartW * scrubT!.clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, chartH),
        Paint()
          ..color = AppColors.chrome
          ..strokeWidth = 1.5,
      );
    }
    final style = TextStyle(
      fontSize: 11,
      color: axisColor,
      fontWeight: FontWeight.w700,
    );
    void label(String text, Offset at, {TextAlign align = TextAlign.left}) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textAlign: align,
      )..layout();
      var dx = at.dx;
      if (align == TextAlign.right) dx -= tp.width;
      tp.paint(canvas, Offset(dx, at.dy));
    }

    label('${maxV.round()} m', const Offset(0, 0));
    label('${minV.round()} m', Offset(0, chartH - 12));
    label('0 km', Offset(left, size.height - 14));
    if (km != null && km > 0) {
      label(
        '${km.toStringAsFixed(km < 10 ? 1 : 0)} km',
        Offset(size.width, size.height - 14),
        align: TextAlign.right,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PlanElevPainter oldDelegate) =>
      oldDelegate.samples != samples ||
      oldDelegate.sampleKm != sampleKm ||
      oldDelegate.scrubT != scrubT ||
      oldDelegate.totalKm != totalKm ||
      oldDelegate.surfaceBands != surfaceBands ||
      oldDelegate.axisColor != axisColor;
}
