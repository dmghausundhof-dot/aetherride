import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/nav_hud_tokens.dart';

/// Charcoal HUD island — Layer-Bar, Zusammen-Chip, Ja-Karte, Live-Bar.
class RideHudIsland extends StatelessWidget {
  const RideHudIsland({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  static const EdgeInsets pad = EdgeInsets.symmetric(
    horizontal: NavHudTokens.islandPadH,
    vertical: NavHudTokens.islandPadV,
  );

  static const EdgeInsets compactPad = EdgeInsets.symmetric(
    horizontal: NavHudTokens.islandPadH,
    vertical: NavHudTokens.islandCompactPadV,
  );

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.card);
    return Material(
      color: NavHudTokens.islandFill(context),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: NavHudTokens.islandStroke(context)),
      ),
      child: onTap == null
          ? Padding(padding: padding ?? pad, child: child)
          : InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Padding(padding: padding ?? pad, child: child),
            ),
    );
  }
}
