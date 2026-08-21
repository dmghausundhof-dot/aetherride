import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/tours/tour_line.dart';
import 'mappe_glyph.dart';

/// Orange Spur auf Charcoal — dasselbe Motiv wie Web `TourLineThumb`.
class TourLineThumb extends StatelessWidget {
  const TourLineThumb({
    super.key,
    required this.coordinates,
    this.size = 80,
    this.wide = false,
  });

  final List<List<double>> coordinates;
  final double size;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final h = wide ? size * 0.72 : size;
    if (!wide) {
      return _thumb(size, h);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final w = maxW.isFinite && maxW > 0 ? maxW : size * 2.2;
        return _thumb(w, h);
      },
    );
  }

  Widget _thumb(double w, double h) {
    final fit = fitTourLine(
      coordinates,
      width: wide ? 128 : 64,
      height: wide ? 64 : 64,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: SizedBox(
        width: w,
        height: h,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (coordinates.length < 2)
              SvgPicture.asset(
                'assets/tours/no-track.svg',
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              )
            else
              CustomPaint(
                painter: _TourLinePainter(
                  coordinates: coordinates,
                  wide: wide,
                ),
              ),
            if (fit?.loop == true)
              Positioned(
                left: wide ? 8 : null,
                right: wide ? null : 4,
                bottom: wide ? 8 : 4,
                child: const MappeGlyph('loop', size: 12),
              ),
          ],
        ),
      ),
    );
  }
}

class _TourLinePainter extends CustomPainter {
  const _TourLinePainter({required this.coordinates, required this.wide});

  final List<List<double>> coordinates;
  final bool wide;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.hofGround);
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.72)
        ..quadraticBezierTo(
          size.width * 0.45,
          size.height * 0.62,
          size.width,
          size.height * 0.85,
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = AppColors.surfaceDark,
    );

    final fit = fitTourLine(
      coordinates,
      width: size.width,
      height: size.height,
      pad: wide ? 10 : 8,
    );
    if (fit == null || fit.points.length < 2) return;

    final path = Path()..moveTo(fit.points.first.x, fit.points.first.y);
    for (var i = 1; i < fit.points.length; i++) {
      path.lineTo(fit.points[i].x, fit.points[i].y);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.sage.withValues(alpha: 0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = wide ? 5.2 : 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = wide ? 2.8 : 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final start = Offset(fit.start.x, fit.start.y);
    canvas.drawCircle(
        start, wide ? 4.2 : 3.6, Paint()..color = AppColors.accent);
    canvas.drawCircle(
      start,
      wide ? 1.8 : 1.5,
      Paint()..color = const Color(0xFFF4F1EC),
    );
    if (!fit.loop) {
      final end = Offset(fit.end.x, fit.end.y);
      canvas.drawCircle(
        end,
        wide ? 3.2 : 2.8,
        Paint()..color = const Color(0xFFF2F2F2),
      );
      canvas.drawCircle(
        end,
        wide ? 1.4 : 1.2,
        Paint()..color = AppColors.hofGround,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TourLinePainter oldDelegate) =>
      oldDelegate.coordinates != coordinates || oldDelegate.wide != wide;
}

/// Mini-Höhenkurve aus echten Samples (0–1).
class MappeElevSparkPainter extends CustomPainter {
  const MappeElevSparkPainter(this.norm);
  final List<double> norm;

  @override
  void paint(Canvas canvas, Size size) {
    if (norm.length < 2 || size.width <= 0 || size.height <= 0) return;
    final path = Path();
    for (var i = 0; i < norm.length; i++) {
      final x = size.width * i / (norm.length - 1);
      final y = size.height * (1 - norm[i].clamp(0, 1));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant MappeElevSparkPainter oldDelegate) =>
      oldDelegate.norm != norm;
}

/// Bis zu drei echte Spuren, leicht versetzt — kein erfundenes Bild.
class MappeTrackStack extends StatelessWidget {
  const MappeTrackStack({
    super.key,
    required this.tracks,
    this.size = 56,
    this.extraCount = 0,
  });

  final List<List<List<double>>> tracks;
  final double size;
  final int extraCount;

  @override
  Widget build(BuildContext context) {
    final real = [
      for (final t in tracks)
        if (t.length >= 2) t,
    ].take(3).toList();
    if (real.isEmpty) return const SizedBox.shrink();
    if (real.length == 1 && extraCount <= 0) {
      return TourLineThumb(coordinates: real.first, size: size, wide: true);
    }
    const offset = 5.0;
    final h = size * 0.72;
    final extra = (real.length - 1) * offset;
    return SizedBox(
      height: h + extra,
      child: Stack(
        children: [
          for (var i = real.length - 1; i >= 0; i--)
            Positioned(
              left: i * offset,
              right: (real.length - 1 - i) * offset,
              top: i * offset,
              height: h,
              child: Opacity(
                opacity: i == 0 ? 1 : 0.62,
                child: TourLineThumb(
                  coordinates: real[i],
                  size: size,
                  wide: true,
                ),
              ),
            ),
          if (extraCount > 0)
            Positioned(
              right: 8,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.hofGround.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '+$extraCount',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.chipIdleText,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
