import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/saved_route.dart';
import '../../../domain/saved_route_note.dart';
import '../../../domain/tours/tour_community_ux.dart';
import '../../../domain/tours/tour_line.dart';
import '../../../l10n/app_localizations.dart';
import '../../library/mappe_glyph.dart';
import '../../library/mappe_tour_face.dart';
import '../../library/tour_line_thumb.dart';

/// Karten-Sheet: dieselbe Sprache wie der Touren-Tab, kürzerer Hero.
class SavedMappeTile extends StatelessWidget {
  const SavedMappeTile({
    super.key,
    required this.route,
    required this.meta,
    required this.sourceBadge,
    required this.onOpen,
    required this.onDetail,
    required this.onDelete,
    this.onGoRide,
  });

  final SavedRouteEntry route;
  final SavedRouteMeta? meta;
  final String sourceBadge;
  final VoidCallback onOpen;
  final VoidCallback onDetail;
  final Future<void> Function() onDelete;
  final VoidCallback? onGoRide;

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

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                TourLineThumb(
                  coordinates: coords,
                  size: 56,
                  wide: true,
                ),
                if (spark.isNotEmpty)
                  Positioned(
                    left: 12,
                    right: canRide ? 56 : 12,
                    bottom: 8,
                    height: 14,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: MappeElevSparkPainter(spark),
                      ),
                    ),
                  ),
                if (canRide)
                  Positioned(
                    right: 8,
                    bottom: 6,
                    child: Material(
                      color: AppColors.hofGround.withValues(alpha: 0.78),
                      shape: const CircleBorder(),
                      child: IconButton(
                        key: Key('mappe-tile-ride-${route.id}'),
                        tooltip: l10n.goRide,
                        onPressed: onGoRide,
                        style: IconButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          minimumSize: const Size(36, 36),
                          padding: EdgeInsets.zero,
                        ),
                        icon: SvgPicture.asset(
                          'assets/tours/glyph-ride.svg',
                          width: 22,
                          height: 22,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 2, 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: onOpen,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      child: MappeTourFace(
                        route: route,
                        meta: meta,
                        sourceChip: sourceBadge,
                        hideLoopChip: loop,
                        showThumb: false,
                        compact: true,
                      ),
                    ),
                  ),
                  _TileIcon(
                    key: Key('mappe-tile-akte-${route.id}'),
                    tooltip: l10n.akteMein,
                    onPressed: onDetail,
                    icon: const MappeGlyph('mappe', size: 18),
                  ),
                  _TileIcon(
                    key: Key('mappe-tile-remove-${route.id}'),
                    tooltip: l10n.remove,
                    onPressed: () => unawaited(onDelete()),
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.muted,
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

class _TileIcon extends StatelessWidget {
  const _TileIcon({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const Size(40, 40),
        padding: EdgeInsets.zero,
      ),
      icon: icon,
    );
  }
}
