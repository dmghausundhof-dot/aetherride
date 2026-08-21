import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_theme.dart';
import '../../data/community/tour_community_store.dart';
import '../../domain/saved_route.dart';
import '../../domain/saved_route_note.dart';
import '../../domain/tours/tour_community_ux.dart';
import '../../domain/tours/tour_line.dart';
import '../../l10n/app_localizations.dart';
import '../discover/widgets/tour_social_proof.dart';
import 'mappe_tour_face.dart';
import 'tour_line_thumb.dart';

double mappeLandscapeHeroSize(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w < 360) return 72;
  if (w < 400) return 80;
  return 92;
}

/// Eine gemerkte Tour: Landschafts-Spur, Stats, Stimme-Teaser, Losfahren.
class MappeTourCard extends StatelessWidget {
  const MappeTourCard({
    super.key,
    required this.route,
    required this.meta,
    required this.onOpen,
    this.onGoRide,
    this.review,
    this.stimmenTourId,
    this.caption,
    this.awayLabel,
    this.sourceChip,
  });

  final SavedRouteEntry route;
  final SavedRouteMeta? meta;
  final VoidCallback onOpen;
  final VoidCallback? onGoRide;
  final TourCommunityReview? review;
  final String? stimmenTourId;
  final String? caption;
  final String? awayLabel;
  final String? sourceChip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canRide = onGoRide != null && savedRouteHasTrack(route);
    final coords = trackCoordsOf(
      coordinates: route.coordinates,
      tour: route.tour,
    );
    final loop = savedRouteIsLoop(route);
    final spark = mappeElevSpark(coords);
    final hero = mappeLandscapeHeroSize(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('platz-tour-${route.id}'),
          onTap: onOpen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  TourLineThumb(
                    coordinates: coords,
                    size: hero,
                    wide: true,
                  ),
                  if (spark.isNotEmpty)
                    Positioned(
                      left: 12,
                      right: canRide ? 56 : 12,
                      bottom: 10,
                      height: 16,
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: MappeElevSparkPainter(spark),
                        ),
                      ),
                    ),
                  if (canRide)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Material(
                        color: AppColors.hofGround.withValues(alpha: 0.78),
                        shape: const CircleBorder(),
                        child: IconButton(
                          key: Key('platz-tour-ride-${route.id}'),
                          tooltip: l10n.goRide,
                          onPressed: onGoRide,
                          icon: SvgPicture.asset(
                            'assets/tours/glyph-ride.svg',
                            width: 32,
                            height: 32,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MappeTourFace(
                      route: route,
                      meta: meta,
                      conditionTag: review?.conditionTag,
                      caption: caption,
                      awayLabel: awayLabel,
                      showThumb: false,
                      hideLoopChip: loop,
                      sourceChip: sourceChip,
                    ),
                    if (stimmenTourId != null) ...[
                      const SizedBox(height: 6),
                      TourSocialProof(tourId: stimmenTourId!, compact: true),
                    ],
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
