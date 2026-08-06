import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/bike.dart';
import '../../providers/app_providers.dart';

class GarageScreen extends ConsumerWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikes = ref.watch(bikesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Garage')),
      body: bikes.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Garage ist leer'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _BikeTile(bike: list[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
      ),
    );
  }
}

class _BikeTile extends StatelessWidget {
  const _BikeTile({required this.bike});

  final Bike bike;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      leading: const Icon(Icons.pedal_bike),
      title: Text(bike.name),
      subtitle: Text(
        [
          if (bike.brand != null) bike.brand!,
          if (bike.model != null) bike.model!,
          '${bike.odometerKm.toStringAsFixed(0)} km',
        ].join(' · '),
      ),
      trailing: Text(
        bike.category.name,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
