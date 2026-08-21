import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/community/tour_share.dart';
import '../../../data/community/tour_share_codec.dart';
import '../../../data/community/tour_share_revoke.dart';
import '../../../data/routing/saved_route_meta_store.dart';
import '../../../domain/bike.dart';
import '../../../domain/home/hof_stand.dart';
import '../../../domain/routing/track_elevation.dart';
import '../../../domain/saved_route.dart';
import '../../../domain/saved_route_note.dart';
import '../../../domain/tours/route_visibility.dart';
import '../../../domain/tours/tour_akte.dart';
import '../../../domain/tours/tour_community_ux.dart';
import '../../../domain/tours/tour_line.dart';
import '../../../domain/tours/tour_listing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../../library/tour_line_thumb.dart';
import '../../shell/hof_threshold_nav.dart';
import '../add_to_collection_sheet.dart';
import '../saved_route_notes_section.dart';
import 'tour_community_section.dart';

enum _AkteShelf { mein, stimmen }

/// Tour-Detail: Freigeben / Stimmen. Das Rad bleibt am Stand.
class TourAkteSheet extends ConsumerStatefulWidget {
  const TourAkteSheet({
    super.key,
    required this.route,
    required this.sourceBadge,
    required this.onShowOnMap,
    this.onRemoveFromMappe,
    this.onGoRide,
    this.onCreateGroup,
  });

  final SavedRouteEntry route;
  final String sourceBadge;
  final VoidCallback onShowOnMap;
  final VoidCallback? onRemoveFromMappe;
  final VoidCallback? onGoRide;
  final VoidCallback? onCreateGroup;

  @override
  ConsumerState<TourAkteSheet> createState() => _TourAkteSheetState();
}

class _TourAkteSheetState extends ConsumerState<TourAkteSheet> {
  _AkteShelf _shelf = _AkteShelf.mein;
  SavedRouteMeta _meta = SavedRouteMeta.empty;
  bool _loaded = false;
  late String _name;

  @override
  void initState() {
    super.initState();
    _name = widget.route.name;
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
    final catalog = catalogTourIdOf(widget.route.id, _meta) != null;
    final now = DateTime.now().toUtc();
    final snap = listingSnapshotOf(_meta);
    final nextSnap = visibility == RouteVisibility.private
        ? unpublishTour(snap)
        : beginTourShare(snap, now: now, isCatalog: catalog);
    final next = applyListingSnapshot(_meta, nextSnap);
    await SavedRouteMetaStore.put(widget.route.id, next);
    if (nextSnap.visibility == RouteVisibility.private &&
        nextSnap.shareEpoch > snap.shareEpoch) {
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

  Future<void> _rename() async {
    final l10n = AppLocalizations.of(context);
    final ctrl = TextEditingController(text: _name);
    final next = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.mappeRename),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            maxLength: 80,
            decoration: InputDecoration(labelText: l10n.garageName),
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
    ctrl.dispose();
    final trimmed = next?.trim() ?? '';
    if (trimmed.isEmpty || trimmed == _name) return;
    await ref
        .read(routeRepositoryProvider)
        .renameSaved(widget.route.id, trimmed);
    ref.invalidate(savedRoutesProvider);
    if (!mounted) return;
    setState(() => _name = trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalogId = catalogTourIdOf(widget.route.id, _meta);
    final stimmenId = RouteVisibility.stimmenTourIdOf(widget.route.id, _meta);
    final visibility = RouteVisibility.visibilityOf(_meta);
    final bikes = ref.watch(bikesProvider).valueOrNull ?? const <Bike>[];
    final rides = ref.watch(recentRidesProvider).valueOrNull ?? const [];
    final last = lastRideForSavedRoute(
      savedRouteId: widget.route.id,
      catalogTourId: catalogId,
      rides: rides,
    );
    final riddenWith = riddenWithLabel(
      preferredBikeId: last?.bikeId ?? _meta.preferredBikeId,
      bikes: bikes,
      active: null,
    );
    final canRide = widget.onGoRide != null && savedRouteHasTrack(widget.route);
    final caption = joinMappeCaption([
      if (riddenWith != null) l10n.discoverRiddenWith(riddenWith),
      if (last != null)
        l10n.mappeLastRidden(formatMappeDay(last.endedAt ?? last.startedAt)),
    ]);
    final hm = mappeHonestHm(
      widget.route.elevationM,
      widget.route.distanceKm,
      source: widget.route.source,
      hasRealElev: trackHasRealElev(
        trackCoordsOf(
          coordinates: widget.route.coordinates,
          tour: widget.route.tour,
        ),
      ),
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
              l10n.akteTourKicker,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () => unawaited(_rename()),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.muted,
                  ),
                  child: Text(l10n.mappeRename),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (widget.sourceBadge.trim().isNotEmpty) widget.sourceBadge,
                '${widget.route.distanceKm.toStringAsFixed(1)} km',
                if (hm != null) '$hm hm',
                '${widget.route.durationMin} min',
                if (catalogId != null) l10n.discoverCatalog,
                if (visibility == RouteVisibility.shared) l10n.discoverShared,
              ].join(' · '),
              style: const TextStyle(color: AppColors.muted),
            ),
            if (caption != null) ...[
              const SizedBox(height: 4),
              Text(
                caption,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TourLineThumb(
                coordinates: trackCoordsOf(
                  coordinates: widget.route.coordinates,
                  tour: widget.route.tour,
                ),
                size: 88,
                wide: true,
              ),
            ),
            const SizedBox(height: 12),
            _AkteRideBar(
              l10n: l10n,
              canRide: canRide,
              onGoRide: widget.onGoRide,
              onShowOnMap: widget.onShowOnMap,
            ),
            const SizedBox(height: 12),
            _AkteChromePair(
              left: l10n.akteMein,
              right: l10n.stimmenTitle,
              selectedIsLeft: _shelf == _AkteShelf.mein,
              onLeft: () => setState(() => _shelf = _AkteShelf.mein),
              onRight: () => setState(() => _shelf = _AkteShelf.stimmen),
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
            if (_shelf == _AkteShelf.mein) ...[
              if (widget.onCreateGroup != null)
                OutlinedButton.icon(
                  onPressed: widget.onCreateGroup,
                  icon: const Icon(Icons.group_add_outlined, size: 18),
                  label: Text(l10n.mappeInviteFriends),
                ),
              if (widget.onRemoveFromMappe != null)
                TextButton(
                  onPressed: widget.onRemoveFromMappe,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.muted,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(l10n.discoverRemoveFromMappe),
                ),
            ],
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
    final hasTrack = savedRouteHasTrack(route);
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
        _AkteChromePair(
          left: l10n.discoverPrivateCap,
          right: l10n.discoverShareRelease,
          selectedIsLeft: visibility == RouteVisibility.private,
          onLeft: () => unawaited(onSetVisibility(RouteVisibility.private)),
          onRight: () => unawaited(onSetVisibility(RouteVisibility.shared)),
        ),
        const SizedBox(height: 8),
        Text(
          _akteHonesty(l10n, routeId: route.id, hasTrack: hasTrack, meta: meta),
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        if (listingAkteHint(parseListingState(meta.listing)) != null) ...[
          const SizedBox(height: 8),
          Text(
            listingAkteHint(parseListingState(meta.listing))!,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
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
                final pinned =
                    meta.media.any((m) => m.path == path && m.hasPin);
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Image.file(
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
                      if (pinned)
                        const Positioned(
                          left: 4,
                          top: 4,
                          child: Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.white,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black54),
                            ],
                          ),
                        ),
                    ],
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

class _AkteChromePair extends StatelessWidget {
  const _AkteChromePair({
    required this.left,
    required this.right,
    required this.selectedIsLeft,
    required this.onLeft,
    required this.onRight,
  });

  final String left;
  final String right;
  final bool selectedIsLeft;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.overlay,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(child: _seg(left, selectedIsLeft, onLeft)),
            Expanded(child: _seg(right, !selectedIsLeft, onRight)),
          ],
        ),
      ),
    );
  }

  Widget _seg(String label, bool on, VoidCallback tap) {
    return TextButton(
      onPressed: tap,
      style: TextButton.styleFrom(
        foregroundColor: on ? AppColors.onAccent : AppColors.muted,
        backgroundColor: on ? AppColors.chrome : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _AkteRideBar extends StatelessWidget {
  const _AkteRideBar({
    required this.l10n,
    required this.canRide,
    required this.onGoRide,
    required this.onShowOnMap,
  });

  final AppLocalizations l10n;
  final bool canRide;
  final VoidCallback? onGoRide;
  final VoidCallback onShowOnMap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.overlay,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: [
            if (canRide)
              SvgPicture.asset(
                'assets/tours/glyph-ride.svg',
                width: 32,
                height: 32,
              )
            else
              const Icon(Icons.map_outlined, color: AppColors.muted),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: canRide ? onGoRide : onShowOnMap,
                child: Text(
                  canRide ? l10n.goRide : l10n.showOnMap,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (canRide)
              TextButton(
                onPressed: onShowOnMap,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.muted,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(l10n.showOnMap),
              ),
          ],
        ),
      ),
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
