import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/routing/connectivity_chip.dart';

/// Honest mid-ride connectivity / offline trust chip (N-03 / N-08).
class RideConnectivityChip extends StatelessWidget {
  const RideConnectivityChip({
    super.key,
    required this.state,
    this.compact = false,
  });

  final ConnectivityChipState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = connectivityChipLabel(state);
    final (bg, fg, icon) = switch (state) {
      ConnectivityChipState.live => (
          Colors.green.shade50,
          Colors.green.shade900,
          Icons.cloud_done_outlined,
        ),
      ConnectivityChipState.routeOffline => (
          Colors.teal.shade50,
          Colors.teal.shade900,
          Icons.offline_pin_outlined,
        ),
      ConnectivityChipState.offlineMapOk => (
          Colors.amber.shade50,
          Colors.amber.shade900,
          Icons.wifi_off_outlined,
        ),
      ConnectivityChipState.mapsMissing => (
          Colors.orange.shade100,
          Colors.orange.shade900,
          Icons.map_outlined,
        ),
    };

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 4 : 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 14 : 16, color: fg),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
