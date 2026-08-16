import 'package:flutter/material.dart';

import 'app_theme.dart';

/// FlowLine mountain + wave mark from the brand lockup.
class FlowLineMark extends StatelessWidget {
  const FlowLineMark({super.key, this.size = 72, this.onDark = true});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: FlowLineMarkPainter(onDark: onDark),
    );
  }
}

class FlowLineMarkPainter extends CustomPainter {
  const FlowLineMarkPainter({required this.onDark});

  final bool onDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final mountain = Paint()
      ..color = onDark ? const Color(0xFFF2F2F2) : AppColors.charcoal
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final peaks = Path()
      ..moveTo(w * 0.10, h * 0.50)
      ..lineTo(w * 0.34, h * 0.18)
      ..lineTo(w * 0.48, h * 0.38)
      ..lineTo(w * 0.68, h * 0.14)
      ..lineTo(w * 0.90, h * 0.50);
    canvas.drawPath(peaks, mountain);

    final orange = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round;
    final wave1 = Path()
      ..moveTo(w * 0.08, h * 0.64)
      ..cubicTo(w * 0.28, h * 0.54, w * 0.44, h * 0.74, w * 0.62, h * 0.64)
      ..cubicTo(w * 0.76, h * 0.56, w * 0.86, h * 0.68, w * 0.92, h * 0.70);
    canvas.drawPath(wave1, orange);

    final sage = Paint()
      ..color = onDark ? AppColors.sageOnDark : AppColors.sage
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04
      ..strokeCap = StrokeCap.round;
    final wave2 = Path()
      ..moveTo(w * 0.10, h * 0.78)
      ..cubicTo(w * 0.30, h * 0.68, w * 0.46, h * 0.86, w * 0.64, h * 0.76)
      ..cubicTo(w * 0.78, h * 0.68, w * 0.86, h * 0.80, w * 0.92, h * 0.82);
    canvas.drawPath(wave2, sage);
  }

  @override
  bool shouldRepaint(covariant FlowLineMarkPainter oldDelegate) =>
      oldDelegate.onDark != onDark;
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
