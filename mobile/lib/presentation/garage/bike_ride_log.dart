import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/ride.dart';
import '../../domain/ride/ride_telemetry.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../post_ride/post_ride_screen.dart';
import '../ride/ride_elev_sparkline.dart';
import 'garage_chrome.dart';

/// Older rides for this bike. The latest peek lives on Die Box.
class BikeRideLog extends ConsumerWidget {
  const BikeRideLog({
    super.key,
    required this.bikeId,
    this.omitLatestPeek = true,
  });

  final String bikeId;
  final bool omitLatestPeek;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rides =
        ref.watch(recentRidesProvider).valueOrNull ?? const <RideRecord>[];
    final ended = rides
        .where((r) => r.bikeId == bikeId && r.endedAt != null)
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final skip = omitLatestPeek &&
        ended.isNotEmpty &&
        buildRideTelemetry(ended.first.track).hasElev;
    final shown = ended.skip(skip ? 1 : 0).take(5).toList();
    if (shown.isEmpty) return const SizedBox.shrink();

    return Container(
      key: const Key('bike-ride-log'),
      decoration: garageCardDecoration(),
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GarageSectionTitle(label: l10n.garageLastRides, mark: 'stand'),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.garageLastRidesHint,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.s),
          for (final r in shown)
            _RideLogRow(ride: r),
        ],
      ),
    );
  }
}

class _RideLogRow extends StatelessWidget {
  const _RideLogRow({required this.ride});

  final RideRecord ride;

  @override
  Widget build(BuildContext context) {
    final tel = buildRideTelemetry(ride.track);
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PostRideScreen(rideId: ride.id),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              [
                '${ride.distanceKm.toStringAsFixed(1)} km',
                '${(ride.movingTimeSec / 60).toStringAsFixed(0)} min',
                if (ride.elevationM > 0)
                  '${ride.elevationM.toStringAsFixed(0)} hm',
              ].join(' · '),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (tel.hasElev)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: RideTerrainPeek(
                  telemetry: tel,
                  caption: terrainCaption(tel),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
