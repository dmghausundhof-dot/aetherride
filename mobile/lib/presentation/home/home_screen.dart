import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/community/ride_group_store.dart';
import '../../data/community/tour_community_store.dart';
import '../../data/routing/map_style_url.dart';
import '../../data/routing/naehe_seeds.dart';

import '../../data/weather/weather_client.dart';
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
import '../../data/routing/saved_route_meta_store.dart';
import '../../domain/saved_route_note.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';
import '../auth/auth_screen.dart';

import '../post_ride/post_ride_screen.dart';
import '../profile/profile_screen.dart';
import '../shared/bike_hero_banner.dart';
import '../shared/bike_schema_view.dart';
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
  double? _lat;
  double? _lng;
  NaeheSeedsBundle? _seeds;
  HofGatePick _gate = const HofGatePick();
  int _gateMinutes = 60;
  TourCommunityCounts? _neighbors;
  String? _tafelStimmenText;
  String? _tafelStimmenRouteId;
  String? _tafelGroupText;


  @override
  void initState() {
    super.initState();
    TourCommunityStore.revision.addListener(_onCommunityRevision);
    RideGroupStore.revision.addListener(_onGroupRevision);
    unawaited(_bootHof());
  }

  @override
  void dispose() {
    TourCommunityStore.revision.removeListener(_onCommunityRevision);
    RideGroupStore.revision.removeListener(_onGroupRevision);
    super.dispose();
  }

  void _onGroupRevision() => unawaited(_loadTafelGroup());

  void _onCommunityRevision() {
    if (!mounted) return;
    final id = _gate.seed?.id;
    if (id != null) unawaited(_loadNeighbors(id));
    unawaited(_loadTafelStimmen());
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
      _tafelGroupText = groups.isEmpty
          ? null
          : l10n.hofTafelGroup(groups.first.title);
    });
  }

  Future<void> _loadPosition({bool prompt = false}) async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (prompt &&
          (perm == LocationPermission.denied ||
              perm == LocationPermission.deniedForever)) {
        await Geolocator.openAppSettings();
        perm = await Geolocator.checkPermission();
      }
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
        if (pos != null &&
            DateTime.now().difference(pos.timestamp) >
                const Duration(minutes: 10)) {
          pos = null;
        }
      }
      if (pos != null && mounted) {
        setState(() {
          _lat = pos!.latitude;
          _lng = pos.longitude;
        });
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
      if (mounted) setState(() => _weatherResolved = true);
      return;
    }
    try {
      final w = await ref.read(weatherClientProvider).fetch(lat: lat, lon: lng);
      if (mounted) {
        setState(() {
          _weather = w;
          _weatherResolved = true;
        });
        if (_seeds != null) _recomputeGate();
      }
    } catch (_) {
      if (mounted) setState(() => _weatherResolved = true);
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
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
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
      ref.read(discoverPendingAkteRouteIdProvider.notifier).state =
          akteRouteId;
    }
    ref.read(shellTabIndexProvider.notifier).state = ShellTabs.platz;
  }

  void _startRide() {
    final done = ref.read(onboardingDoneProvider);
    if (done == false) return;
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
        ref.read(rideAutostartProvider.notifier).state = true;
        ref.read(shellTabIndexProvider.notifier).state = ShellTabs.ride;
        return;
      }
    }
    _openKarte();
  }

  String _skyLine(AppLocalizations l10n) {
    if (!_weatherResolved) return '';
    if (_lat == null) return '';
    final w = _weather;
    if (w == null) return l10n.hofSkyUnknown;
    final temp = w.tempC.round().toString();
    return switch (w.trailHint) {
      'wet_likely' => l10n.hofSkyWet(temp),
      'damp_possible' => l10n.hofSkyDamp(temp),
      _ => l10n.hofSkyDry(temp),
    };
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
          onPressed: () => openProfileScreen(context),
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
        : Text(
            sky,
            key: const Key('hof-sky'),
            style: const TextStyle(
              color: AppColors.sageOnDark,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
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
        final comps = ref
                    .watch(bikeComponentsProvider(active.id))
                    .valueOrNull ??
                const <BikeComponent>[];
        final hasMotor = comps.any((c) => c.slot == ComponentSlot.motor);
        final lastId = ret?.rideId;
        return Semantics(
          container: true,
          explicitChildNodes: true,
          child: _Resident(
            bike: active,
            others: others,
            ret: ret!,
            l10n: l10n,
            sport: l10n.hofResidentSportLabel(active, hasMotor: hasMotor),
            bleAwake: bleAwake,
            photoHeight: shortLandscape ? 72 : (landscape ? 96 : 112),
            hasPhoto: (store.bikePhotos[active.id]?.trim().isNotEmpty ??
                false),
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

    final savedCount =
        ref.watch(savedRoutesProvider).valueOrNull?.length ?? 0;

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
                      : null,
                ),
      );
    }

    Widget tourColumn(String? careText, {bool overdue = false}) {
      final lines = buildHofTafel(
        careText: careText,
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
                for (final item in careLines)
                  tafelLine(item, overdue: overdue),
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
          final setup =
              ref.watch(currentSetupProvider(bike.id)).valueOrNull;
          final logs = ref.watch(userProfileStoreProvider).maintenanceLogs;
          return compsAsync.when(
            data: (comps) {
              final due = listDueMaintenance(
                bike: bike,
                components: comps,
              );
              final plan = planDieBox(
                bike: bike,
                components: comps,
                currentSetup: setup,
                setups: setup != null ? [setup] : const [],
                due: due,
                logs: logs,
              );
              final item = tafelCareItem(plan);
              return tourColumn(
                item == null ? null : l10n.hofCareInWorkshop(item.title),
                overdue: item?.due?.status == DueStatus.overdue,
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

    final ctaHeight = shortLandscape ? 44.0 : 52.0;
    final emptyStand = active == null;
    final cta = FilledButton(
      key: const Key('hof-ride-out'),
      style: emptyStand
          ? AppTheme.parkCta(height: ctaHeight)
          : AppTheme.rideOutCta(height: ctaHeight),
      onPressed: emptyStand
          ? () => _openGarage(addBike: true)
          : _startRide,
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
        onPressed: emptyStand
            ? _startRide
            : () => _openGarage(bikeId: active!.id),
        child: Text(
          emptyStand ? l10n.hofRideWithoutBike : l10n.hofOpenBike,
        ),
      ),
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
                                  if (gate != null) ...[
                                    const SizedBox(height: AppSpacing.s),
                                    gate,
                                  ],
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
    required this.l10n,
    required this.sport,
    required this.bleAwake,
    required this.onOpenBike,
    required this.onBringForward,
    this.onLastRide,
    this.photoHeight = 188,
    this.hasPhoto = false,
  });

  final Bike bike;
  final List<Bike> others;
  final RideReturn ret;
  final AppLocalizations l10n;
  final String sport;
  final bool bleAwake;
  final VoidCallback onOpenBike;
  final Future<void> Function(String id) onBringForward;
  final VoidCallback? onLastRide;
  final double photoHeight;
  final bool hasPhoto;

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
        if (hasPhoto)
          BikeHeroBanner(
            bike: bike,
            onTap: onOpenBike,
            showPhotoPicker: false,
            showActiveBadge: false,
            showCaption: false,
            photoHeight: photoHeight,
          ),
        if (hasPhoto) const SizedBox(height: AppSpacing.s),
        if (!hasPhoto) ...[
          BikeSchemaView(
            key: const Key('hof-parked-mark'),
            bike: bike,
            height: photoHeight < 90 ? 88 : 140,
          ),
          const SizedBox(height: AppSpacing.s),
        ],
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
                ActionChip(
                  label: Text(l10n.hofBringForward(b.name)),
                  onPressed: () => onBringForward(b.id),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ],
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
          child: const CustomPaint(painter: _StandPainter()),
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

class _StandPainter extends CustomPainter {
  const _StandPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.muted
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final cy = size.height * 0.72;
    final cx = size.width / 2;
    canvas.drawLine(
        Offset(size.width * 0.22, cy), Offset(size.width * 0.78, cy), paint);
    canvas.drawLine(Offset(cx, cy), Offset(cx, size.height * 0.32), paint);
    canvas.drawLine(
      Offset(cx - 28, size.height * 0.32),
      Offset(cx + 28, size.height * 0.32),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
