import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../shared/chrome_glyph.dart';
import '../../../domain/routing/connectivity_chip.dart';
import '../../../l10n/l10n_ext.dart';

/// Honest mid-ride connectivity / offline trust chip (N-03 / N-08).
class RideConnectivityChip extends StatelessWidget {
  const RideConnectivityChip({
    super.key,
    required this.state,
    this.compact = false,
    this.mapHintVisible = false,
    this.onTap,
  });

  final ConnectivityChipState state;
  final bool compact;
  final bool mapHintVisible;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = context.l10nOrNull?.connectivityChipLabelFor(
          state,
          mapHintVisible: mapHintVisible,
        ) ??
        connectivityChipLabel(state, mapHintVisible: mapHintVisible);
    final (bg, fg, mark) = switch (state) {
      ConnectivityChipState.live => (
          AppColors.sunSurface,
          AppColors.sageOnLight,
          'cloud',
        ),
      ConnectivityChipState.routeOffline => (
          AppColors.sunSurface,
          AppColors.sageOnLight,
          'check',
        ),
      ConnectivityChipState.offlineMapOk => (
          AppColors.mapCautionFill,
          AppColors.charcoal,
          'offline',
        ),
      ConnectivityChipState.routingOffline => (
          AppColors.mapCautionFill,
          AppColors.charcoal,
          'split',
        ),
      ConnectivityChipState.mapsMissing => (
          AppColors.mapWarnFill,
          AppColors.mapWarnInk,
          'karte',
        ),
    };
    final body = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChromeGlyph(mark, size: compact ? 14 : 16, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
                color: fg,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
    return Semantics(
      container: true,
      button: onTap != null,
      label: label,
      excludeSemantics: true,
      child: Material(
        key: const Key('ride-connectivity-chip'),
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: onTap == null
            ? body
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: body,
              ),
      ),
    );
  }
}
