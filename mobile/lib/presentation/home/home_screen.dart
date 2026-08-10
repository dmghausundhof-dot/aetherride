import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/sync/sync_engine.dart';
import '../../data/weather/weather_client.dart';
import '../../domain/bike.dart';
import '../../domain/ebike/range.dart';
import '../../domain/home/greeting.dart';
import '../../domain/maintenance/intervals.dart';
import '../../domain/active_route.dart';
import '../../domain/saved_route.dart';
import '../../domain/setup.dart';
import '../../domain/setup/fingerprint.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';
import '../auth/auth_screen.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';
import '../shared/bike_hero_banner.dart';

/// Spec-naher Home-Companion: Wetter, Suggestions, Fingerprint, Wartung.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  WeatherSnapshot? _weather;
  bool _weatherLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      double? lat;
      double? lon;
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
        if (pos != null) {
          lat = pos.latitude;
          lon = pos.longitude;
        }
      } catch (_) {}
      if (lat == null || lon == null) {
        if (mounted) setState(() => _weatherLoading = false);
        return;
      }
      final w = await ref.read(weatherClientProvider).fetch(lat: lat, lon: lon);
      if (mounted) {
        setState(() {
          _weather = w;
          _weatherLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _weatherLoading = false);
    }
  }

  /// Detail-Sheet für Config-/Sync-Hinweise — vom Status-Icon geöffnet statt
  /// dauerhaft im Feed zu stehen.
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
                    'Alles verbunden — Garage, Rides und Sync laufen normal.',
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
                      'SUPABASE_URL / SUPABASE_ANON_KEY fehlen — Auth & Cloud-Sync aus.',
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

  @override
  Widget build(BuildContext context) {
    final bikes = ref.watch(bikesProvider);
    final session = ref.watch(authSessionProvider).valueOrNull;
    final savedRoutes = ref.watch(savedRoutesProvider);
    final store = ref.watch(userProfileStoreProvider);
    final syncStatus = ref.watch(syncAuthStatusProvider);
    // Systemzustand (Config/Sync) ist ein Icon, kein Feed-Eintrag — Zuhause
    // bleibt der ruhige, persönliche Teil der Startseite.
    final showSupabaseWarning = kDebugMode && !AppConfig.isSupabaseConfigured;
    final showSyncWarning = AppConfig.isSupabaseConfigured &&
        (syncStatus == SyncAuthStatus.noAuth ||
            syncStatus == SyncAuthStatus.unauthorized);

    final active = bikes.whenData((list) {
      if (list.isEmpty) return null;
      return list.firstWhere((b) => b.isActive, orElse: () => list.first);
    }).valueOrNull;

    final setupAsync = active == null
        ? const AsyncValue<BikeSetup?>.data(null)
        : ref.watch(currentSetupProvider(active.id));

    final displayName = store.displayName;
    final initials = avatarInitials(
      displayName: displayName,
      email: session?.user.email,
    );
    final greet = greetingLine(displayName: displayName);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: bikes.when(
                    data: (list) {
                      final name = list.isEmpty
                          ? 'Garage öffnen'
                          : (active?.name ?? list.first.name);
                      return InkWell(
                        onTap: () =>
                            ref.read(shellTabIndexProvider.notifier).state = 1,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.forest.withValues(alpha: 0.2),
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.pedal_bike,
                                  color: AppColors.accent),
                              const SizedBox(width: AppSpacing.s),
                              Expanded(
                                child: Text(
                                  name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              const Icon(Icons.chevron_right, size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Fehler: $e'),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                _SystemStatusIcon(
                  hasNotice: showSupabaseWarning || showSyncWarning,
                  onTap: () => _openSystemStatusSheet(
                    context,
                    showSupabaseWarning: showSupabaseWarning,
                    showSyncWarning: showSyncWarning,
                    syncStatus: syncStatus,
                  ),
                ),
                IconButton(
                  tooltip: 'Chat',
                  onPressed: () => openChatScreen(context),
                  icon: const Icon(Icons.chat_bubble_outline),
                ),
                Semantics(
                  button: true,
                  label: 'Profil',
                  child: Tooltip(
                    message: 'Profil',
                    child: InkWell(
                      onTap: () => openProfileScreen(context),
                      borderRadius: BorderRadius.circular(24),
                      child: CircleAvatar(
                        backgroundColor:
                            AppColors.forest.withValues(alpha: 0.12),
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: session != null
                                ? AppColors.accent
                                : AppColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              greet,
              // forestOnDark statt forest: forest ist für Text auf hellem
              // Grund kalibriert und fällt im Dark Theme unter 2:1 Kontrast.
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.forestOnDark,
                  ),
            ),
            Text(
              _weatherLoading
                  ? 'Wetter wird geladen…'
                  : _weather == null
                      ? 'Wetter nicht verfügbar'
                      : '${_weather!.tempC.toStringAsFixed(0)}° · ${_weather!.trailLabel} · ${_weather!.summary}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
            const SizedBox(height: AppSpacing.m),
            if (active != null)
              Consumer(
                builder: (context, ref, _) {
                  final compsAsync =
                      ref.watch(bikeComponentsProvider(active.id));
                  return compsAsync.when(
                    data: (comps) {
                      final due = listDueMaintenance(
                        bike: active,
                        components: comps,
                      );
                      if (due.isEmpty) return const SizedBox.shrink();
                      final top = due.first;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => ref
                              .read(shellTabIndexProvider.notifier)
                              .state = 1,
                          child: Text(
                            top.status == DueStatus.overdue
                                ? 'Wartung fällig: ${top.label} → Garage / Shop'
                                : 'Bald fällig: ${top.label} (${top.remainingLabel})',
                            style: TextStyle(
                              color: top.status == DueStatus.overdue
                                  ? Colors.redAccent
                                  : Colors.orange.shade800,
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
              ),
            if (active != null) ...[
              _FingerprintCard(
                bike: active,
                setup: setupAsync.valueOrNull,
                onTap: () =>
                    ref.read(shellTabIndexProvider.notifier).state = 1,
              ),
              const SizedBox(height: AppSpacing.m),
            ],
            _TipHero(
              setup: setupAsync.valueOrNull,
              saved: savedRoutes.valueOrNull,
              weather: _weather,
              weightKg: store.effectiveWeightKg,
            ),
            // Supabase-/Sync-Hinweise stehen nicht mehr im persönlichen
            // Feed — sie hängen am Status-Icon oben (_SystemStatusIcon) und
            // öffnen von dort ein Detail-Sheet (_openSystemStatusSheet).
            if (active != null &&
                (active.category == BikeCategory.emtb ||
                    active.category == BikeCategory.etrekking)) ...[
              const SizedBox(height: AppSpacing.m),
              _RangeCard(bike: active, setup: setupAsync.valueOrNull),
            ],
            if (bikes.valueOrNull?.isEmpty == true) ...[
              const SizedBox(height: AppSpacing.l),
              _OnboardingCards(
                onGarage: () =>
                    ref.read(shellTabIndexProvider.notifier).state = 1,
                onShop: () =>
                    ref.read(shellTabIndexProvider.notifier).state = 4,
              ),
            ],
            const SizedBox(height: AppSpacing.l),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () {
                final done = ref.read(onboardingDoneProvider);
                if (done == false) {
                  // Overlay ist schon sichtbar — Fokus auf Step 3.
                  return;
                }
                ref.read(shellTabIndexProvider.notifier).state = 2;
              },
              child: Text(
                // Gleicher deutscher Begriff wie im Ride-Screen selbst
                // („Freifahren starten") statt des englischen „Freeride".
                bikes.valueOrNull?.isEmpty == true
                    ? 'Freifahren starten'
                    : 'Ride starten',
              ),
            ),
            if (bikes.valueOrNull?.isEmpty == true) ...[
              const SizedBox(height: AppSpacing.s),
              Text(
                'Ohne Bike möglich — GPS-Track wird lokal gespeichert.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.muted.withValues(alpha: 0.95),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.m),
            OutlinedButton.icon(
              onPressed: () => openChatScreen(context),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Assistent fragen'),
            ),
            const SizedBox(height: AppSpacing.s),
            TextButton(
              onPressed: () => openAuthScreen(context),
              child: const Text('Konto & Sync'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Systemzustand als ruhiges Icon mit Punkt statt Feed-Eintrag. Ein Punkt
/// heißt "es gibt einen Hinweis", kein Punkt heißt "alles ok" — Detail per
/// Tap, nie ungefragt im persönlichen Feed.
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

class _FingerprintCard extends StatelessWidget {
  const _FingerprintCard({required this.bike, this.setup, this.onTap});
  final Bike bike;
  final BikeSetup? setup;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fp = SetupFingerprint.fromSetup(setup);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BikeHeroBanner(bike: bike, onTap: onTap),
        if (fp.lines.isNotEmpty || fp.conditionLabel != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(2, AppSpacing.s, 2, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fp.lines.isNotEmpty)
                  Text(fp.lines.join(' · '), style: const TextStyle(fontSize: 13)),
                if (fp.conditionLabel != null)
                  Text(
                    'Bedingungen: ${fp.conditionLabel}',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TipHero extends ConsumerStatefulWidget {
  const _TipHero({
    required this.setup,
    required this.saved,
    this.weather,
    this.weightKg,
  });

  final BikeSetup? setup;
  final List<SavedRouteEntry>? saved;
  final WeatherSnapshot? weather;
  final double? weightKg;

  @override
  ConsumerState<_TipHero> createState() => _TipHeroState();
}

class _TipHeroState extends ConsumerState<_TipHero> {
  bool _evidenceOpen = false;

  @override
  Widget build(BuildContext context) {
    final setup = widget.setup;
    final saved = widget.saved;
    final weather = widget.weather;
    final weightKg = widget.weightKg;
    final fp = SetupFingerprint.fromSetup(setup);
    // Nicht die neueste Mega-Tour als „Heute passt“ — Dauer/Distanz-Cap.
    final avgMin =
        ref.watch(riderProfileProvider).valueOrNull?.avgRideDurationMin ?? 90;
    final maxMin = avgMin + 45;
    const maxKm = 40.0;
    SavedRouteEntry? route;
    if (saved != null) {
      for (final r in saved) {
        if (r.durationMin <= maxMin && r.distanceKm <= maxKm) {
          route = r;
          break;
        }
      }
    }
    final title = route?.name ?? 'Freifahren starten';
    final subtitle = route == null
        ? (saved != null && saved.isNotEmpty
            ? 'Gespeicherte Touren zu lang — Discover öffnen oder Freifahren'
            : 'Keine passende Tour — Discover öffnen oder Freifahren')
        : '${route.distanceKm.toStringAsFixed(1)} km · '
            '${route.elevationM.round()} hm · ${route.durationMin} min';
    final reasons = <String>[
      if (weather != null)
        'Wetter: ${weather.trailLabel} (${weather.tempC.toStringAsFixed(0)}°)',
      if (fp.lines.isNotEmpty) 'Dein Setup: ${fp.lines.first}',
      if (route != null)
        'Gespeicherte Route: ${route.name}'
      else
        'Zeitfenster ≤ ${maxMin.round()} min · ≤ ${maxKm.toStringAsFixed(0)} km',
      if (weightKg != null)
        'Fahrergewicht ${weightKg.toStringAsFixed(0)} kg (aktiv)',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HEUTE PASST',
            style: TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            reasons.take(2).join(' · '),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          InkWell(
            onTap: () => setState(() => _evidenceOpen = !_evidenceOpen),
            child: Row(
              children: [
                Text(
                  _evidenceOpen ? 'Warum? einklappen' : 'Warum? Begründung',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
                Icon(
                  _evidenceOpen ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: AppColors.accent,
                ),
              ],
            ),
          ),
          if (_evidenceOpen) ...[
            const SizedBox(height: AppSpacing.xs),
            for (final r in reasons)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '· $r',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            const Text(
              'Quellen: Wetter · Bike-Setup · Gespeicherte Touren',
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
          const SizedBox(height: AppSpacing.l),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(discoverLaunchModeProvider.notifier).state =
                        DiscoverLaunchMode.discover;
                    ref.read(shellTabIndexProvider.notifier).state = 3;
                  },
                  child: const Text('Discover'),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                  ),
                  onPressed: () {
                    final r = route;
                    if (r != null && r.coordinates.length >= 2) {
                      ref.read(activeRouteProvider.notifier).state =
                          ActiveRoute(
                        id: r.id,
                        name: r.name,
                        distanceKm: r.distanceKm,
                        elevationM: r.elevationM,
                        durationMin: r.durationMin,
                        coordinates: r.coordinates,
                      );
                    } else if (r != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Gespeicherte Tour ohne Track — Freifahren oder Discover.',
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Keine gespeicherte Tour — Freifahren oder Discover öffnen.',
                          ),
                        ),
                      );
                    }
                    ref.read(shellTabIndexProvider.notifier).state = 2;
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Losfahren'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OnboardingCards extends StatelessWidget {
  const _OnboardingCards({required this.onGarage, required this.onShop});
  final VoidCallback onGarage;
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.pedal_bike),
          title: const Text('Bike anlegen'),
          subtitle: const Text('Garage · Katalog, Basis oder GPX'),
          onTap: onGarage,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.build_circle_outlined),
          title: const Text('Basis-Setup'),
          subtitle: const Text('Templates & Sag-Guide in der Garage'),
          onTap: onGarage,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.storefront_outlined),
          title: const Text('Teile browsen'),
          subtitle: const Text('Shop mit Kompatibilitäts-Hinweis'),
          onTap: onShop,
        ),
      ],
    );
  }
}

class _RangeCard extends ConsumerWidget {
  const _RangeCard({required this.bike, this.setup});

  final Bike bike;
  final BikeSetup? setup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(userProfileStoreProvider);
    final tirePsi = setup?.valueFor('tire_rear.pressure_psi') ?? 24;
    final est = estimateRange(
      category: bike.category,
      calibration: store.rangeCalibration,
      tirePressurePsi: tirePsi,
      riderWeightKg: store.effectiveWeightKg,
      bikeWeightKg: bike.category == BikeCategory.emtb ? 24 : 22,
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reichweite ${bike.categoryLabel}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${est.kmLow}–${est.kmHigh} km · ${est.batteryWh} Wh · '
            '${est.whPerKmLow}–${est.whPerKmHigh} Wh/km',
          ),
          Text(
            est.calibrated
                ? 'Kalibriert · ${est.confidence} (${store.rangeCalibration?.samples ?? 0} Samples)'
                : 'Noch nicht kalibriert — nach E-Rides genauer',
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
