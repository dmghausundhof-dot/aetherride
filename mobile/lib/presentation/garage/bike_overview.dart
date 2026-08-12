import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/bike.dart';
import '../../domain/garage/garage_primary_cta.dart';
import '../../domain/maintenance/intervals.dart';
import '../../l10n/app_localizations.dart';

/// Einfache Bike-Karte für die Garage (Einsteiger-Default).
///
/// Kein Komponenten-/Silhouette-Schema: Name, Typ (inkl. E-Bike), Kilometer
/// und Wartungsstatus auf einen Blick. Optional eine Primär-CTA.
/// Domain-Mapper/Anchors bleiben unter `domain/garage/` für Experten nutzbar.
class BikeOverviewCard extends StatelessWidget {
  const BikeOverviewCard({
    super.key,
    required this.bike,
    this.partsCount = 0,
    this.maintenanceDue = const [],
    this.compact = false,
    this.showTitle = true,
    this.showMeta = true,
    this.primaryAction,
    this.onPrimaryAction,
    this.onTap,
  });

  final Bike bike;
  final int partsCount;
  final List<MaintenanceAlert> maintenanceDue;
  final bool compact;

  /// Listen-Preview: Titelzeile „Aktives Bike · …“.
  final bool showTitle;

  /// km / Teile / Rahmen — ausblenden wenn darunter Stat-Chips stehen.
  final bool showMeta;

  /// Einsteiger: eine klare Aktion (Wartung / Teil / Aktiv / Setup).
  final GaragePrimaryAction? primaryAction;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final overdue =
        maintenanceDue.any((a) => a.status == DueStatus.overdue);
    final dueCount = maintenanceDue.length;
    final statusLabel = dueCount == 0
        ? l10n.garageMaintOk
        : overdue
            ? l10n.garageMaintOverdue(dueCount)
            : l10n.garageMaintDue(dueCount);
    final statusColor = dueCount == 0
        ? AppColors.forestOnDark
        : overdue
            ? const Color(0xFFFF6B6B)
            : const Color(0xFFEAB308);

    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: bike.isActive ? AppColors.accent : AppColors.border,
          width: bike.isActive ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.m,
          compact ? AppSpacing.s : AppSpacing.m,
          AppSpacing.m,
          compact ? AppSpacing.s : AppSpacing.m,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              Text(
                bike.isActive
                    ? l10n.garageActiveBike(bike.name)
                    : bike.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
              ),
              const SizedBox(height: AppSpacing.s),
            ],
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _Pill(
                  label: bike.categoryLabel,
                  foreground: AppColors.accent,
                  background: AppColors.accent.withValues(alpha: 0.16),
                ),
                if (bike.hasElectricAssist &&
                    !bike.categoryLabel.toLowerCase().startsWith('e-') &&
                    !bike.categoryLabel.toLowerCase().startsWith('e '))
                  _Pill(
                    label: l10n.garageEbikeBadge,
                    foreground: AppColors.onAccent,
                    background: AppColors.chipIdle,
                  ),
                if (bike.isActive)
                  _Pill(
                    label: l10n.garageActive,
                    foreground: AppColors.onAccent,
                    background: AppColors.accent,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Row(
              children: [
                Icon(Icons.circle, size: 8, color: statusColor),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (showMeta) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                [
                  '${bike.odometerKm.toStringAsFixed(0)} km',
                  if (partsCount > 0) l10n.garagePartsCount(partsCount),
                  if (bike.frameSize != null && bike.frameSize!.isNotEmpty)
                    bike.frameSize!,
                ].join(' · '),
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.muted,
                ),
              ),
            ],
            if (primaryAction != null && onPrimaryAction != null) ...[
              const SizedBox(height: AppSpacing.m),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    minimumSize: const Size(0, 44),
                  ),
                  onPressed: onPrimaryAction,
                  child: Text(_ctaLabel(l10n, primaryAction!)),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: card,
      ),
    );
  }

  static String _ctaLabel(AppLocalizations l10n, GaragePrimaryAction a) {
    return switch (a) {
      GaragePrimaryAction.viewMaintenance => l10n.garageCtaMaintenance,
      GaragePrimaryAction.addPart => l10n.garageCtaAddPart,
      GaragePrimaryAction.setActive => l10n.garageCtaSetActive,
      GaragePrimaryAction.openSetup => l10n.garageCtaOpenSetup,
    };
  }
}

/// Technische Specs hinter einer Klappe — Amateure, ohne Einsteiger-Chaos.
class BikeTechDetailsPanel extends StatelessWidget {
  const BikeTechDetailsPanel({
    super.key,
    required this.bike,
    this.initiallyExpanded = false,
  });

  final Bike bike;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = <(String, String)>[
      if (bike.brand != null || bike.model != null)
        (
          l10n.garageBrandModel,
          [
            if (bike.brand != null) bike.brand!,
            if (bike.model != null) bike.model!,
            if (bike.year != null) '${bike.year}',
          ].join(' '),
        ),
      if (bike.frameSize != null && bike.frameSize!.isNotEmpty)
        (l10n.garageFrameSize, bike.frameSize!),
      if (bike.wheelSize != null) (l10n.garageWheelSize, bike.wheelSize!.label),
      if (bike.travelFrontMm != null)
        (
          l10n.garageTravel,
          '${bike.travelFrontMm}/${bike.travelRearMm ?? '–'} mm',
        ),
      (l10n.garageHours, '${bike.hours.toStringAsFixed(1)} h'),
      ('km', '${bike.odometerKm.toStringAsFixed(0)} km'),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.s),
        title: Text(
          l10n.garageTechDetails,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          l10n.garageTechHint,
          style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
        ),
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.$1,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  Text(
                    row.$2,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}
