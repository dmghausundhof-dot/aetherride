import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/bike.dart';
import '../../domain/ebike/range.dart';
import '../../domain/maintenance/intervals.dart';
import '../../domain/saved_route.dart';
import '../../domain/setup.dart';
import '../../providers/app_providers.dart';
import '../auth/auth_screen.dart';
import '../chat/chat_screen.dart';
import '../privacy/privacy_screen.dart';

/// Spec-naher Home-Companion: Bike-Chip, Tip-Hero, Range, Ride-CTA, Chat.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _seedTip = (
    title: 'Flow Trail Söll',
    subtitle: '18.7 km · 720 hm · 1:35 h · S1–S2',
    reason: 'Weil: Flow-Charakter · Zeitfenster · eher trocken',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikes = ref.watch(bikesProvider);
    final session = ref.watch(authSessionProvider).valueOrNull;
    final savedRoutes = ref.watch(savedRoutesProvider);
    final initials = session?.user.email != null
        ? session!.user.email!.substring(0, 1).toUpperCase()
        : 'AR';

    final active = bikes.whenData((list) {
      if (list.isEmpty) return null;
      return list.firstWhere((b) => b.isActive, orElse: () => list.first);
    }).valueOrNull;

    final setupAsync = active == null
        ? const AsyncValue<BikeSetup?>.data(null)
        : ref.watch(currentSetupProvider(active.id));

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
                          list.isEmpty ? 'Garage öffnen' : list.first.name;
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
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
                PopupMenuButton<String>(
                  tooltip: 'Konto',
                  onSelected: (value) {
                    if (value == 'auth') {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AuthScreen(),
                        ),
                      );
                    } else if (value == 'privacy') {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PrivacyScreen(),
                        ),
                      );
                    } else if (value == 'chat') {
                      openChatScreen(context);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'auth', child: Text('Konto')),
                    PopupMenuItem(value: 'chat', child: Text('Chat')),
                    PopupMenuItem(
                      value: 'privacy',
                      child: Text('Daten & Privatsphäre'),
                    ),
                  ],
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
              'Guten Tag',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.forest,
                  ),
            ),
            Text(
              'AetherRide',
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
                        child: Text(
                          top.status == DueStatus.overdue
                              ? 'Wartung fällig: ${top.label}'
                              : 'Bald fällig: ${top.label} (${top.remainingLabel})',
                          style: TextStyle(
                            color: top.status == DueStatus.overdue
                                ? Colors.redAccent
                                : Colors.orange.shade800,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
              ),
            _TipHero(
              setup: setupAsync.valueOrNull,
              saved: savedRoutes.valueOrNull,
            ),
            if (active != null &&
                (active.category == BikeCategory.emtb ||
                    active.category == BikeCategory.etrekking)) ...[
              const SizedBox(height: 12),
              _RangeCard(bike: active, setup: setupAsync.valueOrNull),
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
            const SizedBox(height: 12),
            bikes.when(
              data: (list) => Text(
                list.isEmpty
                    ? 'Lege in der Garage dein erstes Bike an.'
                    : '${list.length} Bike${list.length == 1 ? '' : 's'} bereit',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                    ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipHero extends ConsumerWidget {
  const _TipHero({required this.setup, required this.saved});

  final BikeSetup? setup;
  final List<SavedRouteEntry>? saved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rebound = setup?.valueFor('fork.rebound');
    final setupHint = rebound == null
        ? null
        : 'Gabel Zugstufe: ${rebound.toStringAsFixed(0)} Klicks'
            '${setup != null ? ' · ${setup!.label}' : ''}';

    final route = (saved != null && saved!.isNotEmpty) ? saved!.first : null;
    final title = route?.name ?? HomeScreen._seedTip.title;
    final subtitle = route == null
        ? HomeScreen._seedTip.subtitle
        : '${route.distanceKm.toStringAsFixed(1)} km · '
            '${route.elevationM.round()} hm · ${route.durationMin} min';
    final reason = [
      if (setupHint != null) setupHint,
      if (route != null)
        'Gespeicherte Route · bereit zum Losfahren'
      else if (setupHint == null)
        HomeScreen._seedTip.reason,
    ].join(' · ');

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
          Text(reason, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      ref.read(shellTabIndexProvider.notifier).state = 3,
                  child: const Text('Route ansehen'),
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

class _RangeCard extends StatelessWidget {
  const _RangeCard({required this.bike, this.setup});

  final Bike bike;
  final BikeSetup? setup;

  @override
  Widget build(BuildContext context) {
    final tirePsi = setup?.valueFor('tire_rear.pressure_psi') ?? 24;
    final est = estimateRange(
      category: bike.category,
      tirePressurePsi: tirePsi,
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
          const SizedBox(height: 4),
          Text(
            'Konfidenz: ${est.confidence}'
            '${est.calibrated ? ' · kalibriert' : ''}',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
