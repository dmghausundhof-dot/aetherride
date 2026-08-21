import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import '../../domain/routing/tour_filters.dart';
import '../../domain/home/hof_stand.dart';
import '../../domain/saved_route.dart';
import '../../domain/saved_route_note.dart';
import '../../domain/tours/add_route_start.dart';
import '../../domain/tours/route_visibility.dart';
import '../../domain/tours/tour_akte.dart';
import '../../domain/tours/tour_community_ux.dart';
import '../../domain/tours/tour_line.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';
import '../discover/widgets/tour_akte_sheet.dart';
import '../ride/widgets/ride_group_extend_sheet.dart';
import '../shell/hof_threshold_nav.dart';
import '../shell/shell_tabs.dart';
import '../shared/chrome_glyph.dart';
import 'mappe_empty.dart';
import 'mappe_glyph.dart';
import 'mappe_shelf.dart';
import 'mappe_stimme_row.dart';
import 'mappe_tour_card.dart';
import 'platz_extras.dart';
import 'tour_line_thumb.dart';

/// Touren-Tab: Liste, Stimmen, Gruppen. Dieselbe Quelle wie die Karte.
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
  double? _awayLat;
  double? _awayLng;
  final _elevBackfillTried = <String>{};
  var _elevBackfillRunning = false;

  @override
  void initState() {
    super.initState();
    TourCommunityStore.revision.addListener(_onCommunity);
    RideGroupStore.revision.addListener(_onGroups);
    unawaited(_reloadMeta());
    unawaited(_reloadInbox());
    unawaited(_reloadGroups());
    unawaited(_warmAwayFix());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_consumePendingAkte());
      unawaited(_backfillElev());
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

  Future<void> _warmAwayFix() async {
    final core = ref.read(locationCoreProvider).lastFix;
    if (core != null) {
      if (!mounted) return;
      setState(() {
        _awayLat = core.lat;
        _awayLng = core.lng;
      });
      return;
    }
    try {
      final pos = await Geolocator.getLastKnownPosition();
      if (pos == null || !mounted) return;
      setState(() {
        _awayLat = pos.latitude;
        _awayLng = pos.longitude;
      });
    } catch (_) {}
  }

  Future<void> _backfillElev() async {
    if (_elevBackfillRunning) return;
    _elevBackfillRunning = true;
    try {
      final list = await ref.read(savedRoutesProvider.future);
      var wrote = false;
      for (final s in list) {
        if (_elevBackfillTried.contains(s.id)) continue;
        if (!savedRouteNeedsElevBackfill(s)) {
          _elevBackfillTried.add(s.id);
          continue;
        }
        _elevBackfillTried.add(s.id);
        final updated = await _routes.backfillTrackElevation(s);
        if (updated != null) {
          wrote = true;
          if (mounted) ref.invalidate(savedRoutesProvider);
        }
      }
      if (wrote && mounted) ref.invalidate(savedRoutesProvider);
    } catch (_) {
      // API optional — 2D-Spur bleibt ohne Kurve.
    } finally {
      _elevBackfillRunning = false;
    }
  }

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
    final inbox = [
      for (final r in all)
        if (ids.contains(r.tourId)) r
    ];
    if (!mounted) return;
    setState(() => _inbox = inbox);
    await _groups.markInboxSeen(inbox.length);
    ref.invalidate(platzInboxBadgeProvider);
  }

  void _startRide(SavedRouteEntry s) {
    ref.read(discoverLaunchModeProvider.notifier).state =
        DiscoverLaunchMode.mine;
    ref.read(shellTabIndexProvider.notifier).state = ShellTabs.karte;
    final catalog = catalogTourIdOf(s.id, _metas[s.id]);
    RideGroup? hit;
    for (final g in _activeGroups) {
      if (g.savedRouteId == s.id ||
          g.catalogTourId == s.id ||
          (catalog != null &&
              (g.catalogTourId == catalog || g.savedRouteId == catalog))) {
        hit = g;
        break;
      }
    }
    ref.read(ridePendingGroupIdProvider.notifier).state = hit?.id;
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
    ref.read(ridePendingGroupIdProvider.notifier).state = g.id;
    ref.read(discoverPendingStartRideRouteIdProvider.notifier).state = pending;
  }

  void _openMapToKeep() {
    ref.read(discoverLaunchModeProvider.notifier).state =
        DiscoverLaunchMode.discover;
    ref.read(shellTabIndexProvider.notifier).state = ShellTabs.karte;
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
          sourceBadge: _sourceBadge(l10n, s.source) ?? '',
          onRemoveFromMappe: () {
            Navigator.pop(ctx);
            unawaited(_removeFromMappe(s));
          },
          onGoRide: () {
            Navigator.pop(ctx);
            _startRide(s);
          },
          onCreateGroup: () {
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
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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

  String? _sourceBadge(AppLocalizations l10n, String source) {
    return mappeSourceChip(
      source,
      importLabel: l10n.myRoutesSourceImport,
      recordedLabel: l10n.myRoutesSourceRecorded,
      ownLabel: l10n.myRoutesSourceOwn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ref.listen(discoverPendingAkteRouteIdProvider, (prev, next) {
      if (next != null && next.isNotEmpty) unawaited(_consumePendingAkte());
    });
    ref.listen(savedRoutesProvider, (prev, next) {
      next.whenData((_) => unawaited(_backfillElev()));
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
    final rides = ref.watch(recentRidesProvider).valueOrNull ?? const [];
    final bikes = ref.watch(bikesProvider).valueOrNull ?? const [];
    final fix = ref.watch(locationCoreProvider).lastFix;

    String? faceAway(SavedRouteEntry s) {
      final away = mappeStartAwayKm(
        coordsLngLat: trackCoordsOf(
          coordinates: s.coordinates,
          tour: s.tour,
        ),
        userLat: fix?.lat ?? _awayLat,
        userLng: fix?.lng ?? _awayLng,
      );
      return away == null ? null : l10n.discoverPeekAwayKm(away);
    }

    String? faceCaption(SavedRouteEntry s) {
      final meta = _metas[s.id];
      final last = lastRideForSavedRoute(
        savedRouteId: s.id,
        catalogTourId: catalogTourIdOf(s.id, meta),
        rides: rides,
      );
      final bikeName = riddenWithLabel(
        preferredBikeId: last?.bikeId ?? meta?.preferredBikeId,
        bikes: bikes,
        active: null,
      );
      return joinMappeCaption([
        if (bikeName != null) l10n.discoverRiddenWith(bikeName),
        if (last != null)
          l10n.mappeLastRidden(formatMappeDay(last.endedAt ?? last.startedAt)),
      ]);
    }

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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          l10n.navPlatz,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (allSaved.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${visible.length}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (allSaved.isEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.mappeSubtitle,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.muted),
                      ),
                    ],
                    if (allSaved.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: l10n.mappeSearch,
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          hintText: l10n.mappeSearch,
                          prefixIcon: const ChromeGlyph(
                            'search',
                            size: 18,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                    if (allSaved.isNotEmpty) ...[
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
                                ref
                                    .read(tourVisibilityProvider.notifier)
                                    .state = chip.id;
                                unawaited(_reloadMeta());
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final sort in MappeSort.values)
                            FilterChip(
                              showCheckmark: false,
                              visualDensity: chipDensity,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              label: Text(
                                switch (sort) {
                                  MappeSort.recent => l10n.mappeSortRecent,
                                  MappeSort.distance => l10n.mappeSortDistance,
                                  MappeSort.name => l10n.mappeSortName,
                                },
                                style: const TextStyle(fontSize: 12),
                              ),
                              selected: _sort == sort,
                              onSelected: (_) => setState(() => _sort = sort),
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
                          icon: const ChromeGlyph('add', size: 18),
                          label: Text(l10n.mappeKeep),
                        ),
                      ),
                    ],
                    if (meet != null) ...[
                      const SizedBox(height: 14),
                      Builder(
                        builder: (context) {
                          SavedRouteEntry? meetRoute;
                          for (final s in allSaved) {
                            if (s.id == meet.savedRouteId) {
                              meetRoute = s;
                              break;
                            }
                          }
                          final coords = meetRoute == null
                              ? const <List<double>>[]
                              : trackCoordsOf(
                                  coordinates: meetRoute.coordinates,
                                  tour: meetRoute.tour,
                                );
                          return Material(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => _startRideFromMeet(meet),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (coords.length >= 2)
                                    TourLineThumb(
                                      coordinates: coords,
                                      size: 72,
                                      wide: true,
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      10,
                                      8,
                                      10,
                                    ),
                                    child: Row(
                                      children: [
                                        const MappeGlyph('meet', size: 22),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            l10n.mappeActiveMeet(
                                              meet.title,
                                              formatRideGroupWhenLine(
                                                start: meet.startWindowStart,
                                                end: meet.startWindowEnd,
                                                l10n: l10n,
                                              ),
                                            ),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: l10n.goRide,
                                          onPressed: () =>
                                              _startRideFromMeet(meet),
                                          icon: SvgPicture.asset(
                                            'assets/tours/glyph-ride.svg',
                                            width: 32,
                                            height: 32,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (savedAsync.isLoading && allSaved.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child:
                      Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              )
            else if (allSaved.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: MappeEmptyBlock(
                    title: l10n.mappeEmptyTitle,
                    hint: l10n.mappeEmpty,
                    actions: [
                      FilledButton.icon(
                        onPressed: _openMapToKeep,
                        icon: const ChromeGlyph('karte', size: 18),
                        label: Text(l10n.mappeKeepOnMap),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => unawaited(_importGpx()),
                        icon: const ChromeGlyph('download', size: 18),
                        label: Text(l10n.gpxImportAction),
                      ),
                      TextButton(
                        onPressed: () => unawaited(_addRoute()),
                        child: Text(l10n.mappeKeepName),
                      ),
                    ],
                  ),
                ),
              )
            else if (visible.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const MappeGlyph('mappe', size: 18),
                        const SizedBox(height: 8),
                        Text(
                          l10n.discoverNoSavedFilter,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            ref.read(tourVisibilityProvider.notifier).state =
                                TourVisibilityKey.allMine;
                            unawaited(_reloadMeta());
                          },
                          child: Text(l10n.mappeShowAll),
                        ),
                      ],
                    ),
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
                      caption: faceCaption(s),
                      awayLabel: faceAway(s),
                      sourceChip: _sourceBadge(l10n, s.source),
                      review: stimmenId == null
                          ? null
                          : TourCommunityReview.latestFor(_inbox, stimmenId),
                      onOpen: () => unawaited(_openAkte(s)),
                      onGoRide:
                          savedRouteHasTrack(s) ? () => _startRide(s) : null,
                    );
                  },
                  childCount: visible.length,
                ),
              ),
            SliverToBoxAdapter(
              child: MappeShelf(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PlatzFoldHeader(
                      label: l10n.stimmenTitle,
                      glyph: 'stimmen',
                      count: _inbox.length,
                      expanded: _stimmenOpen,
                      onTap: () => setState(() {
                        _stimmenOpen = !_stimmenOpen;
                      }),
                    ),
                    if (_stimmenOpen && _inbox.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                        child: Text(
                          l10n.mappeStimmenEmpty,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      )
                    else if (_stimmenOpen)
                      ..._inbox.take(8).map((r) {
                        SavedRouteEntry? hit;
                        for (final s in allSaved) {
                          if (RouteVisibility.stimmenTourIdOf(
                                s.id,
                                _metas[s.id],
                              ) ==
                              r.tourId) {
                            hit = s;
                            break;
                          }
                        }
                        final route = hit;
                        return MappeStimmeRow(
                          review: r,
                          route: route,
                          tight: true,
                          onOpen: route == null
                              ? null
                              : () => unawaited(_openAkte(route)),
                        );
                      }),
                  ],
                ),
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
            const SliverToBoxAdapter(child: SizedBox(height: 72)),
          ],
        ),
      ),
    );
  }
}
