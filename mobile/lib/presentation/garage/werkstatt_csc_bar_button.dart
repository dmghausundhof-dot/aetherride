import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/sensor/bike_ble_store.dart';
import '../../providers/app_providers.dart';
import 'ble_pair_sheet.dart';

/// Discreet Werkstatt-bar control for the bike CSC. Never a hero CTA.
class WerkstattCscBarButton extends ConsumerStatefulWidget {
  const WerkstattCscBarButton({
    super.key,
    required this.bikeId,
    this.isEbike = false,
  });

  final String bikeId;
  final bool isEbike;

  @override
  ConsumerState<WerkstattCscBarButton> createState() =>
      _WerkstattCscBarButtonState();
}

class _WerkstattCscBarButtonState extends ConsumerState<WerkstattCscBarButton> {
  BikeBleDevice? _saved;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  @override
  void didUpdateWidget(covariant WerkstattCscBarButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bikeId != widget.bikeId) unawaited(_reload());
  }

  Future<void> _reload() async {
    final d = await ref.read(bikeBleStoreProvider).deviceForBike(widget.bikeId);
    if (mounted) setState(() => _saved = d);
  }

  Future<void> _pair() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final ok = await showBlePairSheet(
        context,
        bikeId: widget.bikeId,
        isEbike: widget.isEbike,
      );
      await _reload();
      if (!mounted) return;
      if (ok) {
        final ble = ref.read(bleCoreProvider);
        final name = ble.connectedDeviceName ?? _saved?.name;
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              name != null && name.isNotEmpty
                  ? 'Gekoppelt: $name'
                  : 'Gerät gekoppelt',
            ),
          ),
        );
      }
    } catch (_) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Kopplung fehlgeschlagen')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlink() async {
    await ref.read(bikeBleStoreProvider).removeForBike(widget.bikeId);
    try {
      await ref.read(bleCoreProvider).disconnectCsc();
    } catch (_) {}
    await _reload();
  }

  Future<void> _onTap() async {
    if (_busy) return;
    if (_saved == null) {
      await _pair();
      return;
    }
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Neu koppeln'),
              onTap: () => Navigator.pop(ctx, 'pair'),
            ),
            ListTile(
              leading: const Icon(Icons.link_off),
              title: const Text('Gerät entfernen'),
              onTap: () => Navigator.pop(ctx, 'unlink'),
            ),
          ],
        ),
      ),
    );
    if (choice == 'pair') await _pair();
    if (choice == 'unlink') await _unlink();
  }

  @override
  Widget build(BuildContext context) {
    final connected = _saved != null;
    return Semantics(
      button: true,
      label: connected ? 'Bluetooth gekoppelt' : 'Bluetooth koppeln',
      child: Tooltip(
        message: connected
            ? (_saved?.name ?? 'Bluetooth gekoppelt')
            : 'Antrieb oder Sensor koppeln',
        child: InkWell(
          key: const Key('werkstatt-csc-bar'),
          onTap: _busy ? null : () => unawaited(_onTap()),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.bluetooth,
                        size: 22,
                        color: connected
                            ? AppColors.forestOnDark
                            : AppColors.muted,
                      ),
                      if (connected)
                        Positioned(
                          right: -1,
                          top: -1,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.forestOnDark,
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
