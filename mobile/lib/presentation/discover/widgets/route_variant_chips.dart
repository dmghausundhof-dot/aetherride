import 'package:flutter/material.dart';

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
    Widget chip(RouteVariant v, String label, {bool locked = false}) {
      return FilterChip(
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: value == v,
        onSelected: locked ? null : (_) => onChanged(v),
      );
    }

    if (!enabled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          chip(RouteVariant.planned, l10n.discoverVariantPlanned, locked: true),
          const SizedBox(height: 4),
          Text(
            l10n.discoverVariantValhallaOnly,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 4,
      children: [
        chip(RouteVariant.planned, l10n.discoverVariantPlanned),
        chip(RouteVariant.flatter, l10n.discoverVariantFlatter),
        chip(RouteVariant.unpaved, l10n.discoverVariantUnpaved),
      ],
    );
  }
}
