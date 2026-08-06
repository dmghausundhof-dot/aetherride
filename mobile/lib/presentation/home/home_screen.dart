import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikes = ref.watch(bikesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AetherRide')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'AetherRide',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.forest,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Offline-first Garage, Ride und Routing — natives Sensor-/BLE-Gerüst bereit.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.muted,
                ),
          ),
          const SizedBox(height: 24),
          bikes.when(
            data: (list) => Text(
              list.isEmpty
                  ? 'Keine Bikes in der Garage'
                  : '${list.length} Bike${list.length == 1 ? '' : 's'} in der Garage',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Fehler: $e'),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () =>
                ref.read(shellTabIndexProvider.notifier).state = 2,
            child: const Text('Ride starten'),
          ),
        ],
      ),
    );
  }
}
