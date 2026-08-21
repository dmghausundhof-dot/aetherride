import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/garage/bike_value_strip_plan.dart';
import '../../l10n/app_localizations.dart';
import 'garage_chrome.dart';

/// Vier scannbare Zahlen unter dem Foto: km, Stunden, Druck, Termin.
class BikeValueStrip extends StatelessWidget {
  const BikeValueStrip({
    super.key,
    required this.km,
    required this.hours,
    this.pressure,
    this.serviceLabel,
    this.serviceCaption,
    this.onPressure,
    this.onService,
    this.onKm,
    this.onHours,
    this.embedded = false,
  });

  final double km;
  final double hours;
  final String? pressure;
  final String? serviceLabel;
  final String? serviceCaption;
  final VoidCallback? onPressure;
  final VoidCallback? onService;
  final VoidCallback? onKm;
  final VoidCallback? onHours;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dash = l10n.garageStatDash;
    return Container(
      key: const Key('bike-value-strip'),
      decoration: embedded ? null : garageCardDecoration(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.s,
      ),
      child: Row(
        children: [
          _cell(
            key: const Key('bike-value-km'),
            label: l10n.garageStatKm,
            value: formatStripCount(km, dash),
            dash: dash,
            onTap: onKm,
            prominent: true,
          ),
          _divider(),
          _cell(
            key: const Key('bike-value-hours'),
            label: l10n.garageStatHours,
            value: formatStripCount(hours, dash, decimals: 1),
            dash: dash,
            onTap: onHours,
          ),
          _divider(),
          _cell(
            key: const Key('bike-value-pressure'),
            label: l10n.dieBoxChipPressure,
            value: pressure ?? dash,
            dash: dash,
            onTap: onPressure,
          ),
          _divider(),
          _cell(
            key: const Key('bike-value-service'),
            label: serviceCaption ?? l10n.garageStatService,
            value: serviceLabel ?? dash,
            dash: dash,
            onTap: onService,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      color: AppColors.border,
    );
  }

  Widget _cell({
    Key? key,
    required String label,
    required String value,
    required String dash,
    VoidCallback? onTap,
    bool prominent = false,
  }) {
    final known = value != dash;
    return Expanded(
      child: Semantics(
        button: onTap != null,
        enabled: onTap != null,
        label: '$label $value',
        excludeSemantics: true,
        child: Material(
          key: key,
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: AppSpacing.xs,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: prominent ? 18 : 13,
                          fontWeight: FontWeight.w800,
                          color:
                              known ? AppColors.chipIdleText : AppColors.muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
