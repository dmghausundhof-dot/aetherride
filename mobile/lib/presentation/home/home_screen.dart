import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/community/tour_community_store.dart';
import '../../data/routing/naehe_seeds.dart';
import '../../data/weather/weather_client.dart';
import '../../domain/active_route.dart';
import '../../domain/bike.dart';
import '../../domain/home/greeting.dart';
import '../../domain/home/hof_gate.dart';
import '../../domain/home/hof_title.dart';
import '../../domain/maintenance/intervals.dart';
import '../../domain/routing/tour_nav_geometry.dart';
import '../../domain/sport/discipline_ux.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';
import '../auth/auth_screen.dart';
import '../profile/profile_screen.dart';
import '../shared/bike_hero_banner.dart';
import '../shell/shell_tabs.dart';
import 'hof_watch_card.dart';
import 'hof_watch_bar_button.dart';

/// Der Hof — das Rad wohnt hier. Intern `hof`; Titel folgt dem Land.
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
  TourCommunityCounts? _neighbors;

  @override
  void initState() {
    super.initState();
    unawaited(_bootHof());
  }

  Future<void> _bootHof() async {
    await _loadPosition();
    if (!mounted) return;
    await Future.wait([_loadWeather(), _loadGate()]);
  }

  Future<void> _loadPosition() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
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
    final pick = pickHofGate(
      loops: bundle.loops,
      saved: saved,
      lat: _lat,
      lng: _lng,
      trailsWet: wet,
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
                const Text(
                  'Systemstatus',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
                const SizedBox(height: AppSpacing.m),
                if (!showSupabaseWarning && !showSyncWarning)
                  const Text(
                    'Alles verbunden — Werkstatt, Fahrten und Sync laufen normal.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                if (showSupabaseWarning) ...[
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.settings_outlined),
                    title: Text(
                      'Supabase nicht konfiguriert',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Cloud-Sync ist nicht eingerichtet — Anmeldung und Sync sind aus.',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                ],
                if (showSyncWarning)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cloud_off_outlined),
                    title: Text(
                      syncStatus == SyncAuthStatus.unauthorized
                          ? 'Sync: Sitzung abgelaufen'
                          : 'Sync nur mit Login',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Garage/Rides bleiben lokal — Konto für Cloud-Sync.',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (syncStatus == SyncAuthStatus.unauthorized)
                          TextButton(
                            onPressed: () {
                              unawaited(ref.read(syncEngineProvider).syncNow());
                              Navigator.pop(ctx);
                            },
                            child: const Text('Erneut'),
                          ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            openAuthScreen(context);
                          },
                          child: const Text('Anmelden'),
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

  void _startRide() {
    final done = ref.read(onboardingDoneProvider);
    if (done == false) return;
    ref.read(discoverLaunchModeProvider.notifier).state =
        DiscoverLaunchMode.rideOut;
    ref.read(shellTabIndexProvider.notifier).state = ShellTabs.karte;
  }

  void _openGate() {
    final gate = _gate;
    if (gate.seed != null) {
      ref.read(discoverPendingLoopIdProvider.notifier).state = gate.seed!.id;
      ref.read(discoverPendingLensMinutesProvider.notifier).state = 60;
      ref.read(shellTabIndexProvider.notifier).state = ShellTabs.karte;
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
    _startRide();
  }

  String _skyLine(AppLocalizations l10n) {
    if (!_weatherResolved) return '';
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
    final locale = Localizations.localeOf(context);
    final seedCountry =
        _gate.seed != null ? countryFromSeedId(_gate.seed!.id) : null;
    return hofTitleFor(
      countryCode: seedCountry ?? locale.countryCode,
      languageCode: locale.languageCode,
    );
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
    Bike? active;
    if (list != null && list.isNotEmpty) {
      active = list.firstWhere((b) => b.isActive, orElse: () => list.first);
    }
    final others = (list ?? [])
        .where((b) => active == null || b.id != active.id)
        .toList();

    final displayName = store.displayName;
    final initials = avatarInitials(
      displayName: displayName,
      email: session?.user.email,
    );

    RideReturn? ret;
    if (active != null) {
      ret = rideReturnForBike(bikeId: active.id, rides: rides);
    }
    final justBack = ret?.hidesGate == true;
    final bleAwake = ref.read(bleCoreProvider).isConnected;

    final sky = _skyLine(l10n);
    final title = _hofTitle(context);
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final shortLandscape =
        landscape && MediaQuery.sizeOf(context).height < 560;

    final header = Row(
      children: [
        Expanded(
          child: Text(
            title,
            key: const Key('hof-title'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.forestOnDark,
                  fontSize: landscape ? 22 : null,
                ),
          ),
        ),
        const HofWatchBarButton(),
        const SizedBox(width: AppSpacing.xs),
        _SystemStatusIcon(
          hasNotice: showSupabaseWarning || showSyncWarning,
          onTap: () => _openSystemStatusSheet(
            context,
            showSupabaseWarning: showSupabaseWarning,
            showSyncWarning: showSyncWarning,
            syncStatus: syncStatus,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Semantics(
          button: true,
          label: l10n.profile,
          child: Tooltip(
            message: l10n.profile,
            child: InkWell(
              onTap: () => openProfileScreen(context),
              borderRadius: BorderRadius.circular(24),
              child: CircleAvatar(
                backgroundColor: AppColors.forest.withValues(alpha: 0.12),
                child: Text(
                  initials,
                  style: TextStyle(
                    color: session != null ? AppColors.accent : AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s),
      ],
    );

    final skyChip = sky.isEmpty
        ? null
        : Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.s,
            ),
            decoration: BoxDecoration(
              color: (_weather?.trailHint == 'wet_likely')
                  ? AppColors.forest.withValues(alpha: 0.18)
                  : AppColors.forest.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Text(
              sky,
              key: const Key('hof-sky'),
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          );

    final gpsHonesty = (_weatherResolved && _lat == null)
        ? Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s),
            child: Text(
              l10n.hofGpsUnknown,
              key: const Key('hof-gps-honesty'),
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
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
        return _Resident(
          bike: active,
          others: others,
          ret: ret!,
          l10n: l10n,
          bleAwake: bleAwake,
          photoHeight: shortLandscape ? 72 : (landscape ? 108 : 188),
          onOpenBike: () => _openGarage(bikeId: active!.id),
          onBringForward: (id) async {
            await ref.read(garageRepositoryProvider).setActiveBike(id);
            ref.invalidate(bikesProvider);
          },
        );
      },
    );

    Widget care = const SizedBox.shrink();
    if (active != null) {
      care = Consumer(
        builder: (context, ref, _) {
          final compsAsync = ref.watch(bikeComponentsProvider(active!.id));
          return compsAsync.when(
            data: (comps) {
              final due = listDueMaintenance(
                bike: active!,
                components: comps,
              );
              if (due.isEmpty) return const SizedBox.shrink();
              final top = due.first;
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.m),
                child: InkWell(
                  onTap: () => _openGarage(bikeId: active!.id),
                  child: Text(
                    l10n.hofCareInWorkshop(top.label),
                    style: TextStyle(
                      color: top.status == DueStatus.overdue
                          ? Colors.redAccent
                          : AppColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          );
        },
      );
    }

    final gate = (!justBack)
        ? _GateCard(
            l10n: l10n,
            pick: _gate,
            neighbors: _neighbors,
            onTap: _openGate,
          )
        : null;

    final cta = FilledButton(
      key: const Key('hof-ride-out'),
      style: AppTheme.rideOutCta(height: shortLandscape ? 44 : 52),
      onPressed: _startRide,
      child: Text(
        active == null
            ? l10n.hofJustRide
            : (justBack ? l10n.hofRideOutAgain : l10n.hofRideOut),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );

    final secondary = Center(
      child: TextButton(
        onPressed: active == null
            ? () => _openGarage(addBike: true)
            : () => _openGarage(bikeId: active!.id),
        child: Text(
          active == null ? l10n.hofParkBike : l10n.hofOpenBike,
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
                    if (!short && skyChip != null) ...[
                      const SizedBox(height: AppSpacing.s),
                      skyChip,
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
                                  care,
                                  if (short && skyChip != null) ...[
                                    const SizedBox(height: AppSpacing.s),
                                    skyChip,
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
                                  const SizedBox(height: AppSpacing.s),
                                  watch,
                                  if (gate != null) ...[
                                    const SizedBox(height: AppSpacing.s),
                                    gate,
                                  ],
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            header,
            if (skyChip != null) ...[
              const SizedBox(height: AppSpacing.m),
              skyChip,
            ],
            if (gpsHonesty != null) gpsHonesty,
            const SizedBox(height: AppSpacing.l),
            resident,
            care,
            if (gate != null) ...[
              const SizedBox(height: AppSpacing.l),
              gate,
            ],
            const SizedBox(height: AppSpacing.xl),
            cta,
            const SizedBox(height: AppSpacing.s),
            secondary,
            const SizedBox(height: AppSpacing.l),
            const HofWatchCard(),
          ],
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
    required this.bleAwake,
    required this.onOpenBike,
    required this.onBringForward,
    this.photoHeight = 188,
  });

  final Bike bike;
  final List<Bike> others;
  final RideReturn ret;
  final AppLocalizations l10n;
  final bool bleAwake;
  final VoidCallback onOpenBike;
  final Future<void> Function(String id) onBringForward;
  final double photoHeight;

  @override
  Widget build(BuildContext context) {
    final sport = bike.category.shortLabel;
    var meta = switch (ret.kind) {
      RideReturnKind.neverOut => '$sport · ${l10n.hofAtHof} · ${l10n.hofNotYetOut}',
      RideReturnKind.justBack =>
        '${l10n.hofJustBack} · ${ret.distanceKm!.toStringAsFixed(1)} km · '
            '${formatMovingTime(ret.movingTimeSec ?? 0)}',
      RideReturnKind.atHof =>
        '$sport · ${l10n.hofAtHof} · ${ret.daysSince == 1 ? l10n.hofSinceOneDay : l10n.hofSinceDays(ret.daysSince ?? 1)}',
    };
    if (ret.kind != RideReturnKind.neverOut && !ret.usedGps) {
      meta = '$meta · ${l10n.hofLastRideNoGps}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BikeHeroBanner(
          bike: bike,
          onTap: onOpenBike,
          showPhotoPicker: false,
          showActiveBadge: false,
          showCaption: false,
          photoHeight: photoHeight,
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          bike.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          meta,
          key: const Key('hof-resident-meta'),
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
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
    canvas.drawLine(Offset(size.width * 0.22, cy), Offset(size.width * 0.78, cy), paint);
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
    this.neighbors,
  });

  final AppLocalizations l10n;
  final HofGatePick pick;
  final TourCommunityCounts? neighbors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (pick.honesty == HofGateHonesty.none && !pick.hasLoop) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
          child: Text(
            l10n.hofOpenTours,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    final title = pick.hasLoop ? pick.title : l10n.hofNoHonestLoop;
    final duration = pick.hasLoop ? l10n.hofLoopDuration(pick.durationMin) : null;
    final neighborLine = (neighbors != null && neighbors!.hasCommunity)
        ? l10n.hofCommunityNotes(neighbors!.reviewCount + neighbors!.photoCount)
        : null;

    return Material(
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
              if (neighborLine != null) ...[
                const SizedBox(height: 2),
                Text(
                  neighborLine,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemStatusIcon extends StatelessWidget {
  const _SystemStatusIcon({required this.hasNotice, required this.onTap});

  final bool hasNotice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: hasNotice ? 'Systemstatus — Hinweis vorhanden' : 'Systemstatus',
      child: Tooltip(
        message: hasNotice ? 'Systemstatus — Hinweis' : 'Systemstatus: ok',
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
                  color: hasNotice ? Colors.orange.shade700 : AppColors.muted,
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
                        color: Colors.orange.shade700,
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
