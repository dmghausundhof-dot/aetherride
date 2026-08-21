import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/community/tour_community_store.dart';
import '../../domain/saved_route.dart';
import '../../domain/tours/tour_community_ux.dart';
import '../../domain/tours/tour_line.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import 'mappe_glyph.dart';
import 'tour_line_thumb.dart';

/// Stimme im Regal: Quer-Spur wie die Tour-Karte, kein ListTile.
class MappeStimmeRow extends StatelessWidget {
  const MappeStimmeRow({
    super.key,
    required this.review,
    this.route,
    this.onOpen,
    this.tight = false,
  });

  final TourCommunityReview review;
  final SavedRouteEntry? route;
  final VoidCallback? onOpen;
  final bool tight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = stimmeInboxTitle(
      untitled: l10n.stimmeInboxUntitled,
      routeName: route?.name,
      body: review.body,
    );
    final tag = review.conditionTag;
    final pending = review.cloudStatus == CloudSubmitResult.pending;
    final localOnly = review.cloudStatus == CloudSubmitResult.localOnly;
    final showBody = stimmeInboxShowsBody(title: name, body: review.body);
    final bits = [
      if (pending) l10n.stimmenStatusPending,
      if (localOnly) l10n.stimmenStatusLocal,
      if (showBody) review.body,
    ];
    final coords = route == null
        ? const <List<double>>[]
        : trackCoordsOf(
            coordinates: route!.coordinates,
            tour: route!.tour,
          );

    return Padding(
      padding: tight
          ? const EdgeInsets.only(bottom: 8)
          : const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: tight ? AppColors.elevated : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (route != null)
                TourLineThumb(coordinates: coords, size: 56, wide: true)
              else
                const Padding(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: MappeGlyph('stimmen', size: 18),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 8, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (bits.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              bits.join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                          if (tag != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: tight
                                    ? AppColors.surfaceDark
                                    : AppColors.elevated,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const MappeGlyph('stimmen', size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.stimmeTagLabel(tag),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onOpen != null)
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.muted,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
