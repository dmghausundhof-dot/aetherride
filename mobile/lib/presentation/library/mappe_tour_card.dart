import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/community/tour_community_store.dart';
import '../../domain/saved_route.dart';
import '../../domain/saved_route_note.dart';
import '../../domain/tours/route_visibility.dart';
import '../../domain/tours/tour_community_ux.dart';
import '../../domain/tours/tour_functions.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../discover/widgets/tour_social_proof.dart';

/// Eine gemerkte Tour: Stats, Stimme-Teaser, Losfahren — kein Feed.
class MappeTourCard extends StatelessWidget {
  const MappeTourCard({
    super.key,
    required this.route,
    required this.meta,
    required this.onOpen,
    this.onGoRide,
    this.review,
    this.stimmenTourId,
  });

  final SavedRouteEntry route;
  final SavedRouteMeta? meta;
  final VoidCallback onOpen;
  final VoidCallback? onGoRide;
  final TourCommunityReview? review;
  final String? stimmenTourId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shared = RouteVisibility.isShared(meta);
    final vis = shared ? l10n.discoverShared : l10n.discoverPrivate;
    final stats = mappeCardStats(route);
    final tag = review?.conditionTag;
    final canRide = onGoRide != null && savedRouteHasTrack(route);
    final attached =
        stimmenTourId == null ? eventsForTour('') : eventsForTour(stimmenTourId!);
    final event = attached.isEmpty ? null : attached.first;
    final subtitle = [
      if (stats.isNotEmpty) stats,
      vis,
      if (tag != null) l10n.stimmeTagLabel(tag),
      if (event != null) event.dateLabel,
    ].join(' · ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('platz-tour-${route.id}'),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                    if (stimmenTourId != null) ...[
                      const SizedBox(height: 6),
                      TourSocialProof(tourId: stimmenTourId!, compact: true),
                    ],
                  ],
                ),
              ),
              if (canRide)
                IconButton(
                  key: Key('platz-tour-ride-${route.id}'),
                  tooltip: l10n.goRide,
                  onPressed: onGoRide,
                  icon: const Icon(Icons.play_arrow_rounded),
                  color: AppColors.accent,
                )
              else
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.muted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
