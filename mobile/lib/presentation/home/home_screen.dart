import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/theme/app_theme.dart';
import '../../data/weather/weather_client.dart';
import '../../domain/bike.dart';
import '../../domain/ebike/range.dart';
import '../../domain/home/greeting.dart';
import '../../domain/maintenance/intervals.dart';
import '../../domain/saved_route.dart';
import '../../domain/setup.dart';
import '../../domain/setup/fingerprint.dart';
import '../../providers/app_providers.dart';
import '../auth/auth_screen.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';

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
      var lat = 47.99;
      var lon = 7.85;
      try {
        final perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          await Geolocator.requestPermission();
        }
        final pos = await Geolocator.getLastKnownPosition();
        if (pos != null) {
          lat = pos.latitude;
          lon = pos.longitude;
        }
      } catch (_) {}
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

  @override
  Widget build(BuildContext context) {
    final bikes = ref.watch(bikesProvider);
    final session = ref.watch(authSessionProvider).valueOrNull;
    final savedRoutes = ref.watch(savedRoutesProvider);
    final store = ref.watch(userProfileStoreProvider);

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
                      final name =
                          list.isEmpty ? 'Garage öffnen' : (active?.name ?? list.first.name);
                      return InkWell(
                        onTap: () =>
                            ref.read(shellTabIndexProvider.notifier).state = 1,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.forest.withValues(alpha: 0.2),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.pedal_bike, color: AppColors.accent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
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
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Chat',
                  onPressed: () => openChatScreen(context),
                  icon: const Icon(Icons.chat_bubble_outline),
                ),
                InkWell(
                  onTap: () => openProfileScreen(context),
                  borderRadius: BorderRadius.circular(24),
                  child: CircleAvatar(
                    backgroundColor: AppColors.forest.withValues(alpha: 0.12),
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
              ],
            ),
            const SizedBox(height: 20),
            Text(
              greet,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.forest,
                  ),
            ),
            Text(
              _weatherLoading
                  ? 'Wetter wird geladen…'
                  : _weather == null
                      ? 'AetherRide'
                      : '${_weather!.tempC.toStringAsFixed(0)}° · ${_weather!.trailLabel} · ${_weather!.summary}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
            const SizedBox(height: 12),
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
                          onTap: () =>
                              ref.read(shellTabIndexProvider.notifier).state = 1,
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
                bikeName: active.name,
                setup: setupAsync.valueOrNull,
              ),
              const SizedBox(height: 12),
            ],
            _TipHero(
              setup: setupAsync.valueOrNull,
              saved: savedRoutes.valueOrNull,
              weather: _weather,
              weightKg: store.effectiveWeightKg,
            ),
            if (active != null &&
                (active.category == BikeCategory.emtb ||
                    active.category == BikeCategory.etrekking)) ...[
              const SizedBox(height: 12),
              _RangeCard(bike: active, setup: setupAsync.valueOrNull),
            ],
            if (bikes.valueOrNull?.isEmpty == true) ...[
              const SizedBox(height: 16),
              _OnboardingCards(
                onGarage: () =>
                    ref.read(shellTabIndexProvider.notifier).state = 1,
                onShop: () =>
                    ref.read(shellTabIndexProvider.notifier).state = 4,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () =>
                  ref.read(shellTabIndexProvider.notifier).state = 2,
              child: const Text('Ride starten'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => openChatScreen(context),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Assistent fragen'),
            ),
            const SizedBox(height: 8),
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

class _FingerprintCard extends StatelessWidget {
  const _FingerprintCard({required this.bikeName, this.setup});
  final String bikeName;
  final BikeSetup? setup;

  @override
  Widget build(BuildContext context) {
    final fp = SetupFingerprint.fromSetup(setup);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(bikeName, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            fp.lines.join(' · '),
            style: const TextStyle(fontSize: 13),
          ),
          if (fp.conditionLabel != null)
            Text(
              'Bedingungen: ${fp.conditionLabel}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
        ],
      ),
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
    final route = (saved != null && saved.isNotEmpty) ? saved.first : null;
    final title = route?.name ?? 'Freifahren starten';
    final subtitle = route == null
        ? 'Keine gespeicherte Tour — Discover öffnen oder Freeride'
        : '${route.distanceKm.toStringAsFixed(1)} km · '
            '${route.elevationM.round()} hm · ${route.durationMin} min';
    final reasons = <String>[
      if (weather != null)
        'Wetter: ${weather.trailLabel} (${weather.tempC.toStringAsFixed(0)}°)',
      if (fp.lines.isNotEmpty) 'Fingerprint: ${fp.lines.first}',
      if (route != null)
        'Gespeicherte Route: ${route.name}'
      else
        'Zeitfenster bereit — keine Saved Route',
      if (weightKg != null)
        'Fahrergewicht ${weightKg.toStringAsFixed(0)} kg (aktiv)',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
          const SizedBox(height: 6),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            reasons.take(2).join(' · '),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => setState(() => _evidenceOpen = !_evidenceOpen),
            child: Row(
              children: [
                Text(
                  _evidenceOpen ? 'Warum? einklappen' : 'Warum? Evidence',
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
            const SizedBox(height: 6),
            for (final r in reasons)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '· $r',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            const Text(
              'Quellen: Wetter-API · Setup-Fingerprint · Saved Routes',
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      ref.read(shellTabIndexProvider.notifier).state = 3,
                  child: const Text('Discover'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                  ),
                  onPressed: () =>
                      ref.read(shellTabIndexProvider.notifier).state = 2,
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
          subtitle: const Text('Garage · Katalog oder Basisdaten'),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reichweite ${bike.categoryLabel}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
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
