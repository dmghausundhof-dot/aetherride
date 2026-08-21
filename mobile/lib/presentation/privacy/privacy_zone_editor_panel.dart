import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/privacy/privacy_zone_map.dart';
import '../../l10n/app_localizations.dart';

/// Untere Leiste des Zonen-Karteneditors (Label, Radius, optionale Koordinaten).
class PrivacyZoneEditorPanel extends StatelessWidget {
  const PrivacyZoneEditorPanel({
    super.key,
    required this.labelController,
    required this.radiusM,
    required this.onRadiusChanged,
    this.onRadiusChangeEnd,
    required this.latController,
    required this.lngController,
    required this.onApplyCoords,
    required this.placed,
  });

  final TextEditingController labelController;
  final double radiusM;
  final ValueChanged<double> onRadiusChanged;
  final ValueChanged<double>? onRadiusChangeEnd;
  final TextEditingController latController;
  final TextEditingController lngController;
  final VoidCallback onApplyCoords;
  final bool placed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = clampPrivacyZoneRadius(radiusM);
    return Material(
      color: AppColors.elevated,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              placed ? l10n.privacyZoneRadiusHint : l10n.privacyZoneTapHint,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: labelController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.privacyZoneLabel,
                hintText: kPrivacyZoneDefaultLabel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final preset in kPrivacyZoneRadiusPresetsM)
                  ChoiceChip(
                    label: Text(privacyZoneRadiusLabel(preset)),
                    selected: (r - preset).abs() < 1,
                    onSelected: (_) {
                      onRadiusChanged(preset);
                      onRadiusChangeEnd?.call(preset);
                    },
                  ),
              ],
            ),
            Row(
              children: [
                Text(l10n.privacyZoneRadiusWord),
                Expanded(
                  child: Slider(
                    min: kPrivacyZoneMinRadiusM,
                    max: kPrivacyZoneMaxRadiusM,
                    value: r,
                    label: privacyZoneRadiusLabel(r),
                    onChanged: onRadiusChanged,
                    onChangeEnd: onRadiusChangeEnd,
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Text(
                    privacyZoneRadiusLabel(r),
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  l10n.privacyZoneCoords,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: Text(
                  l10n.privacyZoneCoordsHint,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                children: [
                  TextField(
                    controller: latController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Lat',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: lngController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Lng',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onApplyCoords,
                      child: Text(l10n.privacyZoneApplyCoords),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
