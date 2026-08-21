import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Handgezeichnete Bike-Silhouette — App-weites Empty-State-Motiv.
/// Aus `garage_screen.dart` extrahiert (dort ursprünglich `_EmptyBikeSilhouettePainter`,
/// privat und nur für die leere Garage nutzbar). Jetzt öffentlich, damit
/// Chat und Ride (Bereit-Screen) denselben Leerzustand statt eines
/// schwarzen Void zeigen (UX-Review: Punkt „Void-Empty-States").
class BikeSilhouettePainter extends CustomPainter {
  const BikeSilhouettePainter({this.color});

  /// Default: `AppColors.trail` bei 55% Deckkraft (Original-Look aus der Garage).
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = (color ?? AppColors.trail).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width;
    final h = size.height;
    // Neutrale Bike-Silhouette (alle Disziplinen): Räder + Rahmen + Lenker.
    canvas.drawCircle(Offset(w * 0.22, h * 0.72), h * 0.22, stroke);
    canvas.drawCircle(Offset(w * 0.78, h * 0.72), h * 0.22, stroke);
    final frame = Path()
      ..moveTo(w * 0.22, h * 0.72)
      ..lineTo(w * 0.42, h * 0.38)
      ..lineTo(w * 0.68, h * 0.38)
      ..lineTo(w * 0.78, h * 0.72)
      ..moveTo(w * 0.42, h * 0.38)
      ..lineTo(w * 0.5, h * 0.72)
      ..moveTo(w * 0.68, h * 0.38)
      ..lineTo(w * 0.5, h * 0.72)
      ..moveTo(w * 0.42, h * 0.38)
      ..lineTo(w * 0.36, h * 0.22)
      ..lineTo(w * 0.28, h * 0.22);
    canvas.drawPath(frame, stroke);
  }

  @override
  bool shouldRepaint(covariant BikeSilhouettePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Wiederverwendbarer Leerzustand: Illustration + Titel + optionale
/// Beschreibung + optionale Aktion.
///
/// Ersetzt den „schwarzen Void" (UX-Review), der bislang unabhängig
/// voneinander auf Garage (Letzte Rides), Chat (vor der ersten Nachricht)
/// und Ride (Bereit-Screen) entstand — eine Zeile Text, dann 60–70 % leere
/// Fläche. Ein Aufruf statt drei verschiedene Ad-hoc-Lösungen.
///
/// Default-Icon ist die Bike-Silhouette (App-weites Motiv, konsistent mit
/// der ursprünglichen Garage-Lösung). Ein `icon` (z. B.
/// `Icons.chat_bubble_outline`) überschreibt sie für thematisch andere
/// Kontexte, wenn gewünscht — muss aber nicht: Konsistenz vor Abwechslung.
class EmptyStateIllustration extends StatelessWidget {
  const EmptyStateIllustration({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.icon,
    this.illustration,
    this.compact = false,
  });

  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final IconData? icon;
  final Widget? illustration;

  /// Kleinere Variante für Screens, auf denen der Leerzustand nicht die
  /// ganze Fläche einnimmt (z. B. unter einer bereits gefüllten Liste),
  /// statt der bildschirmfüllenden Garage-Variante.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 56.0 : 96.0;
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: compact ? AppSpacing.l : AppSpacing.xxxl,
        horizontal: AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (illustration != null)
            illustration!
          else if (icon != null)
            Icon(
              icon,
              size: iconSize,
              color: AppColors.trail.withValues(alpha: 0.55),
            )
          else
            CustomPaint(
              size: Size(iconSize * 1.35, iconSize * 0.8),
              painter: const BikeSilhouettePainter(),
            ),
          SizedBox(height: AppSpacing.l),
          Text(
            title,
            textAlign: TextAlign.center,
            style: (compact
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.titleLarge)
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (message != null) ...[
            SizedBox(height: AppSpacing.s),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.35),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: AppSpacing.l),
            FilledButton.icon(
              onPressed: onAction,
              icon: Icon(actionIcon ?? Icons.add),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
