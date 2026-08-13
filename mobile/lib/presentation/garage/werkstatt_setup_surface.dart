import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/garage/werkstatt_setup.dart';
import '../../l10n/app_localizations.dart';

/// Kind-specific setup glance on the Werkstatt overview.
/// Rebuilds with the selected bike — not a second app.
class WerkstattSetupSurface extends StatelessWidget {
  const WerkstattSetupSurface({
    super.key,
    required this.plan,
    this.onOpenSetup,
  });

  final WerkstattSetupPlan plan;
  final VoidCallback? onOpenSetup;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lines = [
      for (final e in plan.emphasis) _line(l10n, e, plan),
    ].whereType<String>().toList();

    return Material(
      key: const Key('werkstatt-setup-surface'),
      color: AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onOpenSetup,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.garageSetupTabTitle,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                _hint(l10n, plan),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                  height: 1.35,
                ),
              ),
              if (lines.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      line,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _hint(AppLocalizations l10n, WerkstattSetupPlan plan) {
    if (plan.hasSuspension) return l10n.garageSetupTabHint;
    return l10n.garageSetupTabHintTires;
  }

  static String? _line(
    AppLocalizations l10n,
    WerkstattEmphasis e,
    WerkstattSetupPlan plan,
  ) {
    return switch (e) {
      WerkstattEmphasis.tires => l10n.werkstattSetupTires,
      WerkstattEmphasis.suspension => l10n.werkstattSetupSuspension,
      WerkstattEmphasis.suspensionUnknown =>
        l10n.werkstattSetupSuspensionUnknown,
      WerkstattEmphasis.dropper => l10n.werkstattSetupDropper,
      WerkstattEmphasis.wheel => plan.wheelLabel == null
          ? null
          : l10n.werkstattSetupWheel(plan.wheelLabel!),
      WerkstattEmphasis.cockpit => l10n.werkstattSetupCockpit,
      WerkstattEmphasis.bagsCockpit => l10n.werkstattSetupBagsCockpit,
      WerkstattEmphasis.lightsRack => l10n.werkstattSetupLightsRack,
      WerkstattEmphasis.drivetrain => l10n.werkstattSetupDrivetrain,
      WerkstattEmphasis.batteryHonest => l10n.werkstattBatteryHonest,
    };
  }
}

class WerkstattBatteryHonesty extends StatelessWidget {
  const WerkstattBatteryHonesty({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      key: const Key('werkstatt-battery-honest'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.werkstattBatteryHonest,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.werkstattBatteryHonestHint,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.muted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
