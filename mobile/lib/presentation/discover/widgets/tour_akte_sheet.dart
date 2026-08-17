import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/community/tour_share_codec.dart';
import '../../../data/community/tour_share.dart';
import '../../../data/community/tour_share_revoke.dart';
import '../../../data/routing/saved_route_meta_store.dart';
import '../../../domain/bike.dart';
import '../../../domain/saved_route.dart';
import '../../../domain/saved_route_note.dart';
import '../../../domain/home/hof_stand.dart';
import '../../../domain/tours/route_visibility.dart';
import '../../../domain/tours/tour_akte.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../../shell/hof_threshold_nav.dart';
import '../saved_route_notes_section.dart';
import 'tour_community_section.dart';
import '../add_to_collection_sheet.dart';

enum _AkteShelf { mein, stimmen }

/// Tour-Detail: Mein / Stimmen. Das Rad bleibt in der Werkstatt.
class TourAkteSheet extends ConsumerStatefulWidget {
  const TourAkteSheet({
    super.key,
    required this.route,
    required this.sourceBadge,
    required this.onShowOnMap,
    this.onRemoveFromMappe,
  });

  final SavedRouteEntry route;
  final String sourceBadge;
  final VoidCallback onShowOnMap;
  final VoidCallback? onRemoveFromMappe;

  @override
  ConsumerState<TourAkteSheet> createState() => _TourAkteSheetState();
}

class _TourAkteSheetState extends ConsumerState<TourAkteSheet> {
  _AkteShelf _shelf = _AkteShelf.mein;
  SavedRouteMeta _meta = SavedRouteMeta.empty;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final meta = await SavedRouteMetaStore.get(widget.route.id);
    if (!mounted) return;
    setState(() {
      _meta = meta;
      _loaded = true;
    });
  }

  Future<void> _setVisibility(String visibility) async {
    var next = _meta;
    if (visibility == RouteVisibility.private &&
        RouteVisibility.isShared(_meta)) {
      next = _meta.copyWith(
        visibility: RouteVisibility.private,
        shareEpoch: (_meta.shareEpoch) + 1,
      );
    } else {
      next = _meta.copyWith(visibility: visibility);
    }
    await SavedRouteMetaStore.put(widget.route.id, next);
    if (visibility == RouteVisibility.private && next.shareEpoch > 0) {
      unawaited(
        revokeTourShareOnServer(
          routeId: widget.route.id,
          epoch: next.shareEpoch,
        ),
      );
    }
    if (!mounted) return;
    setState(() => _meta = next);
  }

  String _stimmenShareBody(String? catalogId, String visibility) {
    if (visibility == RouteVisibility.shared) {
      final encoded = encodeTourShareToken(widget.route, meta: _meta);
      return shareTourUrl(encoded.token);
    }
    if (catalogId != null && catalogId.isNotEmpty) {
      return TourShare.text(catalogId);
    }
    return '';
  }

  Future<void> _copyShareLink() async {
    final encoded = encodeTourShareToken(widget.route, meta: _meta);
    final url = shareTourUrl(encoded.token);
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final note = encoded.droppedTrack
        ? l10n.discoverLinkNoTrack
        : encoded.includeTrack
            ? l10n.discoverLinkCopiedTrack
            : l10n.discoverLinkCopiedStats;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(note)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalogId = catalogTourIdOf(widget.route.id, _meta);
    final stimmenId = RouteVisibility.stimmenTourIdOf(widget.route.id, _meta);
    final visibility = RouteVisibility.visibilityOf(_meta);
    final bikes = ref.watch(bikesProvider).valueOrNull ?? const <Bike>[];
    final active = bikes.cast<Bike?>().firstWhere(
          (b) => b?.isActive == true,
          orElse: () => bikes.isEmpty ? null : bikes.first,
        );
    final riddenWith = riddenWithLabel(
      preferredBikeId: _meta.preferredBikeId,
      bikes: bikes,
      active: active,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: HofThresholdNav.sheetBottomInset(context),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.akteTourKicker.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.route.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.sourceBadge} · '
              '${widget.route.distanceKm.toStringAsFixed(1)} km · '
              '${widget.route.elevationM.round()} hm · '
              '${widget.route.durationMin} min'
              '${catalogId != null ? ' · ${l10n.discoverCatalog}' : ''}'
              '${visibility == RouteVisibility.shared ? ' · ${l10n.discoverShared}' : ' · ${l10n.discoverPrivate}'}',
              style: const TextStyle(color: AppColors.muted),
            ),
            if (riddenWith != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.discoverRiddenWith(riddenWith),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.overlay,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  for (final entry in [
                    (_AkteShelf.mein, l10n.discoverOwn),
                    (_AkteShelf.stimmen, l10n.stimmenTitle),
                  ])
                    Expanded(
                      child: TextButton(
                        onPressed: () => setState(() => _shelf = entry.$1),
                        style: TextButton.styleFrom(
                          foregroundColor: _shelf == entry.$1
                              ? AppColors.chrome
                              : AppColors.muted,
                          backgroundColor: _shelf == entry.$1
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.transparent,
                        ),
                        child: Text(
                          entry.$2,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!_loaded)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_shelf == _AkteShelf.mein)
              _MeinShelf(
                l10n: l10n,
                route: widget.route,
                meta: _meta,
                visibility: visibility,
                onMeta: (m) => setState(() => _meta = m),
                onSetVisibility: _setVisibility,
                onCopyLink: _copyShareLink,
              )
            else if (_shelf == _AkteShelf.stimmen)
              stimmenId != null
                  ? TourCommunitySection(
                      tourId: stimmenId,
                      showHeading: false,
                      shareBody: _stimmenShareBody(catalogId, visibility),
                    )
                  : Text(
                      l10n.discoverPrivateCommentHint,
                      style: const TextStyle(color: AppColors.muted),
                    ),
            const SizedBox(height: 16),
            if (_shelf == _AkteShelf.mein)
              FilledButton.icon(
                onPressed: widget.onShowOnMap,
                icon: const Icon(Icons.map_outlined),
                label: Text(l10n.showOnMap),
              )
            else
              TextButton.icon(
                onPressed: widget.onShowOnMap,
                icon: const Icon(Icons.map_outlined, size: 18),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.muted,
                  visualDensity: VisualDensity.compact,
                ),
                label: Text(l10n.showOnMap),
              ),
            if (_shelf == _AkteShelf.mein && widget.onRemoveFromMappe != null)
              TextButton(
                onPressed: widget.onRemoveFromMappe,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.muted,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(l10n.discoverRemoveFromMappe),
              ),
          ],
        ),
      ),
    );
  }
}

class _MeinShelf extends StatelessWidget {
  const _MeinShelf({
    required this.l10n,
    required this.route,
    required this.meta,
    required this.visibility,
    required this.onMeta,
    required this.onSetVisibility,
    required this.onCopyLink,
  });

  final AppLocalizations l10n;
  final SavedRouteEntry route;
  final SavedRouteMeta meta;
  final String visibility;
  final ValueChanged<SavedRouteMeta> onMeta;
  final Future<void> Function(String visibility) onSetVisibility;
  final Future<void> Function() onCopyLink;

  @override
  Widget build(BuildContext context) {
    final hasTrack = route.coordinates.length >= 2 || route.tour.length >= 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasTrack ? l10n.discoverTrackLocal : l10n.discoverNoTrackEntry,
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.discoverVisibility,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(
              value: RouteVisibility.private,
              label: Text(l10n.discoverPrivateCap),
            ),
            ButtonSegment(
              value: RouteVisibility.shared,
              label: Text(l10n.discoverShareRelease),
            ),
          ],
          selected: {visibility},
          onSelectionChanged: (s) => onSetVisibility(s.first),
        ),
        const SizedBox(height: 8),
        Text(
          _akteHonesty(l10n, routeId: route.id, hasTrack: hasTrack, meta: meta),
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        if (visibility == RouteVisibility.shared) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              onCopyLink();
            },
            icon: const Icon(Icons.link, size: 18),
            label: Text(l10n.discoverCopyLink),
          ),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => unawaited(
            showAddToCollectionSheet(context, routeId: route.id),
          ),
          icon: const Icon(Icons.folder_outlined, size: 18),
          label: Text(l10n.akteAddToCollection),
        ),
        if (meta.description.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(meta.description),
        ],
        if (meta.photoPaths.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l10n.myRouteDetailPhotos,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: meta.photoPaths.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final path = meta.photoPaths[i];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(path),
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 88,
                      height: 88,
                      color: AppColors.muted.withValues(alpha: 0.2),
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 16),
        SavedRouteNotesSection(
          notes: meta.notes,
          onAdd: (text) async {
            final note = SavedRouteNote.create(text: text);
            onMeta(await SavedRouteMetaStore.addNote(route.id, note));
          },
          onRemove: (id) async {
            onMeta(await SavedRouteMetaStore.removeNote(route.id, id));
          },
        ),
      ],
    );
  }
}

String _akteHonesty(
  AppLocalizations l10n, {
  required String routeId,
  required bool hasTrack,
  required SavedRouteMeta meta,
}) {
  final catalog = catalogTourIdOf(routeId, meta);
  if (catalog != null && !hasTrack) return l10n.akteHonestyCatalog;
  if (hasTrack) return l10n.akteHonestyTrack;
  return l10n.akteHonestyNoTrack;
}
