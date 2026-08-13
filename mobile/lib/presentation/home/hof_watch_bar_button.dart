import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/sensor/bike_ble_store.dart';
import '../../l10n/app_localizations.dart';
import '../../native/ble_core_channel.dart';
import '../../providers/app_providers.dart';

/// Discreet Hof-bar control for rider watch / HR. Never a hero CTA.
class HofWatchBarButton extends ConsumerStatefulWidget {
  const HofWatchBarButton({super.key});

  @override
  ConsumerState<HofWatchBarButton> createState() => _HofWatchBarButtonState();
}

class _HofWatchBarButtonState extends ConsumerState<HofWatchBarButton> {
  BikeBleDevice? _saved;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  Future<void> _reload() async {
    try {
      final d = await ref.read(bikeBleStoreProvider).savedWatch();
      if (mounted) setState(() => _saved = d);
    } catch (_) {}
  }

  Future<void> _pair() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ble = ref.read(bleCoreProvider);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final perm = await ble.ensurePermission();
      if (!mounted) return;
      if (perm == BlePermissionResult.adapterOff) {
        messenger?.showSnackBar(
          const SnackBar(content: Text('Bluetooth ist aus')),
        );
        return;
      }
      if (perm == BlePermissionResult.denied) {
        messenger?.showSnackBar(
          const SnackBar(content: Text('Bluetooth-Berechtigung fehlt')),
        );
        return;
      }
      if (perm == BlePermissionResult.unsupported) {
        messenger?.showSnackBar(
          const SnackBar(content: Text('Bluetooth nicht verfügbar')),
        );
        return;
      }
      final ok = await ble.connectWatch(deviceId: _saved?.deviceId);
      if (!mounted) return;
      if (!ok) {
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              ble.watchStatusDetail ??
                  'Keine Uhr mit Standard-Puls-Service in Reichweite',
            ),
          ),
        );
        return;
      }
      final id = ble.lastWatchRemoteId;
      if (id != null && id.isNotEmpty) {
        await ref.read(bikeBleStoreProvider).saveWatch(
              BikeBleDevice(deviceId: id, name: ble.connectedWatchName),
            );
      }
      await _reload();
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            ble.connectedWatchName != null
                ? 'Gekoppelt: ${ble.connectedWatchName}'
                : 'Uhr gekoppelt',
          ),
        ),
      );
    } catch (_) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Kopplung fehlgeschlagen')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlink() async {
    await ref.read(bikeBleStoreProvider).removeWatch();
    try {
      await ref.read(bleCoreProvider).disconnectWatch();
    } catch (_) {}
    await _reload();
  }

  Future<void> _onTap() async {
    if (_busy) return;
    if (_saved == null) {
      await _pair();
      return;
    }
    final l10n = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: Text(l10n.hofWatchReconnect),
              onTap: () => Navigator.pop(ctx, 'pair'),
            ),
            ListTile(
              leading: const Icon(Icons.link_off),
              title: Text(l10n.hofWatchRemove),
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
    final l10n = AppLocalizations.of(context);
    final connected = _saved != null;
    return Semantics(
      button: true,
      label: connected ? '${l10n.hofYourWatch} · gekoppelt' : l10n.hofWatchPair,
      child: Tooltip(
        message: connected ? l10n.hofYourWatch : l10n.hofWatchPair,
        child: InkWell(
          key: const Key('hof-watch-bar'),
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
                        Icons.watch_outlined,
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
