import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/routing/elevation_client.dart';
import '../../../domain/routing/osm_surface_label.dart';
import '../../../l10n/app_localizations.dart';

class PlanSurfaceBar extends StatelessWidget {
  const PlanSurfaceBar({super.key, required this.mix});

  final List<SurfaceShare> mix;

  @override
  Widget build(BuildContext context) {
    if (mix.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    Color tone(String key) {
      switch (key) {
        case 'asphalt':
        case 'paved':
        case 'concrete':
          return const Color(0xFF5C6B73);
        case 'gravel':
        case 'compacted':
        case 'fine_gravel':
          return const Color(0xFFC4A574);
        default:
          return const Color(0xFF7A8B73);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                for (final s in mix)
                  Expanded(
                    flex: (s.share * 1000).round().clamp(20, 1000),
                    child: ColoredBox(color: tone(s.key)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          mix
              .take(3)
              .map(
                (s) =>
                    '${osmSurfaceDisplay(s.key, l10n)} ${(s.share * 100).round()}%',
              )
              .join(' · '),
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }
}
