import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/routing/discover_card_hero.dart';

/// Full-bleed hero on a Discover tour card (D-60-CARD-01).
///
/// Loads a real network image (curated photo or place static map). On failure
/// falls back to a painted loop mini-map — never a sticky gray placeholder.
class DiscoverTourCardHero extends StatelessWidget {
  const DiscoverTourCardHero({
    super.key,
    required this.imageUrl,
    required this.isLoop,
    this.height = 148,
  });

  final String imageUrl;
  final bool isLoop;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.card),
      ),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              headers: kDiscoverHeroImageHeaders,
              // Warm cache / decode ASAP so ≥3 cards paint within a few seconds.
              filterQuality: FilterQuality.medium,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) return child;
                return const _HeroBootstrapping();
              },
              errorBuilder: (context, error, stack) {
                return _LoopMiniMapFallback(isLoop: isLoop);
              },
            ),
            // Soft bottom scrim so title text over the card stays readable.
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 36,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00000000),
                      Color(0x66000000),
                    ],
                  ),
                ),
              ),
            ),
            if (isLoop)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: const Text(
                    '⟲ Rundkurs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Brief atmospheric bootstrap while the first frames decode — not a gray slab.
class _HeroBootstrapping extends StatelessWidget {
  const _HeroBootstrapping();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B4332),
            Color(0xFF2D6A4F),
            Color(0xFF40916C),
          ],
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _LoopMiniMapFallback extends StatelessWidget {
  const _LoopMiniMapFallback({required this.isLoop});

  final bool isLoop;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MiniLoopPainter(isLoop: isLoop),
      child: const SizedBox.expand(),
    );
  }
}

class _MiniLoopPainter extends CustomPainter {
  _MiniLoopPainter({required this.isLoop});

  final bool isLoop;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final route = Paint()
      ..color = const Color(0xFFE9C46A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final cx = size.width * 0.5;
    final cy = size.height * 0.52;
    final rx = size.width * 0.28;
    final ry = size.height * 0.28;
    if (isLoop) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
        route,
      );
    } else {
      final path = Path()
        ..moveTo(size.width * 0.18, size.height * 0.7)
        ..quadraticBezierTo(
          size.width * 0.45,
          size.height * 0.25,
          size.width * 0.82,
          size.height * 0.55,
        );
      canvas.drawPath(path, route);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniLoopPainter oldDelegate) =>
      oldDelegate.isLoop != isLoop;
}
