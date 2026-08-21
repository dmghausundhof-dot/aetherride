import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../library/mappe_glyph.dart';
import 'plan_route_stats.dart';

/// Compact identity of the tour being edited — photo + original 2×2.
class PlanAdaptBanner extends StatelessWidget {
  const PlanAdaptBanner({
    super.key,
    required this.name,
    this.photoUrl,
    this.distanceKm,
    this.durationMin,
    this.elevationM,
    this.surface,
    this.looped = false,
    this.compact = false,
  });

  final String name;
  final String? photoUrl;
  final double? distanceKm;
  final int? durationMin;
  final int? elevationM;
  final String? surface;
  final bool looped;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final km = distanceKm;
    final min = durationMin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: _thumb(photoUrl),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (looped)
                      Text(
                        l10n.discoverLoopBadge,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.chrome,
                        ),
                      ),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (compact && km != null && min != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${km.toStringAsFixed(km < 10 ? 1 : 0)} km · $min min',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else if (!compact) ...[
                      const SizedBox(height: 2),
                      Text(
                        l10n.discoverAdjustStops,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!compact && km != null && min != null) ...[
          const SizedBox(height: 8),
          PlanRouteStats(
            distanceKm: km,
            durationMin: min,
            ascentM: elevationM?.toDouble(),
            surfaceLine: (surface ?? '').trim().isEmpty ? null : surface,
            looped: false,
          ),
        ],
      ],
    );
  }

  Widget _thumb(String? url) {
    final u = url?.trim() ?? '';
    if (u.isEmpty) {
      return const ColoredBox(
        color: Color(0xFF2A2E32),
        child: Center(child: MappeGlyph('elevation', size: 22)),
      );
    }
    if (u.startsWith('http://') || u.startsWith('https://')) {
      return Image.network(
        u,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const ColoredBox(
          color: Color(0xFF2A2E32),
          child: Center(child: MappeGlyph('elevation', size: 22)),
        ),
      );
    }
    return Image.asset(
      u,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const ColoredBox(
        color: Color(0xFF2A2E32),
        child: Center(child: MappeGlyph('elevation', size: 22)),
      ),
    );
  }
}
