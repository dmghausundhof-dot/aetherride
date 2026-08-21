import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';

/// Schwelle zum Hof — Haarlinie, FlowLine-Orange als aktiver Chrome.
class HofThresholdNav extends StatelessWidget {
  const HofThresholdNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<HofThresholdDestination> destinations;

  /// Tab-Zeile ohne System-Inset — Sheets/Menüs darüber halten.
  static const double barHeight = 56;

  static double sheetBottomInset(BuildContext context, {double extra = 16}) {
    return extra +
        barHeight +
        MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.paddingOf(context).bottom;
  }

  @override
  Widget build(BuildContext context) {
    final index = selectedIndex.clamp(0, destinations.length - 1);
    final ground = Theme.of(context).scaffoldBackgroundColor;
    return Material(
      color: ground,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                for (var i = 0; i < destinations.length; i++)
                  Expanded(
                    child: _HofThresholdTab(
                      destination: destinations[i],
                      selected: i == index,
                      onTap: () => onDestinationSelected(i),
                      semanticIndex: i + 1,
                      semanticCount: destinations.length,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HofThresholdDestination {
  const HofThresholdDestination({
    this.icon,
    this.selectedIcon,
    this.mark,
    required this.label,
    this.showBadge = false,
  });

  final IconData? icon;
  final IconData? selectedIcon;
  final Widget Function(Color color, bool selected)? mark;
  final String label;
  final bool showBadge;
}

class _HofThresholdTab extends StatelessWidget {
  const _HofThresholdTab({
    required this.destination,
    required this.selected,
    required this.onTap,
    required this.semanticIndex,
    required this.semanticCount,
  });

  final HofThresholdDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final int semanticIndex;
  final int semanticCount;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.chrome : AppColors.muted;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '${destination.label}, ${l10n.navTabOf(semanticIndex, semanticCount)}',
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.charcoal.withValues(alpha: 0.10),
        highlightColor: AppColors.charcoal.withValues(alpha: 0.06),
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  destination.mark?.call(color, selected) ??
                      Icon(
                        selected
                            ? (destination.selectedIcon ?? destination.icon)
                            : destination.icon,
                        size: 22,
                        color: color,
                      ),
                  if (destination.showBadge)
                    Positioned(
                      right: -3,
                      top: -2,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: selected ? 14 : 0,
                height: 1.5,
                decoration: BoxDecoration(
                  color: selected ? AppColors.chrome : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.1,
                  letterSpacing: 0.2,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
