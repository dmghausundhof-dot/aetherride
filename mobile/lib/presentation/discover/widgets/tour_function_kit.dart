import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/bike.dart';
import '../../../domain/tours/tour_function_copy.dart';
import '../../../domain/tours/tour_functions.dart';

/// Funktionskit + Termin — Parität zur Web-Tourseite.
class TourFunctionKit extends StatelessWidget {
  const TourFunctionKit({
    super.key,
    required this.tourId,
    this.regionSlug,
    this.categories = const [],
    this.tags = const [],
    this.onOpenGroup,
    this.compact = false,
  });

  final String tourId;
  final String? regionSlug;
  final List<BikeCategory> categories;
  final List<String> tags;
  final VoidCallback? onOpenGroup;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'de';
    final copy = tourFunctionCopy(lang);
    final slug = regionSlug ?? regionSlugForTour(tourId, tags);
    final states = tourFunctionStates(
      tourId: tourId,
      regionSlug: slug,
      categories: categories,
    );
    final events = eventsForTour(tourId);
    final clubs = clubsForTour(
      tourId: tourId,
      regionSlug: slug,
      categories: categories,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          copy.kitTitle,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          copy.kitLead,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final state in states)
              Container(
                key: Key('tour-fn-${state.id}'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: state.available
                      ? AppColors.overlay
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: state.available
                      ? null
                      : Border.all(color: AppColors.muted.withValues(alpha: 0.35)),
                ),
                child: Text(
                  copy.label(state.id),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: state.available ? null : AppColors.muted,
                  ),
                ),
              ),
          ],
        ),
        if (events.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            copy.eventTitle,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            copy.eventLead,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
          for (final event in events) ...[
            const SizedBox(height: 8),
            DecoratedBox(
              key: Key('tour-event-${event.id}'),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.muted.withValues(alpha: 0.25)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${event.sport} · ${event.dateLabel}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.blurb,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
        if (!compact) ...[
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.muted.withValues(alpha: 0.25)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.groupTitle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    copy.groupBody,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  if (onOpenGroup != null)
                    TextButton(
                      onPressed: onOpenGroup,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.chrome,
                      ),
                      child: Text(copy.groupCta),
                    ),
                  if (clubs.isNotEmpty)
                    Text(
                      clubs.map((c) => c.name).join(' · '),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
