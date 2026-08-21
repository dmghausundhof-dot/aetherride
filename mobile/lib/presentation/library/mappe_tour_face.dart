import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/saved_route.dart';
import '../../domain/saved_route_note.dart';
import '../../domain/tours/route_visibility.dart';
import '../../domain/tours/tour_community_ux.dart';
import '../../domain/tours/tour_line.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import 'mappe_glyph.dart';
import 'tour_line_thumb.dart';

/// Spur, Stats, Chips — dasselbe Motiv wie Web `MappeTourFace`.
class MappeTourFace extends StatelessWidget {
  const MappeTourFace({
    super.key,
    required this.route,
    required this.meta,
    this.size = 80,
    this.conditionTag,
    this.caption,
    this.awayLabel,
    this.showThumb = true,
    this.hideLoopChip = false,
    this.sourceChip,
    this.thumbWide = false,
    this.compact = false,
  });

  final SavedRouteEntry route;
  final SavedRouteMeta? meta;
  final double size;
  final String? conditionTag;
  final String? caption;
  final String? awayLabel;
  final bool showThumb;
  final bool hideLoopChip;
  final String? sourceChip;
  final bool thumbWide;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shared = RouteVisibility.isShared(meta);
    final stats = mappeCardStatParts(route);
    final coords = trackCoordsOf(
      coordinates: route.coordinates,
      tour: route.tour,
    );
    final loop = savedRouteIsLoop(route);
    final nameSize = compact ? 13.0 : (size >= 80 ? 15.0 : 14.0);
    final gap = compact ? 3.0 : 6.0;
    final scale = compact ? null : mappeFaceTag(meta?.mtbScale);
    final surface = compact ? null : mappeFaceTag(meta?.surface);
    final chips = <Widget>[
      if (shared)
        _Chip(
          icon: 'shared',
          text: l10n.discoverShared,
        ),
      if (sourceChip != null && sourceChip!.isNotEmpty)
        _Chip(icon: 'mappe', text: sourceChip!),
      if (loop && !hideLoopChip) _Chip(icon: 'loop', text: l10n.loopTag),
      if (conditionTag != null)
        _Chip(
          icon: 'stimmen',
          text: l10n.stimmeTagLabel(conditionTag!),
        ),
      if (scale != null) _Chip(text: scale),
      if (surface != null) _Chip(text: surface),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showThumb) ...[
          SizedBox(
            width: thumbWide ? size * 1.7 : size,
            child: TourLineThumb(
              coordinates: coords,
              size: size,
              wide: thumbWide,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                route.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: nameSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: gap),
              if (stats != null)
                compact
                    ? Text(
                        [
                          stats.km,
                          if (stats.hm != null) stats.hm!,
                          stats.min,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFeatures: [FontFeature.tabularFigures()],
                          color: AppColors.muted,
                        ),
                      )
                    : Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          _Stat(icon: 'distance', text: stats.km),
                          if (stats.hm != null)
                            _Stat(icon: 'elevation', text: stats.hm!),
                          _Stat(icon: 'duration', text: stats.min),
                        ],
                      )
              else
                Text(
                  l10n.noTrackLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              if (chips.isNotEmpty) ...[
                SizedBox(height: gap),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: chips,
                ),
              ],
              if (awayLabel != null && awayLabel!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  awayLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ],
              if (caption != null && caption!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.text});
  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MappeGlyph(icon, size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontFeatures: [FontFeature.tabularFigures()],
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({this.icon, required this.text});
  final String? icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            MappeGlyph(icon!, size: 12),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
