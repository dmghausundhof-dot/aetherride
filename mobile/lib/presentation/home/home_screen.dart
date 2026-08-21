import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/location/safe_position.dart';
import '../../data/community/listings_client.dart';
import '../../data/community/ride_group_store.dart';
import '../../data/community/tour_community_store.dart';
import '../../data/routing/coverage_label.dart';
import '../../data/routing/map_style_url.dart';
import '../../data/routing/naehe_seeds.dart';
import '../../data/routing/offline_pack_catalog.dart';
import '../../data/routing/offline_pack_catalog_client.dart';
import '../../data/routing/offline_pack_dirs.dart';
import '../../data/routing/offline_maps_prefs.dart';
import '../../data/routing/overlay_regions.dart';
import '../../domain/home/hof_pack.dart';

import '../../data/weather/weather_client.dart';
import '../../data/routing/routing_client.dart';
import '../../domain/active_route.dart';
import '../../domain/bike.dart';
import '../../domain/component.dart';
import '../../domain/garage/die_box.dart';
import '../../domain/home/greeting.dart';
import '../../domain/home/hof_gate.dart';

import '../../domain/home/hof_stand.dart';
import '../../domain/maintenance/intervals.dart';
import '../../domain/routing/duration_lens.dart';
import '../../domain/routing/tour_nav_geometry.dart';
import '../../domain/tours/route_visibility.dart';
import '../../domain/tours/tour_akte.dart';
import '../../domain/tours/tour_display_name.dart';
import '../../domain/tours/tour_listing.dart';
import '../../data/community/tour_share_revoke.dart';
import '../../data/routing/saved_route_meta_store.dart';
import '../../domain/saved_route_note.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';
import '../auth/auth_screen.dart';
import '../discover/offline_maps_sheet.dart';

import '../../domain/ride.dart';
import '../../domain/ride/ride_telemetry.dart';
import '../post_ride/post_ride_screen.dart';
import '../profile/profile_screen.dart';
import '../ride/ride_elev_sparkline.dart';
import '../garage/rad_stand_frame.dart';
import '../shared/bike_hero_banner.dart';
import '../shared/weather_glyph.dart';
import '../shell/shell_tabs.dart';
import 'hof_coach_banner.dart';
import 'hof_watch_card.dart';
import 'hof_watch_bar_button.dart';

/// Start — Status und Losfahren. Intern weiter `hof`.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  WeatherSnapshot? _weather;
  bool _weatherResolved = false;
  bool _weatherOffline = false;
  double? _lat;
  double? _lng;
  NaeheSeedsBundle? _seeds;
  HofGatePick _gate = const HofGatePick();
  int _gateMinutes = 60;
  TourCommunityCounts? _neighbors;
  String? _tafelStimmenText;
  String? _tafelStimmenRouteId;
  String? _tafelGroupText;
  String? _tafelListingText;
  String? _tafelListingRouteId;
  HofPackHint? _packHint;

  @override
  void initState() {
    super.initState();
    TourCommunityStore.revision.addListener(_onCommunityRevision);
    RideGroupStore.revision.addListener(_onGroupRevision);
    OfflineMapsPrefs.revision.addListener(_onPackRevision);
    unawaited(_bootHof());
  }

  @override
  void dispose() {
    TourCommunityStore.revision.removeListener(_onCommunityRevision);
    RideGroupStore.revision.removeListener(_onGroupRevision);
    OfflineMapsPrefs.revision.removeListener(_onPackRevision);
    super.dispose();
  }

  void _onPackRevision() => unawaited(_refreshPackHint());

  void _onGroupRevision() => unawaited(_loadTafelGroup());

  void _onCommunityRevision() {
    if (!mounted) return;
    final id = _gate.seed?.id;
    if (id != null) unawaited(_loadNeighbors(id));
    unawaited(_loadTafelStimmen());
    unawaited(_tickListings());
  }

  Future<void> _bootHof() async {
    unawaited(prefetchMapStyleJson(AppConfig.browseMapStyleUrl));
    unawaited(prefetchMapStyleJson(AppConfig.mapStyleUrl));
    final gate = _loadGate();
    await _loadPosition();
    if (!mounted) return;
    await Future.wait([_loadWeather(), gate]);
    if (mounted) {
      unawaited(_loadTafelStimmen());
      unawaited(_loadTafelGroup());
      unawaited(_tickListings());
    }
  }

  Future<void> _loadTafelStimmen() async {
    final saved = ref.read(savedRoutesProvider).valueOrNull ?? const [];
    if (saved.isEmpty) {
      if (mounted) {
        setState(() {
          _tafelStimmenText = null;
          _tafelStimmenRouteId = null;
        });
      }
      return;
    }
    final metas = await SavedRouteMetaStore.listAll();
    final store = TourCommunityStore();
    String? text;
    String? routeId;
    for (final r in saved) {
      final meta = metas[r.id] ?? SavedRouteMeta.empty;
      final stimmenId = RouteVisibility.stimmenTourIdOf(r.id, meta);
      if (stimmenId == null) continue;
      try {
        final local = await store.reviewsForTour(stimmenId);
        await store.mergeCloudBundle(stimmenId);
        final cloud = TourCommunityStore.countsCache[stimmenId];
        final cloudN = cloud?.reviewCount ?? 0;
        final n = local.length > cloudN ? local.length : cloudN;
        if (n <= 0) continue;
        if (!mounted) return;
        final loc = AppLocalizations.of(context);
        text = n == 1
            ? loc.hofTafelVoiceOne(r.name)
            : loc.hofTafelVoices(n, r.name);
        routeId = r.id;
        break;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _tafelStimmenText = text;
      _tafelStimmenRouteId = routeId;
    });
  }

  Future<void> _loadTafelGroup() async {
    final groups = await RideGroupStore().activeGroups();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _tafelGroupText =
          groups.isEmpty ? null : l10n.hofTafelGroup(groups.first.title);
    });
  }

  Future<void> _tickListings() async {
    final saved = ref.read(savedRoutesProvider).valueOrNull ?? const [];
    if (saved.isEmpty) {
      if (mounted) {
        setState(() {
          _tafelListingText = null;
          _tafelListingRouteId = null;
        });
      }
      return;
    }
    final metas = await SavedRouteMetaStore.listAll();
    final store = TourCommunityStore();
    final own = <ListingTafelOwn>[];
    String? listingRouteId;
    for (final r in saved) {
      final meta = metas[r.id] ?? SavedRouteMeta.empty;
      if (meta.visibility != 'shared' &&
          meta.listing != 'candidate' &&
          meta.listing != 'listed' &&
          meta.listing != 'reverted') {
        continue;
      }
      final catalog = catalogTourIdOf(r.id, meta);
      final stimmenId = RouteVisibility.stimmenTourIdOf(r.id, meta);
      var reviews = const <TourCommunityReview>[];
      if (stimmenId != null) {
        try {
          reviews = await store.reviewsForTour(stimmenId);
          await store.mergeCloudBundle(stimmenId);
          reviews = await store.reviewsForTour(stimmenId);
        } catch (_) {}
      }
      final confirms = confirmationsFromReviews([
        for (final v in reviews)
          (
            authorLabel: v.authorLabel,
            authorId: null,
            createdAt: v.createdAt,
            status: switch (v.cloudStatus) {
              CloudSubmitResult.pending => 'pending',
              CloudSubmitResult.rejected => 'rejected',
              _ => 'approved',
            },
            editorial: false,
          ),
      ]);
      final ticked = tickSavedMeta(
        meta: meta,
        isCatalog: catalog != null,
        confirmations: confirms,
      );
      if (ticked.decision.changed) {
        await SavedRouteMetaStore.put(r.id, ticked.meta);
        if (ticked.decision.notice == ListingNotice.reverted &&
            ticked.decision.shareEpoch > meta.shareEpoch) {
          unawaited(
            revokeTourShareOnServer(
              routeId: r.id,
              epoch: ticked.meta.shareEpoch,
            ),
          );
        }
      }
      own.add(
        ListingTafelOwn(
          name: r.name,
          notice: ticked.decision.notice,
          confirmCount: ticked.decision.confirmCount,
          candidateSince: ticked.decision.candidateSince,
        ),
      );
      if (ticked.decision.notice != ListingNotice.none) {
        listingRouteId = r.id;
      }
    }
    var nearbyWaiting = 0;
    final lat = _lat;
    final lng = _lng;
    if (lat != null && lng != null) {
      try {
        final hit = await NearbyListingsClient().fetchViewport(
          west: lng - 0.2,
          south: lat - 0.2,
          east: lng + 0.2,
          north: lat + 0.2,
        );
        nearbyWaiting = hit.nearbyWaiting;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _tafelListingText = pickListingTafel(
        own: own,
        nearbyWaiting: nearbyWaiting,
      );
      _tafelListingRouteId = listingRouteId;
    });
  }

  Future<void> _loadPosition({bool prompt = false}) async {
    try {
      var perm = await Geolocator.checkPermission();
      if (prompt && perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (prompt &&
          (perm == LocationPermission.denied ||
              perm == LocationPermission.deniedForever)) {
        await Geolocator.openAppSettings();
        perm = await Geolocator.checkPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      // Boot: nur lastKnown. getCurrentPosition auf dem ersten Frame
      // kann auf dem Emulator ANR (NmeaListener auf dem UI-Thread).
      var pos = await readCachedPosition(maxAge: const Duration(minutes: 15));
      if (pos == null && prompt) {
        pos = await readFreshPosition();
      }
      if (pos != null && mounted) {
        setState(() {
          _lat = pos!.latitude;
          _lng = pos.longitude;
        });
        unawaited(_refreshPackHint());
        if (prompt) {
          await _loadWeather();
          if (mounted && _seeds != null) _recomputeGate();
        }
      }
    } catch (_) {}
  }

  Future<void> _loadWeather() async {
    final lat = _lat;
    final lng = _lng;
    if (lat == null || lng == null) {
      if (mounted) {
        setState(() {
          _weatherResolved = true;
          _weatherOffline = false;
        });
      }
      return;
    }
    try {
      final bikes = ref.read(bikesProvider).valueOrNull ?? [];
      final active = hofResidentBike(bikes);
      final profile = active != null
          ? routingProfileForBike(active.category).apiId
          : null;
      final w = await ref.read(weatherClientProvider).fetch(
            lat: lat,
            lon: lng,
            profile: profile,
            lang: Localizations.localeOf(context).languageCode,
          );
      if (mounted) {
        setState(() {
          if (w != null) {
            _weather = w;
            _weatherOffline = false;
          } else {
            _weatherOffline = _weather == null;
          }
          _weatherResolved = true;
        });
        if (_seeds != null) _recomputeGate();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _weatherOffline = _weather == null;
          _weatherResolved = true;
        });
      }
    }
  }

  Future<void> _loadGate() async {
    try {
      final bundle = await NaeheSeedsBundle.load();
      if (!mounted) return;
      setState(() => _seeds = bundle);
      _recomputeGate();
    } catch (_) {
      if (mounted) {
        setState(() => _seeds = const NaeheSeedsBundle(
              routes: [],
              labelWithoutLocation: '',
              labelWithLocation: '',
              defaultCenterLat: 0,
              defaultCenterLng: 0,
            ));
        _recomputeGate();
      }
    }
  }

  void _recomputeGate() {
    final bundle = _seeds;
    if (bundle == null) return;
    final saved = ref.read(savedRoutesProvider).valueOrNull ?? [];
    final wet = _weather?.trailHint == 'wet_likely';
    final bikes = ref.read(bikesProvider).valueOrNull ?? [];
    final active = hofResidentBike(bikes);
    final store = ref.read(userProfileStoreProvider);
    final pick = pickHofGate(
      loops: bundle.loops,
      saved: saved,
      lat: _lat,
      lng: _lng,
      trailsWet: wet,
      targetMin: _gateMinutes,
      preferred: active?.category ?? store.preferredSport,
      preferredSports: active != null ? const [] : store.preferredSports,
    );
    setState(() => _gate = pick);
    final id = pick.seed?.id;
    if (id != null) unawaited(_loadNeighbors(id));
  }

  Future<void> _loadNeighbors(String tourId) async {
    final cached = TourCommunityStore.countsCache[tourId];
    if (cached != null && cached.hasCommunity && mounted) {
      setState(() => _neighbors = cached);
    }
    try {
      final store = TourCommunityStore();
      final local = await store.reviewsForTour(tourId);
      await store.mergeCloudBundle(tourId);
      final fromCloud = TourCommunityStore.countsCache[tourId];
      final count = (fromCloud?.reviewCount ?? 0) > local.length
          ? fromCloud!.reviewCount
          : local.length;
      final photos = fromCloud?.photoCount ?? 0;
      final next = TourCommunityCounts(
        reviewCount: count,
        photoCount: photos,
      );
      if (!mounted) return;
      setState(() => _neighbors = next.hasCommunity ? next : null);
    } catch (_) {}
  }

  Future<void> _openSystemStatusSheet(
    BuildContext context, {
    required bool showSupabaseWarning,
    required bool showSyncWarning,
    required SyncAuthStatus syncStatus,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              0,
              AppSpacing.l,
              AppSpacing.l,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  loc.hofSystemStatus,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 17),
                ),
                const SizedBox(height: AppSpacing.m),
                if (!showSupabaseWarning && !showSyncWarning)
                  Text(
                    loc.hofSystemOk,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                if (showSupabaseWarning) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.settings_outlined),
                    title: Text(
                      loc.hofSupabaseMissing,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(loc.hofSupabaseMissingHint),
                  ),
                  const SizedBox(height: AppSpacing.s),
                ],
                if (showSyncWarning)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cloud_off_outlined),
                    title: Text(
                      syncStatus == SyncAuthStatus.unauthorized
                          ? loc.hofSyncSessionExpired
                          : loc.hofSyncLoginOnly,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(loc.hofSyncLocalHint),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (syncStatus == SyncAuthStatus.unauthorized)
                          TextButton(
                            onPressed: () {
                              unawaited(ref.read(syncEngineProvider).syncNow());
                              Navigator.pop(ctx);
                            },
                            child: Text(loc.retry),
                          ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            openAuthScreen(context);
                          },
                          child: Text(loc.signIn),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openGarage({String? bikeId, bool addBike = false}) {
    if (addBike) {
      ref.read(garageOpenAddPendingProvider.notifier).state = true;
    } else if (bikeId != null) {
      ref.read(garagePendingBikeIdProvider.notifier).state = bikeId;
    }
    ref.read(shellTabIndexProvider.notifier).state = ShellTabs.werkstatt;
  }

  void _openMappe({String? akteRouteId}) {
    if (akteRouteId != null && akteRouteId.isNotEmpty) {
      ref.read(discoverPendingAkteRouteIdProvider.notifier).state = akteRouteId;
    }
    ref.read(shellTabIndexProvider.notifier).state = ShellTabs.platz;
  }

  void _startRide() {
    final done = ref.read(onboardingDoneProvider);
    if (done == false) return;
    ref.read(ridePendingGroupIdProvider.notifier).state = null;
    ref.read(rideAutostartProvider.notifier).state = true;
    ref.read(shellTabIndexProvider.notifier).state = ShellTabs.ride;
  }

  Future<void> _openPostRide(String rideId) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => PostRideScreen(rideId: rideId),
      ),
    );
    if (!mounted) return;
    if (result != null && result.startsWith('akte:')) {
      final routeId = result.substring(5);
      _openMappe(akteRouteId: routeId.isEmpty ? null : routeId);
    }
  }

  void _openKarte() {
    ref.read(shellTabIndexProvider.notifier).state = ShellTabs.karte;
  }

  void _openGate() {
    final gate = _gate;
    if (gate.seed != null) {
      final lens = DurationLens.nearestHofGateMinutes(
        gate.durationMin > 0 ? gate.durationMin : _gateMinutes,
      );
      ref.read(discoverPendingLoopIdProvider.notifier).state = gate.seed!.id;
      ref.read(discoverPendingLensMinutesProvider.notifier).state = lens;
      _openKarte();
      return;
    }
    if (gate.saved != null) {
      final r = gate.saved!;
      if (r.coordinates.length >= 2) {
        ref.read(activeRouteProvider.notifier).state = ActiveRoute(
          id: r.id,
          name: r.name,
          distanceKm: r.distanceKm,
          elevationM: r.elevationM,
          durationMin: r.durationMin,
          coordinates: r.coordinates,
          isLoop: navGeometryIsLoop(r.coordinates),
        );
        ref.read(ridePendingGroupIdProvider.notifier).state = null;
        ref.read(rideAutostartProvider.notifier).state = true;
        ref.read(shellTabIndexProvider.notifier).state = ShellTabs.ride;
        return;
      }
    }
    _openKarte();
  }

  Future<void> _refreshPackHint() async {
    final lat = _lat;
    final lng = _lng;
    if (lat == null || lng == null) {
      if (mounted && _packHint != null) setState(() => _packHint = null);
      return;
    }
    final l10n = AppLocalizations.of(context);
    final region = overlayRegionForPoint(lng, lat);
    final ready = await OfflinePackDirs.legitimateCoversPoint(lng, lat);
    if (!mounted) return;
    String? suggestedId;
    String? suggestedName;
    String? readyId;
    String? readyName;
    final overlayIsEnvelope = region != null && isEnvelopePackId(region.id);
    if (ready) {
      try {
        final m = await OfflineMapsPrefs.read();
        readyId = OfflineMapsPrefs.packIdFromActivatedPath(
          m['activatedPackPath'] as String?,
        );
        final raw = (m['regionPack'] as String?)?.trim();
        if (readyId != null && readyId.isNotEmpty) {
          readyName = l10n.overlayRegionNameFor(readyId, raw);
        } else if (raw != null && raw.isNotEmpty) {
          readyId = raw;
          readyName = raw;
        }
      } catch (_) {}
      if (!mounted) return;
    } else {
      try {
        final packs = await loadOfflinePackCatalog();
        final sug = suggestedPackForPoint(packs: packs, lng: lng, lat: lat);
        suggestedId = sug?.id;
        suggestedName =
            sug == null ? null : l10n.overlayRegionNameFor(sug.id, sug.name);
      } catch (_) {}
      if (!mounted) return;
    }
    final hint = hofHintForLocation(
      overlayId: region?.id,
      overlayName: region == null
          ? null
          : l10n.overlayRegionNameFor(region.id, region.name),
      overlayIsEnvelope: overlayIsEnvelope,
      suggestedId: suggestedId,
      suggestedName: suggestedName,
      packReady: ready,
      readyId: readyId,
      readyName: readyName,
    );
    if (hint?.regionId == _packHint?.regionId &&
        hint?.ready == _packHint?.ready) {
      return;
    }
    setState(() => _packHint = hint);
  }

  Future<void> _openOfflineMaps() async {
    var paused = false;
    await openOfflineMapsSheet(
      context,
      userLng: _lng,
      userLat: _lat,
      focusPackId: _packHint?.regionId,
      onDownloadPaused: () => paused = true,
    );
    if (!mounted) return;
    if (paused) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context).offlineDownloadPaused)),
      );
    }
    await _refreshPackHint();
  }

  String _skyLine(AppLocalizations l10n) {
    if (!_weatherResolved) return '';
    if (_lat == null) return '';
    final w = _weather;
    if (w != null) {
      final temp = w.tempC.round().toString();
      return switch (w.trailHint) {
        'wet_likely' => l10n.hofSkyWet(temp),
        'damp_possible' => l10n.hofSkyDamp(temp),
        _ => l10n.hofSkyDry(temp),
      };
    }
    if (_weatherOffline) return l10n.hofSkyNeedNet;
    return '';
  }

  String _hofTitle(BuildContext context) {
    return AppLocalizations.of(context).navHome;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ref.listen(savedRoutesProvider, (prev, next) {
      if (next.hasValue && _seeds != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _recomputeGate();
        });
      }
      if (next.hasValue) {
        unawaited(_loadTafelStimmen());
      }
    });
    ref.listen(bikesProvider, (prev, next) {
      if (_seeds != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _recomputeGate();
        });
      }
      final prevCat =
          hofResidentBike(prev?.valueOrNull ?? const <Bike>[])?.category;
      final nextCat =
          hofResidentBike(next.valueOrNull ?? const <Bike>[])?.category;
      if (prevCat != nextCat) unawaited(_loadWeather());
    });
    ref.listen(shellTabIndexProvider, (prev, next) {
      if (next == ShellTabs.hof) unawaited(_refreshPackHint());
    });
    final bikes = ref.watch(bikesProvider);
    final session = ref.watch(authSessionProvider).valueOrNull;
    final store = ref.watch(userProfileStoreProvider);
    final syncStatus = ref.watch(syncAuthStatusProvider);
    final rides = ref.watch(recentRidesProvider).valueOrNull ?? [];
    final showSupabaseWarning = kDebugMode && !AppConfig.isSupabaseConfigured;
    final showSyncWarning = AppConfig.isSupabaseConfigured &&
        (syncStatus == SyncAuthStatus.noAuth ||
            syncStatus == SyncAuthStatus.unauthorized);

    final list = bikes.valueOrNull;
    final Bike? active = list == null ? null : hofResidentBike(list);
    final others = active == null
        ? const <Bike>[]
        : hofStandOthers(active: active, all: list ?? const <Bike>[]);

    final displayName = store.displayName;
    final initials = avatarInitials(
      displayName: displayName,
      email: session?.user.email,
    );
    final photo = store.profilePhotoPath;

    RideReturn? ret;
    if (active != null) {
      ret = rideReturnForBike(bikeId: active.id, rides: rides);
    }
    final justBack = ret?.hidesGate == true;
    final bleAwake = ref.read(bleCoreProvider).hasBikeLiveMetrics;

    final sky = _skyLine(l10n);
    final title = _hofTitle(context);
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final shortLandscape = landscape && MediaQuery.sizeOf(context).height < 560;

    final header = Row(
      children: [
        Expanded(
          child: Text(
            title,
            key: const Key('hof-title'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.chrome,
                  fontSize: landscape ? 22 : null,
                ),
          ),
        ),
        const HofWatchBarButton(),
        HofCoachBellButton(
          stimmenText: _tafelStimmenText,
          groupText: _tafelGroupText,
          listingText: _tafelListingText,
          onOpenCare: () {
            final id = active?.id;
            if (id != null) _openGarage(bikeId: id);
          },
          onOpenTours: _openMappe,
        ),
        const HofChatButton(),
        if (showSupabaseWarning) ...[
          const SizedBox(width: AppSpacing.xs),
          _SystemStatusIcon(
            hasNotice: true,
            onTap: () => _openSystemStatusSheet(
              context,
              showSupabaseWarning: showSupabaseWarning,
              showSyncWarning: showSyncWarning,
              syncStatus: syncStatus,
            ),
          ),
        ],
        const SizedBox(width: AppSpacing.xs),
        IconButton(
          tooltip: l10n.profile,
          onPressed: () async {
            await openProfileScreen(context);
            if (mounted) unawaited(_refreshPackHint());
          },
          icon: _HofProfileAvatar(
            initials: initials,
            photo: photo,
            signedIn: session != null,
          ),
        ),
        const SizedBox(width: AppSpacing.s),
      ],
    );

    final wetSky = _weather?.trailHint == 'wet_likely';
    final skyBand = Color.alphaBlend(
      AppColors.sage.withValues(alpha: wetSky ? 0.40 : 0.30),
      AppColors.hofGround,
    );
    final yard = Color.alphaBlend(
      AppColors.sage.withValues(alpha: wetSky ? 0.16 : 0.10),
      AppColors.hofGround,
    );
    final skyLine = sky.isEmpty
        ? null
        : Row(
            key: const Key('hof-sky'),
            children: [
              WeatherGlyph(
                _weather?.trailHint,
                offline: _weatherOffline,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sky,
                  style: const TextStyle(
                    color: AppColors.sageOnDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          );

    final gpsHonesty = (_weatherResolved && _lat == null)
        ? Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s),
            child: InkWell(
              key: const Key('hof-gps-honesty'),
              onTap: () => unawaited(_loadPosition(prompt: true)),
              child: Text(
                l10n.hofAllowLocation,
                style: const TextStyle(
                  color: AppColors.chrome,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
        : null;

    final resident = bikes.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text(l10n.errorPrefix('$e')),
      data: (_) {
        if (active == null) {
          return _EmptyStand(l10n: l10n, compact: landscape);
        }
        final comps =
            ref.watch(bikeComponentsProvider(active.id)).valueOrNull ??
                const <BikeComponent>[];
        final hasMotor = comps.any((c) => c.slot == ComponentSlot.motor);
        final lastId = ret?.rideId;
        RideRecord? lastRide;
        if (lastId != null && lastId.isNotEmpty) {
          for (final r in rides) {
            if (r.id == lastId) {
              lastRide = r;
              break;
            }
          }
        }
        final due = listDueMaintenance(
          bike: active,
          components: comps,
          logs: store.maintenanceLogs,
        );
        final plan = planDieBox(
          bike: active,
          components: comps,
          due: due,
          logs: store.maintenanceLogs,
        );
        final health = bikeHealthLine(
          readiness: plan.readiness,
          odometerKm: active.odometerKm,
          readyLabel: l10n.dieBoxReady,
          almostLabel: l10n.dieBoxAlmost,
          unknownLabel: l10n.dieBoxUnknown,
        );
        return Semantics(
          container: true,
          explicitChildNodes: true,
          child: _Resident(
            bike: active,
            others: others,
            ret: ret!,
            lastRide: lastRide,
            healthLine: health,
            l10n: l10n,
            sport: l10n.hofResidentSportLabel(active, hasMotor: hasMotor),
            bleAwake: bleAwake,
            photoHeight: shortLandscape ? 72 : (landscape ? 96 : 112),
            photos: store.bikePhotos,
            onOpenBike: () => _openGarage(bikeId: active!.id),
            onBringForward: (id) async {
              await ref.read(garageRepositoryProvider).setActiveBike(id);
              ref.invalidate(bikesProvider);
            },
            onLastRide: (lastId != null && lastId.isNotEmpty)
                ? () => _openPostRide(lastId)
                : null,
          ),
        );
      },
    );

    final savedCount = ref.watch(savedRoutesProvider).valueOrNull?.length ?? 0;

    Widget tafelLine(HofTafelItem item, {required bool overdue}) {
      return _TafelLine(
        key: Key(
          item.kind == HofTafelKind.care
              ? 'hof-tafel-care'
              : 'hof-tafel-${item.id}',
        ),
        label: item.text,
        color: item.kind == HofTafelKind.care && overdue
            ? AppColors.error
            : AppColors.chipIdleText,
        onTap: item.kind == HofTafelKind.care
            ? () {
                final id = active?.id;
                if (id != null) _openGarage(bikeId: id);
              }
            : () => _openMappe(
                  akteRouteId: item.kind == HofTafelKind.stimmen
                      ? _tafelStimmenRouteId
                      : item.kind == HofTafelKind.listing
                          ? _tafelListingRouteId
                          : null,
                ),
      );
    }

    Widget tourColumn(String? careText, {bool overdue = false}) {
      final lines = buildHofTafel(
        careText: careText,
        listingText: _tafelListingText,
        stimmenText: _tafelStimmenText,
        groupText: _tafelGroupText,
        savedCount: savedCount,
      );
      if (lines.isEmpty) return const SizedBox.shrink();
      final careLines =
          lines.where((e) => e.kind == HofTafelKind.care).toList();
      final tourLines =
          lines.where((e) => e.kind != HofTafelKind.care).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (careLines.isNotEmpty)
            _TafelBoard(
              key: const Key('hof-tafel-workshop'),
              kicker: l10n.navWorkshop,
              children: [
                for (final item in careLines) tafelLine(item, overdue: overdue),
              ],
            ),
          if (careLines.isNotEmpty && tourLines.isNotEmpty)
            const SizedBox(height: AppSpacing.s),
          if (tourLines.isNotEmpty)
            _TafelBoard(
              key: const Key('hof-tafel-board'),
              kicker: l10n.navPlatz,
              children: [
                for (final item in tourLines) tafelLine(item, overdue: false),
              ],
            ),
        ],
      );
    }

    final Bike? residentForTafel = active;
    late final Widget tafelBody;
    if (residentForTafel == null) {
      tafelBody = tourColumn(null);
    } else {
      final bike = residentForTafel;
      tafelBody = Consumer(
        builder: (context, ref, _) {
          final compsAsync = ref.watch(bikeComponentsProvider(bike.id));
          final setup = ref.watch(currentSetupProvider(bike.id)).valueOrNull;
          final setups =
              ref.watch(setupsForBikeProvider(bike.id)).valueOrNull ??
                  (setup != null ? [setup] : const []);
          final logs = ref.watch(userProfileStoreProvider).maintenanceLogs;
          return compsAsync.when(
            data: (comps) {
              final due = listDueMaintenance(
                bike: bike,
                components: comps,
                logs: logs,
              );
              final plan = planDieBox(
                bike: bike,
                components: comps,
                currentSetup: setup,
                setups: setups,
                due: due,
                logs: logs,
              );
              final item = tafelCareItem(plan);
              final care = item == null ? null : l10n.localizeDieBoxItem(item);
              return tourColumn(
                care == null ? null : l10n.hofCareInWorkshop(care.title),
                overdue: care?.due?.status == DueStatus.overdue,
              );
            },
            loading: () => tourColumn(null),
            error: (_, __) => tourColumn(null),
          );
        },
      );
    }
    final tafel = Semantics(
      container: true,
      explicitChildNodes: true,
      child: tafelBody,
    );

    final gate = (!justBack)
        ? _GateCard(
            l10n: l10n,
            pick: _gate,
            neighbors: _neighbors,
            minutes: _gateMinutes,
            onMinutes: (m) {
              setState(() => _gateMinutes = m);
              _recomputeGate();
            },
            onTap: _openGate,
          )
        : null;
    final packHint = _packHint;
    final packLine = packHint == null
        ? null
        : packHint.ready
            ? Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  key: const Key('hof-offline-ready'),
                  onTap: () => unawaited(_openOfflineMaps()),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: AppColors.sageOnDark,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.hofPackReadyRideMap(
                              coverageGlanceName(packHint.regionName),
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.3,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Align(
                alignment: Alignment.centerLeft,
                child: ActionChip(
                  key: const Key('hof-load-offline-map'),
                  avatar: const Icon(Icons.download_outlined, size: 18),
                  label: Text(
                    l10n.hofLoadOfflineMap(
                      coverageGlanceName(packHint.regionName),
                    ),
                  ),
                  backgroundColor: AppColors.sage.withValues(alpha: 0.22),
                  side: const BorderSide(color: AppColors.sageOnDark),
                  onPressed: () => unawaited(_openOfflineMaps()),
                ),
              );

    final ctaHeight = shortLandscape ? 44.0 : 52.0;
    final emptyStand = active == null;
    final cta = FilledButton(
      key: const Key('hof-ride-out'),
      style: emptyStand
          ? AppTheme.parkCta(height: ctaHeight)
          : AppTheme.rideOutCta(height: ctaHeight),
      onPressed: emptyStand ? () => _openGarage(addBike: true) : _startRide,
      child: Text(
        emptyStand
            ? l10n.hofParkBike
            : (justBack ? l10n.hofRideOutAgain : l10n.hofRideOut),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );

    final secondary = Center(
      child: TextButton(
        onPressed:
            emptyStand ? _startRide : () => _openGarage(bikeId: active!.id),
        child: Text(
          emptyStand ? l10n.hofRideWithoutBike : l10n.hofOpenBike,
        ),
      ),
    );
    final groupHint = emptyStand
        ? null
        : Text(
            l10n.hofRideGroupHint,
            key: const Key('hof-ride-group-hint'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          );

    if (landscape) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final short = constraints.maxHeight < 520;
                final watch = HofWatchCard(dense: short);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    if (!short && skyLine != null) ...[
                      const SizedBox(height: AppSpacing.s),
                      skyLine,
                    ],
                    if (!short && gpsHonesty != null) gpsHonesty,
                    const SizedBox(height: AppSpacing.s),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  resident,
                                  tafel,
                                  if (short && skyLine != null) ...[
                                    const SizedBox(height: AppSpacing.s),
                                    skyLine,
                                  ],
                                  if (short && gpsHonesty != null) gpsHonesty,
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.m),
                          Expanded(
                            flex: 4,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  cta,
                                  const SizedBox(height: AppSpacing.s),
                                  secondary,
                                  if (groupHint != null) ...[
                                    const SizedBox(height: 4),
                                    groupHint,
                                  ],
                                  if (gate != null) ...[
                                    const SizedBox(height: AppSpacing.s),
                                    gate,
                                  ],
                                  if (packLine != null) packLine,
                                  const SizedBox(height: AppSpacing.s),
                                  watch,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: yard,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  ColoredBox(
                    color: skyBand,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          header,
                          if (skyLine != null) ...[
                            const SizedBox(height: AppSpacing.s),
                            skyLine,
                          ],
                          if (gpsHonesty != null) gpsHonesty,
                          const SizedBox(height: AppSpacing.l),
                          resident,
                          if (gate != null) ...[
                            const SizedBox(height: AppSpacing.m),
                            gate,
                          ],
                          if (packLine != null) packLine,
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        tafel,
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  cta,
                  const SizedBox(height: AppSpacing.s),
                  secondary,
                  if (groupHint != null) ...[
                    const SizedBox(height: 4),
                    groupHint,
                  ],
                  const HofWatchCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Eine Tafel als Brett — nicht als lose graue Zeilen auf Kohle.
class _TafelBoard extends StatelessWidget {
  const _TafelBoard({
    super.key,
    required this.kicker,
    this.hint,
    required this.children,
  });

  final String kicker;
  final String? hint;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        AppSpacing.m,
        AppSpacing.m,
        AppSpacing.s,
      ),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kicker,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: AppColors.muted,
            ),
          ),
          if (hint != null && hint!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 2),
              child: Text(
                hint!,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.muted,
                ),
              ),
            ),
          ...children,
        ],
      ),
    );
  }
}

/// Eine Tafel-Zeile: eigener Semantics-Knoten, vollbreite Hit-Fläche.
class _TafelLine extends StatelessWidget {
  const _TafelLine({
    super.key,
    required this.label,
    required this.onTap,
    this.kicker,
    this.icon,
    this.color = AppColors.chipIdleText,
  });

  final String label;
  final VoidCallback onTap;
  final String? kicker;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (kicker != null)
          Text(
            kicker!,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: AppColors.muted,
            ),
          ),
        if (kicker != null) const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
    return Semantics(
      button: true,
      label: [
        if (kicker != null) kicker,
        label.replaceAll('\n', ', '),
      ].join(', '),
      excludeSemantics: true,
      container: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: double.infinity,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.s,
                  bottom: AppSpacing.s,
                ),
                child: icon == null
                    ? body
                    : Row(
                        children: [
                          Icon(icon, size: 20, color: color),
                          const SizedBox(width: 10),
                          Expanded(child: body),
                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: color.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Resident extends StatelessWidget {
  const _Resident({
    required this.bike,
    required this.others,
    required this.ret,
    this.lastRide,
    this.healthLine,
    required this.l10n,
    required this.sport,
    required this.bleAwake,
    required this.onOpenBike,
    required this.onBringForward,
    this.onLastRide,
    this.photoHeight = 188,
    this.photos = const {},
  });

  final Bike bike;
  final List<Bike> others;
  final RideReturn ret;
  final RideRecord? lastRide;
  final String? healthLine;
  final AppLocalizations l10n;
  final String sport;
  final bool bleAwake;
  final VoidCallback onOpenBike;
  final Future<void> Function(String id) onBringForward;
  final VoidCallback? onLastRide;
  final double photoHeight;
  final Map<String, String> photos;

  @override
  Widget build(BuildContext context) {
    final meta = formatHofResidentMeta(
      ret: ret,
      sport: sport,
      garageTypeLabel: l10n.hofGarageType(sport),
      justBackLabel: l10n.hofJustBack,
      atHofLabel: l10n.hofAtHof,
      notYetOutLabel: l10n.hofNotYetOut,
      sinceOneDay: l10n.hofSinceOneDay,
      sinceDays: l10n.hofSinceDays,
      noGpsLabel: l10n.hofLastRideNoGps,
      ago: hofAgoLabel(
        endedAt: ret.endedAt,
        now: DateTime.now(),
        minutes: l10n.hofAgoMinutes,
        hours: l10n.hofAgoHours,
      ),
    );

    final metaStyle = TextStyle(
      color: onLastRide != null ? AppColors.chrome : AppColors.muted,
      fontSize: 13,
      fontWeight: onLastRide != null ? FontWeight.w600 : FontWeight.w400,
    );

    Widget metaBlock() {
      if (onLastRide == null) {
        return Text(
          meta,
          key: const Key('hof-resident-meta'),
          style: metaStyle,
        );
      }
      return Semantics(
        button: true,
        label: '$meta · ${l10n.hofWhatCameIn}',
        excludeSemantics: true,
        child: InkWell(
          key: const Key('hof-resident-meta'),
          onTap: onLastRide,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(meta, style: metaStyle)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  l10n.hofWhatCameIn,
                  key: const Key('hof-what-came-in'),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BikeHeroBanner(
          key: const Key('hof-parked-mark'),
          bike: bike,
          onTap: onOpenBike,
          showPhotoPicker: false,
          showActiveBadge: false,
          showCaption: false,
          photoHeight: photoHeight < 90 ? 88 : photoHeight,
        ),
        const SizedBox(height: AppSpacing.s),
        InkWell(
          onTap: onOpenBike,
          child: Text(
            bike.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        const SizedBox(height: 2),
        metaBlock(),
        if (healthLine != null) ...[
          const SizedBox(height: 4),
          InkWell(
            onTap: onOpenBike,
            child: Text(
              healthLine!,
              key: const Key('hof-bike-health'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.chrome,
              ),
            ),
          ),
        ],
        if (lastRide != null && lastRide!.track.length >= 2) ...[
          const SizedBox(height: AppSpacing.s),
          _LastRideSpark(ride: lastRide!, onTap: onLastRide),
        ],
        if (bleAwake) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.hofSensorAwake,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (others.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.m),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              for (final b in others)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onBringForward(b.id),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: SizedBox(
                      width: 92,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RadMiniStand(
                            bike: b,
                            photo: photos[b.id],
                            width: 92,
                            height: 48,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.hofBringForward(b.name),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LastRideSpark extends StatelessWidget {
  const _LastRideSpark({required this.ride, this.onTap});

  final RideRecord ride;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tel = buildRideTelemetry(ride.track);
    if (!tel.hasElev) return const SizedBox.shrink();
    return RideTerrainPeek(
      key: const Key('hof-ride-spark'),
      telemetry: tel,
      caption: terrainCaption(tel),
      onTap: onTap,
    );
  }
}

class _EmptyStand extends StatelessWidget {
  const _EmptyStand({required this.l10n, this.compact = false});

  final AppLocalizations l10n;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: compact ? 96 : 160,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: RadEmptyStandMark(height: compact ? 96 : 160),
        ),
        const SizedBox(height: AppSpacing.m),
        Text(
          l10n.hofEmptyStand,
          key: const Key('hof-empty-stand'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.hofNoBikeHere,
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      ],
    );
  }
}

class _GateCard extends StatelessWidget {
  const _GateCard({
    required this.l10n,
    required this.pick,
    required this.onTap,
    required this.minutes,
    required this.onMinutes,
    this.neighbors,
  });

  final AppLocalizations l10n;
  final HofGatePick pick;
  final TourCommunityCounts? neighbors;
  final VoidCallback onTap;
  final int minutes;
  final ValueChanged<int> onMinutes;

  Widget _lensChips() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s),
      child: Wrap(
        spacing: AppSpacing.s,
        children: [
          for (final m in DurationLens.hofGateMinutes)
            ChoiceChip(
              key: Key('hof-gate-lens-$m'),
              label: Text('~$m'),
              selected: minutes == m,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => onMinutes(m),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (pick.honesty == HofGateHonesty.none && !pick.hasLoop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: const Key('hof-gate'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.hofNoHonestLoop,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.hofOpenTours,
                    style: const TextStyle(
                      color: AppColors.chrome,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _lensChips(),
        ],
      );
    }

    final title = pick.hasLoop
        ? tourDisplayName(pick.title)
        : hofGateEmptyTitle(
            honesty: pick.honesty,
            wetClosed: l10n.hofGateWetClosed,
            noLoop: l10n.hofNoHonestLoop,
          );
    final duration =
        pick.hasLoop ? l10n.hofLoopDuration(pick.durationMin) : null;
    final neighborLine = (neighbors != null && neighbors!.hasCommunity)
        ? l10n.hofCommunityNotes(neighbors!.reviewCount + neighbors!.photoCount)
        : null;
    final away = formatHofGateAway(
      distanceKm: pick.distanceKm,
      underOne: l10n.hofGateAwayNear,
      km: l10n.hofGateAwayKm,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('hof-gate'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.hofAtGate,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    duration == null ? title : '$title · $duration',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  if (away != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      away,
                      key: const Key('hof-gate-away'),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (neighborLine != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      neighborLine,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        _lensChips(),
      ],
    );
  }
}

class _SystemStatusIcon extends StatelessWidget {
  const _SystemStatusIcon({required this.hasNotice, required this.onTap});

  final bool hasNotice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: hasNotice ? l10n.hofSystemNotice : l10n.hofSystemStatus,
      child: Tooltip(
        message: hasNotice ? l10n.hofSystemHint : l10n.hofSystemOkTooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 22,
                  color: hasNotice ? AppColors.warning : AppColors.muted,
                ),
                if (hasNotice)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.warning,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HofProfileAvatar extends StatelessWidget {
  const _HofProfileAvatar({
    required this.initials,
    required this.photo,
    required this.signedIn,
  });

  final String initials;
  final String? photo;
  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photo != null &&
        (photo!.startsWith('http') || File(photo!).existsSync());
    return CircleAvatar(
      backgroundColor: AppColors.charcoal.withValues(alpha: 0.12),
      backgroundImage: hasPhoto
          ? (photo!.startsWith('http')
              ? NetworkImage(photo!)
              : FileImage(File(photo!)) as ImageProvider)
          : null,
      child: hasPhoto
          ? null
          : (initials == '?'
              ? Icon(
                  Icons.person_outline,
                  color: signedIn ? AppColors.accent : AppColors.muted,
                )
              : Text(
                  initials,
                  style: TextStyle(
                    color: signedIn ? AppColors.accent : AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                )),
    );
  }
}
