import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n_ext.dart';
import 'nav_puck_image.dart';

/// Vergleich der Navi-Puck-Stile — dunkler + heller Grund.
/// [styles] begrenzt die Liste (Profil: 3D + klassischer Pfeil).
Future<NavPuckStyle?> showNavPuckStyleSheet(
  BuildContext context, {
  required NavPuckStyle current,
  List<NavPuckStyle>? styles,
  String? hint,
}) {
  final list = styles ?? NavPuckStyle.values;
  final compact = list.length <= 3;
  return showModalBottomSheet<NavPuckStyle>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final picker = NavPuckStylePicker(
        current: current,
        styles: list,
        hint: hint,
        onSelect: (s) => Navigator.of(ctx).pop(s),
      );
      if (compact) return picker;
      return SizedBox(
        height: MediaQuery.sizeOf(ctx).height * 0.88,
        child: picker,
      );
    },
  );
}

class NavPuckStylePicker extends StatelessWidget {
  const NavPuckStylePicker({
    super.key,
    required this.current,
    required this.onSelect,
    this.styles,
    this.hint,
  });

  final NavPuckStyle current;
  final ValueChanged<NavPuckStyle> onSelect;
  final List<NavPuckStyle>? styles;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10nOrNull;
    final list = styles ?? NavPuckStyle.values;
    final compact = list.length <= 3;
    final header = <Widget>[
      Text(
        l10n?.rideNavPuckTitle ?? 'Navi-Symbol',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        hint ??
            l10n?.rideNavPuckHint ??
            'Alle Varianten auf dunkel und hell. Tippen wählt das Symbol '
                'für Karte und HUD. 0° = Spitze oben.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.muted,
        ),
      ),
      const SizedBox(height: AppSpacing.m),
    ];
    final tiles = <Widget>[
      for (final style in list) ...[
        _StyleTile(
          style: style,
          selected: style == current,
          onTap: () => onSelect(style),
        ),
        const SizedBox(height: AppSpacing.s),
      ],
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          0,
          AppSpacing.l,
          AppSpacing.l,
        ),
        child: compact
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [...header, ...tiles],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...header,
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(children: tiles),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _StyleTile extends StatelessWidget {
  const _StyleTile({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final NavPuckStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10nOrNull;
    return Material(
      key: Key('nav-puck-style-${style.id}'),
      color: selected
          ? AppColors.accent.withValues(alpha: 0.12)
          : Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.m,
            AppSpacing.s,
            AppSpacing.m,
            AppSpacing.s,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      navPuckTitle(l10n, style),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (style.isRecommended)
                    Text(
                      l10n?.rideRecommend ?? 'Empfehlung',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.sageOnDark,
                      ),
                    ),
                  if (selected) ...[
                    const SizedBox(width: AppSpacing.s),
                    const Icon(Icons.check_circle, color: AppColors.accent),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                navPuckSubtitle(l10n, style),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Row(
                children: [
                  Expanded(
                    child:                     _SwatchPair(
                      label: l10n?.ridePuckDark ?? 'Dunkel',
                      background: AppColors.hofGround,
                      foreground: AppColors.chrome,
                      style: style,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child:                     _SwatchPair(
                      label: l10n?.ridePuckLight ?? 'Hell',
                      background: AppColors.sunSurface,
                      foreground: AppColors.sunMuted,
                      style: style,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwatchPair extends StatelessWidget {
  const _SwatchPair({
    required this.label,
    required this.background,
    required this.foreground,
    required this.style,
  });

  final String label;
  final Color background;
  final Color foreground;
  final NavPuckStyle style;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s,
          vertical: AppSpacing.s,
        ),
        child: Row(
          children: [
            AetherNavMark(
              size: style.usesRiderAsset ? 44 : 34,
              style: style,
            ),
            const SizedBox(width: AppSpacing.s),
            AetherNavMark(
              size: style.usesRiderAsset ? 22 : 17,
              style: style,
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
