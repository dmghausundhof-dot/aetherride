import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/community/filmstrip.dart';
import '../../../l10n/app_localizations.dart';

class PlanFilmstrip extends StatelessWidget {
  const PlanFilmstrip({
    super.key,
    required this.shots,
    required this.onTap,
  });

  final List<FilmstripShot> shots;
  final void Function(FilmstripShot shot) onTap;

  @override
  Widget build(BuildContext context) {
    if (shots.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: shots.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (ctx, i) {
              final s = shots[i];
              return GestureDetector(
                onTap: () => onTap(s),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  child: Image.network(
                    s.imageUrl,
                    width: 108,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 108,
                      height: 72,
                      color: AppColors.chipIdle,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.discoverFilmstripAttribution,
          style: const TextStyle(fontSize: 10, color: AppColors.muted),
        ),
      ],
    );
  }
}
