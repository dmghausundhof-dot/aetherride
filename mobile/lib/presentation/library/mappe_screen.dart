import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/theme/app_theme.dart';
import '../../data/community/ride_group_store.dart';
import '../../data/community/tour_community_store.dart';
import '../../data/import/gpx_import.dart';
import '../../data/local/ride_prefs.dart';
import '../../data/routing/route_repository.dart';
import '../../data/routing/saved_route_meta_store.dart';
import '../../data/routing/simple_add_route.dart';
import '../../domain/community/ride_group.dart';
import '../../domain/community/ride_group_policy.dart';
import '../../domain/routing/tour_filters.dart';
import '../../domain/saved_route.dart';
import '../../domain/saved_route_note.dart';
import '../../domain/tours/add_route_start.dart';
import '../../domain/tours/route_visibility.dart';
import '../../domain/tours/tour_akte.dart';
import '../../domain/tours/tour_community_ux.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';
import '../discover/widgets/tour_akte_sheet.dart';
import '../shell/hof_threshold_nav.dart';
import '../shell/shell_tabs.dart';
import 'mappe_tour_card.dart';
import 'platz_extras.dart';

/// Touren-Tab: Liste, Tipps, Gruppen. Dieselbe Quelle wie die Karte.
class MappeScreen extends ConsumerStatefulWidget {
  const MappeScreen({super.key});

  @override
  ConsumerState<MappeScreen> createState() => MappeScreenState();
}

class MappeScreenState extends ConsumerState<MappeScreen> {
  final _store = TourCommunityStore();
  final _groups = RideGroupStore();
  final _extrasKey = GlobalKey<PlatzExtrasState>();
  final _searchCtrl = TextEditingController();
  Map<String, SavedRouteMeta> _metas = const {};
  List<TourCommunityReview> _inbox = const [];
  List<RideGroup> _activeGroups = const [];
  bool _akteBusy = false;
  bool _stimmenOpen = false;
  MappeSort _sort = MappeSort.recent;

  @override
  void initState() {
    super.initState();
    TourCommunityStore.revision.addListener(_onCommunity);
    RideGroupStore.revision.addListener(_onGroups);
    unawaited(_reloadMeta());
    unawaited(_reloadInbox());
    unawaited(_reloadGroups());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_consumePendingAkte());
    });
  }

  @override
  void dispose() {
    TourCommunityStore.revision.removeListener(_onCommunity);
    RideGroupStore.revision.removeListener(_onGroups);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onCommunity() => unawaited(_reloadInbox());

  void _onGroups() => unawaited(_reloadGroups());

  Future<void> _reloadGroups() async {
    final groups = await _groups.activeGroups();
    if (!mounted) return;
    setState(() => _activeGroups = groups);
  }

  Future<void> _reloadMeta() async {
    final all = await SavedRouteMetaStore.listAll();
    if (!mounted) return;
    setState(() => _metas = all);
  }

  Future<void> _reloadInbox() async {
    final saved = ref.read(savedRoutesProvider).valueOrNull ?? const [];
    final metas = _metas.isEmpty ? await SavedRouteMetaStore.listAll() : _metas;
    final all = await _store.allReviews();
    final ids = <String>{};
    for (final s in saved) {
      final id = RouteVisibility.stimmenTourIdOf(s.id, metas[s.id]);
      if (id != null) ids.add(id);
    }
    final inbox = [for (final r in all) if (ids.contains(r.tourId)) r];
    if (!mounted) return;
    setState(() => _inbox = inbox);
    await _groups.markInboxSeen(inbox.length);
    ref.invalidate(platzInboxBadgeProvider);
  }

  void _startRide(SavedRouteEntry s) {
    ref.read(discoverLaunchModeProvider.notifier).state =
        DiscoverLaunchMode.mine;
    ref.read(shellTabIndexProvider.notifier).state = ShellTabs.karte;
    ref.read(discoverPendingStartRideRouteIdProvider.notifier).state = s.id;
  }

  void _startRideFromMeet(RideGroup g) {
    final pending = startRidePendingIdForGroup(
      savedRouteId: g.savedRouteId,
      catalogTourId: g.catalogTourId,
      saved: ref.read(savedRoutesProvider).valueOrNull ?? const [],
      metas: _metas,
    );
    if (pending == null || pending.isEmpty) return;
    ref.read(discoverLaunchModeProvider.notifier).state =
        DiscoverLaunchMode.mine;
    ref.read(shellTabIndexProvider.notifier).state = ShellTabs.karte;
    ref.read(discoverPendingStartRideRouteIdProvider.notifier).state = pending;
  }

  RouteRepository get _routes => ref.read(routeRepositoryProvider);

  Future<void> _openAkte(SavedRouteEntry s) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return TourAkteSheet(
          route: s,
          sourceBadge: _sourceBadge(l10n, s.source),
          onRemoveFromMappe: () {
            Navigator.pop(ctx);
            unawaited(_removeFromMappe(s));
          },
          onGoRide: () {
            Navigator.pop(ctx);
            _startRide(s);
          },
          onCreateGroup: () {
            if (!RideGroupPolicy.canAttachSaved(s, _metas[s.id])) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text(l10n.platzNeedSharedTour)),
              );
              return;
            }
            Navigator.pop(ctx);
            unawaited(_extrasKey.currentState?.createGroup(attach: s));
          },
          onShowOnMap: () {
            Navigator.pop(ctx);
            ref.read(discoverLaunchModeProvider.notifier).state =
                DiscoverLaunchMode.mine;
            ref.read(discoverPendingMineProvider.notifier).state = true;
            ref.read(discoverPendingAkteRouteIdProvider.notifier).state = s.id;
            ref.read(shellTabIndexProvider.notifier).state = ShellTabs.karte;
          },
        );
      },
    );
    await _reloadMeta();
    await _reloadInbox();
  }

  Future<void> _consumePendingAkte() async {
    if (_akteBusy) return;
    final id = ref.read(discoverPendingAkteRouteIdProvider);
    if (id == null || id.isEmpty) return;
    _akteBusy = true;
    try {
      var list = ref.read(savedRoutesProvider).valueOrNull ?? const [];
      if (list.isEmpty) {
        try {
          list = await ref.read(savedRoutesProvider.future);
        } catch (_) {
          list = const [];
        }
      }
      final metas = await SavedRouteMetaStore.listAll();
      final match = resolveAkteSavedRoute(
        pendingId: id,
        saved: list,
        metas: metas,
      );
      ref.read(discoverPendingAkteRouteIdProvider.notifier).state = null;
      if (match != null && mounted) await _openAkte(match);
    } finally {
      _akteBusy = false;
    }
  }

  Future<AddRouteStartPin?> _resolveAddStart() async {
    double? gpsLat;
    double? gpsLng;
    final fix = ref.read(locationCoreProvider).lastFix;
    if (fix != null) {
      gpsLat = fix.lat;
      gpsLng = fix.lng;
    } else {
      try {
        final perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.always ||
            perm == LocationPermission.whileInUse) {
          Position? pos;
          try {
            pos = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.low,
                timeLimit: Duration(seconds: 3),
              ),
            );
          } catch (_) {
            pos = await Geolocator.getLastKnownPosition();
          }
          if (pos != null) {
            gpsLat = pos.latitude;
            gpsLng = pos.longitude;
          }
        }
      } catch (_) {}
    }
    final vp = await RidePrefs.discoverViewport();
    return resolveAddRouteStart(
      gpsLat: gpsLat,
      gpsLng: gpsLng,
      mapLat: vp?.lat,
      mapLng: vp?.lng,
    );
  }

  String _startCopy(AppLocalizations loc, AddRouteStartPin? pin) {
    if (pin == null) return loc.mappeStartNone;
    final coords =
        '${pin.lat.toStringAsFixed(3)}°N, ${pin.lng.toStringAsFixed(3)}°E';
    return pin.source == AddRouteStartSource.gps
        ? loc.mappeStartGps(coords)
        : loc.mappeStartMap(coords);
  }

  Future<void> _addRoute() async {
    final l10n = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(
      text: SimpleAddRoute.defaultName(DateTime.now()),
    );
    final pin = await _resolveAddStart();
    if (!mounted) {
      nameCtrl.dispose();
      return;
    }
    final saved = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx);
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: HofThresholdNav.sheetBottomInset(ctx),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                loc.mappeKeep,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                loc.mappeAddHint,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: loc.garageName,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _startCopy(loc, pin),
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.pop(
                    ctx,
                    SimpleAddRoute.fromStart(
                      name: nameCtrl.text,
                      lat: pin?.lat,
                      lng: pin?.lng,
                    ),
                  );
                },
                child: Text(loc.mappePutIn),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'gpx'),
                child: Text(loc.gpxImportAction),
              ),
            ],
          ),
        );
      },
    );
    nameCtrl.dispose();
    if (saved == 'gpx') {
      await _importGpx();
      return;
    }
    if (saved is! SavedRouteEntry) return;
    await _routes.saveEntry(saved);
    ref.invalidate(savedRoutesProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.mappeSaved(saved.name))),
    );
  }

  Future<void> _removeFromMappe(SavedRouteEntry s) async {
    await _routes.deleteSaved(s.id);
    await SavedRouteMetaStore.delete(s.id);
    ref.invalidate(savedRoutesProvider);
  }

  Future<void> _importGpx() async {
    final l10n = AppLocalizations.of(context);
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['gpx', 'xml'],
    );
    if (f == null) return;
    String? xml;
    try {
      if (f.path != null) {
        xml = await File(f.path!).readAsString();
      } else {
        final bytes = await f.readAsBytes();
        xml = decodeGpxBytes(bytes);
      }
    } catch (_) {}
    if (xml == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.garageFileUnreadable)),
        );
      }
      return;
    }
    final parsed = parseGpx(
      xml,
      fallbackName:
          f.name.replaceAll(RegExp(r'\.gpx$', caseSensitive: false), ''),
    );
    if (parsed == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.garageGpxInvalid)),
        );
      }
      return;
    }
    final entry = SavedRouteEntry(
      id: 'gpx-${DateTime.now().millisecondsSinceEpoch}',
      name: parsed.name,
      distanceKm: parsed.distanceKm,
      elevationM: parsed.elevationM,
      durationMin: parsed.durationMinEstimate,
      savedAt: DateTime.now().toUtc(),
      source: 'import',
      coordinates: parsed.points,
    );
    await _routes.saveEntry(entry);
    ref.invalidate(savedRoutesProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.mappeImported(entry.name))),
    );
  }

  String _sourceBadge(AppLocalizations l10n, String source) {
    switch (source) {
      case 'import':
        return l10n.myRoutesSourceImport;
      case 'recorded':
        return l10n.myRoutesSourceRecorded;
      case 'library':
        return l10n.myRoutesSourceOwn;
      default:
        return l10n.myRoutesSourceEngine;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ref.listen(discoverPendingAkteRouteIdProvider, (prev, next) {
      if (next != null && next.isNotEmpty) unawaited(_consumePendingAkte());
    });
    final savedAsync = ref.watch(savedRoutesProvider);
    final allSaved = savedAsync.valueOrNull ?? const <SavedRouteEntry>[];
    final visibility = ref.watch(tourVisibilityProvider);
    final visible = sortMappe(
      filterMappeQuery(
        RouteVisibility.filter(allSaved, visibility, _metas),
        _searchCtrl.text,
      ),
      _sort,
    );
    final meet = nextActiveMeeting(_activeGroups);
    const chipDensity = VisualDensity(horizontal: -2, vertical: -3);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.navPlatz,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.mappeSubtitle,
                      style: const TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                    if (allSaved.length >= 3) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: l10n.mappeSearch,
                          prefixIcon: const Icon(Icons.search, size: 18),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final chip in TourFilters.visibilityChips)
                          FilterChip(
                            showCheckmark: false,
                            visualDensity: chipDensity,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 6,
                            ),
                            label: Text(
                              l10n.tourVisibilityChip(chip.id),
                              style: const TextStyle(fontSize: 12),
                            ),
                            selected: visibility == chip.id,
                            onSelected: (_) {
                              ref.read(tourVisibilityProvider.notifier).state =
                                  chip.id;
                              unawaited(_reloadMeta());
                            },
                          ),
                        PopupMenuButton<MappeSort>(
                          tooltip: l10n.mappeSortRecent,
                          padding: EdgeInsets.zero,
                          onSelected: (v) => setState(() => _sort = v),
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: MappeSort.recent,
                              child: Text(l10n.mappeSortRecent),
                            ),
                            PopupMenuItem(
                              value: MappeSort.distance,
                              child: Text(l10n.mappeSortDistance),
                            ),
                            PopupMenuItem(
                              value: MappeSort.name,
                              child: Text(l10n.mappeSortName),
                            ),
                          ],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.sort, size: 16, color: AppColors.muted),
                                const SizedBox(width: 4),
                                Text(
                                  switch (_sort) {
                                    MappeSort.recent => l10n.mappeSortRecent,
                                    MappeSort.distance => l10n.mappeSortDistance,
                                    MappeSort.name => l10n.mappeSortName,
                                  },
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
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.chrome,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () => unawaited(_addRoute()),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l10n.mappeKeep),
                      ),
                    ),
                    if (meet != null) ...[
                      const SizedBox(height: 14),
                      Material(
                        color: AppColors.overlay,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        child: InkWell(
                          onTap: () => _startRideFromMeet(meet),
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l10n.mappeActiveMeet(
                                      meet.title,
                                      RideGroupPolicy.formatWhen(
                                        meet.startWindowStart,
                                        meet.startWindowEnd,
                                      ),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _startRideFromMeet(meet),
                                  child: Text(l10n.goRide),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      visible.isEmpty
                          ? l10n.mappeKicker
                          : '${l10n.mappeKicker} · ${visible.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (savedAsync.isLoading && allSaved.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              )
            else if (allSaved.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    l10n.mappeEmpty,
                    style: const TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                ),
              )
            else if (visible.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    l10n.discoverNoSavedFilter,
                    style: const TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final s = visible[i];
                    final stimmenId = RouteVisibility.stimmenTourIdOf(
                      s.id,
                      _metas[s.id],
                    );
                    return MappeTourCard(
                      route: s,
                      meta: _metas[s.id],
                      stimmenTourId: stimmenId,
                      review: stimmenId == null
                          ? null
                          : TourCommunityReview.latestFor(_inbox, stimmenId),
                      onOpen: () => unawaited(_openAkte(s)),
                      onGoRide: savedRouteHasTrack(s)
                          ? () => _startRide(s)
                          : null,
                    );
                  },
                  childCount: visible.length,
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 6),
              sliver: SliverToBoxAdapter(
                child: PlatzFoldHeader(
                  label: l10n.stimmenTitle,
                  count: _inbox.length,
                  expanded: _stimmenOpen,
                  onTap: () => setState(() {
                    _stimmenOpen = !_stimmenOpen;
                  }),
                ),
              ),
            ),
            if (_stimmenOpen && _inbox.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    l10n.mappeStimmenEmpty,
                    style: const TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                ),
              )
            else if (_stimmenOpen)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final r = _inbox[i];
                    SavedRouteEntry? hit;
                    for (final s in allSaved) {
                      if (RouteVisibility.stimmenTourIdOf(s.id, _metas[s.id]) ==
                          r.tourId) {
                        hit = s;
                        break;
                      }
                    }
                    final route = hit;
                    return ListTile(
                      dense: true,
                      visualDensity: const VisualDensity(
                        horizontal: 0,
                        vertical: -3,
                      ),
                      minVerticalPadding: 2,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      title: Text(
                        route?.name ?? r.tourId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        [
                          if (r.cloudStatus == CloudSubmitResult.pending)
                            l10n.stimmenStatusPending,
                          if (r.cloudStatus == CloudSubmitResult.localOnly)
                            l10n.stimmenStatusLocal,
                          r.authorLabel,
                          r.body,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.muted,
                      ),
                      onTap: route == null
                          ? null
                          : () => unawaited(_openAkte(route)),
                    );
                  },
                  childCount: _inbox.length.clamp(0, 8),
                ),
              ),
            SliverToBoxAdapter(
              child: PlatzExtras(
                key: _extrasKey,
                saved: allSaved,
                metas: _metas,
                store: _groups,
                visibility: visibility,
                onOpenAkte: _openAkte,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }
}
