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
import '../../domain/routing/tour_filters.dart';
import '../../domain/saved_route.dart';
import '../../domain/saved_route_note.dart';
import '../../domain/tours/add_route_start.dart';
import '../../domain/tours/route_visibility.dart';
import '../../domain/tours/tour_akte.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';
import '../discover/widgets/tour_akte_sheet.dart';
import '../shell/hof_threshold_nav.dart';
import '../shell/shell_tabs.dart';
import 'platz_extras.dart';

/// Platz-Tab: Mappe, Stimmen-Inbox, Zusammen raus. Keine zweite Datenbank.
class MappeScreen extends ConsumerStatefulWidget {
  const MappeScreen({super.key});

  @override
  ConsumerState<MappeScreen> createState() => MappeScreenState();
}

class MappeScreenState extends ConsumerState<MappeScreen> {
  final _store = TourCommunityStore();
  final _groups = RideGroupStore();
  TourVisibilityKey _visibility = TourVisibilityKey.allMine;
  Map<String, SavedRouteMeta> _metas = const {};
  List<TourCommunityReview> _inbox = const [];
  bool _akteBusy = false;
  bool _stimmenOpen = false;
  bool _stimmenToggled = false;

  @override
  void initState() {
    super.initState();
    TourCommunityStore.revision.addListener(_onCommunity);
    unawaited(_reloadMeta());
    unawaited(_reloadInbox());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_consumePendingAkte());
    });
  }

  @override
  void dispose() {
    TourCommunityStore.revision.removeListener(_onCommunity);
    super.dispose();
  }

  void _onCommunity() => unawaited(_reloadInbox());

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
    setState(() {
      _inbox = inbox;
      if (!_stimmenToggled) {
        _stimmenOpen = inbox.isNotEmpty;
      }
    });
    await _groups.markInboxSeen(inbox.length);
    ref.invalidate(platzInboxBadgeProvider);
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
                loc.discoverAddRoute,
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
    final visible = RouteVisibility.filter(allSaved, _visibility, _metas);
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
                    const SizedBox(height: 22),
                    _PlatzSectionLabel(l10n.mappeTitle),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
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
                            selected: _visibility == chip.id,
                            onSelected: (_) {
                              setState(() => _visibility = chip.id);
                              unawaited(_reloadMeta());
                            },
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
                        label: Text(l10n.discoverAddRoute),
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
                    final shared = RouteVisibility.isShared(_metas[s.id]);
                    final vis = shared ? l10n.discoverShared : l10n.discoverPrivate;
                    final meta = s.coordinates.length < 2
                        ? vis
                        : '${s.distanceKm.toStringAsFixed(1)} km · $vis';
                    return ListTile(
                      key: Key('platz-tour-${s.id}'),
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
                        s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        meta,
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
                      onTap: () => unawaited(_openAkte(s)),
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
                    _stimmenToggled = true;
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
                        r.body,
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
                saved: allSaved,
                metas: _metas,
                store: _groups,
                visibility: _visibility,
                onOpenAkte: (s) => unawaited(_openAkte(s)),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }
}

class _PlatzSectionLabel extends StatelessWidget {
  const _PlatzSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
        color: AppColors.muted,
      ),
    );
  }
}
