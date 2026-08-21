import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/routing/coverage_graph_ring.dart';
import '../../data/routing/map_style_url.dart';

Color coverageSketchUserFill({
  required double lng,
  required double lat,
  List<List<double>>? ring,
}) {
  if (ring != null &&
      ring.length >= 4 &&
      !coveragePointInRing(lng: lng, lat: lat, ring: ring)) {
    return AppColors.sage;
  }
  return AppColors.chrome;
}

/// Mini-Karte: Pack auf seinem Blatt (DACH oder das passende Overview-Blatt).
///
/// World = Übersicht; orange plate = Routing-Graph; optional GPS,
/// download fill, and a sage frame when the Blatt is already on disk.
class OfflineCoverageSketch extends StatelessWidget {
  const OfflineCoverageSketch({
    super.key,
    required this.bbox,
    this.ring,
    this.dots,
    this.height = 88,
    this.userLng,
    this.userLat,
    this.overviewReady = false,
    this.progress,
    this.onTap,
    this.semanticLabel,
  });

  /// [west, south, east, north]
  final List<double> bbox;
  /// Graph occupancy ring `[lng, lat]`. Falls back to the bbox plate.
  final List<List<double>>? ring;
  /// Graph nodes for a trail stipple — not fake hillshade.
  final List<List<double>>? dots;
  final double height;
  final double? userLng;
  final double? userLat;
  final bool overviewReady;
  final double? progress;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (bbox.length < 4) return const SizedBox.shrink();
    final child = SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: CoverageSketchPainter(
          bbox: bbox,
          ring: ring,
          dots: dots,
          userLng: userLng,
          userLat: userLat,
          overviewReady: overviewReady,
          progress: progress,
        ),
      ),
    );
    if (onTap == null) return child;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('offline-coverage-sketch'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: child,
        ),
      ),
    );
  }
}

class CoverageSketchPainter extends CustomPainter {
  CoverageSketchPainter({
    required this.bbox,
    this.ring,
    this.dots,
    this.userLng,
    this.userLat,
    this.overviewReady = false,
    this.progress,
  });

  final List<double> bbox;
  final List<List<double>>? ring;
  final List<List<double>>? dots;
  final double? userLng;
  final double? userLat;
  final bool overviewReady;
  final double? progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = coverageSketchWorld(bbox);
    final canvasRRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(8),
    );
    canvas.save();
    canvas.clipRRect(canvasRRect);
    canvas.drawRRect(
      canvasRRect,
      Paint()..color = AppColors.elevated,
    );

    Offset map(double lng, double lat) {
      final spanLng = w[2] - w[0];
      final spanLat = w[3] - w[1];
      if (spanLng.abs() < 1e-9 || spanLat.abs() < 1e-9) {
        return Offset(size.width / 2, size.height / 2);
      }
      final x = (lng - w[0]) / spanLng * size.width;
      final y = (1 - (lat - w[1]) / spanLat) * size.height;
      return Offset(x, y);
    }

    final land = coverageSketchLandRing(w);
    if (land.length >= 3) {
      final path = Path();
      for (var i = 0; i < land.length; i++) {
        final p = map(land[i][0], land[i][1]);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color =
              AppColors.sage.withValues(alpha: overviewReady ? 0.42 : 0.22),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.sageOnDark.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );
    } else {
      canvas.drawRRect(
        canvasRRect,
        Paint()
          ..color =
              AppColors.sage.withValues(alpha: overviewReady ? 0.34 : 0.18),
      );
    }

    final grid = Paint()
      ..color = AppColors.sageOnDark.withValues(alpha: 0.18)
      ..strokeWidth = 0.7;
    const steps = 5;
    for (var i = 1; i < steps; i++) {
      final t = i / steps;
      final lng = w[0] + (w[2] - w[0]) * t;
      final lat = w[1] + (w[3] - w[1]) * t;
      canvas.drawLine(map(lng, w[1]), map(lng, w[3]), grid);
      canvas.drawLine(map(w[0], lat), map(w[2], lat), grid);
    }

    if (overviewReady) {
      canvas.drawRRect(
        canvasRRect.deflate(3),
        Paint()
          ..color = AppColors.sageOnDark.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    final a = map(bbox[0], bbox[1]);
    final b = map(bbox[2], bbox[3]);
    final rect = Rect.fromPoints(a, b).inflate(1);
    final packPath = Path();
    final ringPts = ring;
    if (ringPts != null && ringPts.length >= 4) {
      for (var i = 0; i < ringPts.length; i++) {
        final p = ringPts[i];
        if (p.length < 2) continue;
        final o = map(p[0], p[1]);
        if (i == 0) {
          packPath.moveTo(o.dx, o.dy);
        } else {
          packPath.lineTo(o.dx, o.dy);
        }
      }
      packPath.close();
    }
    if (packPath.getBounds().isEmpty) {
      packPath.addRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      );
    }
    canvas.drawPath(
      packPath,
      Paint()..color = AppColors.chrome.withValues(alpha: 0.28),
    );
    final stipple = dots;
    if (stipple != null && stipple.isNotEmpty) {
      final ink = Paint()..color = AppColors.chrome.withValues(alpha: 0.55);
      for (final p in stipple) {
        if (p.length < 2) continue;
        canvas.drawCircle(map(p[0], p[1]), 1.15, ink);
      }
    }
    final p = (progress ?? 0).clamp(0.0, 1.0);
    if (p > 0) {
      canvas.save();
      canvas.clipPath(packPath);
      canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.top, rect.width * p, rect.height),
        Paint()..color = AppColors.chrome.withValues(alpha: 0.55),
      );
      canvas.restore();
    }

    final tick = math.min(rect.width, rect.height) * 0.22;
    final tickLen = tick.clamp(6.0, 16.0);
    final frame = Paint()
      ..color = AppColors.chrome
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;
    void corner(Offset origin, double sx, double sy) {
      canvas.drawLine(origin, origin + Offset(sx * tickLen, 0), frame);
      canvas.drawLine(origin, origin + Offset(0, sy * tickLen), frame);
    }

    corner(rect.bottomLeft, 1, -1);
    corner(rect.bottomRight, -1, -1);
    corner(rect.topLeft, 1, 1);
    corner(rect.topRight, -1, 1);

    final lng = userLng;
    final lat = userLat;
    if (lng != null && lat != null && pointInBasemapBbox(lng, lat, w)) {
      final at = map(lng, lat);
      canvas.drawCircle(at, 5, Paint()..color = Colors.white);
      canvas.drawCircle(
        at,
        3.4,
        Paint()
          ..color = coverageSketchUserFill(
            lng: lng,
            lat: lat,
            ring: ringPts,
          ),
      );
    }
    canvas.restore();
    canvas.drawRRect(
      canvasRRect,
      Paint()
        ..color = AppColors.border.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CoverageSketchPainter oldDelegate) =>
      oldDelegate.bbox != bbox ||
      oldDelegate.ring != ring ||
      oldDelegate.dots != dots ||
      oldDelegate.userLng != userLng ||
      oldDelegate.userLat != userLat ||
      oldDelegate.overviewReady != overviewReady ||
      oldDelegate.progress != progress;
}
