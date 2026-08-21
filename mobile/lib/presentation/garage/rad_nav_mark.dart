import 'package:flutter/material.dart';

/// Tab mark for Rad — same silhouette as web `RadNavMark`.
class RadNavMark extends StatelessWidget {
  const RadNavMark({
    super.key,
    required this.color,
    this.filled = false,
    this.size = 22,
  });

  final Color color;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _RadNavPainter(color: color, filled: filled),
    );
  }
}

class _RadNavPainter extends CustomPainter {
  const _RadNavPainter({required this.color, required this.filled});

  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.scale(scale);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = filled ? 1.5 : 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    void wheel(Offset c, double r) {
      canvas.drawCircle(c, r, stroke);
      if (filled) canvas.drawCircle(c, r * 0.28, fill);
    }

    wheel(const Offset(7.4, 16.2), 3.4);
    wheel(const Offset(16.6, 16.2), 3.4);
    canvas.drawPath(
      Path()
        ..moveTo(7.4, 16.2)
        ..lineTo(10.6, 9.2)
        ..lineTo(15.2, 9.2)
        ..lineTo(16.6, 16.2),
      stroke,
    );
    canvas.drawLine(const Offset(10.6, 9.2), const Offset(12.2, 16.2), stroke);
    canvas.drawPath(
      Path()
        ..moveTo(10.6, 9.2)
        ..lineTo(9.6, 6.6)
        ..lineTo(7.8, 6.6),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _RadNavPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.filled != filled;
}
