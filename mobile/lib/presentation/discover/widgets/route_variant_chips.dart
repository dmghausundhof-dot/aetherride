import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/routing/route_variant.dart';
import '../../../l10n/app_localizations.dart';

class RouteVariantChips extends StatelessWidget {
  const RouteVariantChips({
    super.key,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final RouteVariant value;
  final bool enabled;
  final ValueChanged<RouteVariant> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget chip(RouteVariant v, String label) {
      return FilterChip(
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: value == v,
        onSelected: (enabled || v == RouteVariant.planned)
            ? (_) => onChanged(v)
            : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 4,
          children: [
            chip(RouteVariant.planned, l10n.discoverVariantPlanned),
            chip(RouteVariant.flatter, l10n.discoverVariantFlatter),
            chip(RouteVariant.unpaved, l10n.discoverVariantUnpaved),
          ],
        ),
        if (!enabled) ...[
          const SizedBox(height: 4),
          Text(
            l10n.discoverVariantValhallaOnly,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ],
    );
  }
}
