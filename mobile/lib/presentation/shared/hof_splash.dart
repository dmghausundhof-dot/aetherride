import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// In-engine Hof splash — same ground as native Android 12 splash.
class HofSplash extends StatelessWidget {
  const HofSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.hofGround,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HofMark(),
            SizedBox(height: 20),
            Text(
              'AetherRide',
              style: TextStyle(
                color: AppColors.forestOnDark,
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: 0.4,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Der Hof',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HofMark extends StatelessWidget {
  const _HofMark();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(72, 64),
      painter: _HofMarkPainter(),
    );
  }
}

class _HofMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.forestOnDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.12, h * 0.62)
      ..lineTo(w * 0.5, h * 0.12)
      ..lineTo(w * 0.88, h * 0.62)
      ..moveTo(w * 0.28, h * 0.62)
      ..lineTo(w * 0.28, h * 0.92)
      ..lineTo(w * 0.72, h * 0.92)
      ..lineTo(w * 0.72, h * 0.62);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
