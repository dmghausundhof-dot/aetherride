import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/sensor/bike_ble_store.dart';
import '../../domain/ble.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../native/ble_core_channel.dart';
import '../../providers/app_providers.dart';
import 'watch_pair_sheet.dart';

/// Discreet Hof-bar control for rider watch / HR. Never a hero CTA.
class HofWatchBarButton extends ConsumerStatefulWidget {
  const HofWatchBarButton({super.key});

  @override
  ConsumerState<HofWatchBarButton> createState() => _HofWatchBarButtonState();
}

class _HofWatchBarButtonState extends ConsumerState<HofWatchBarButton> {
  BikeBleDevice? _saved;
  bool _busy = false;
  StreamSubscription<BoschLiveData>? _liveSub;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
    _liveSub = ref.read(bleCoreProvider).liveData.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    unawaited(_liveSub?.cancel());
    super.dispose();
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
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final ok = await showWatchPairSheet(context);
      await _reload();
      if (!mounted) return;
      if (ok) {
        final ble = ref.read(bleCoreProvider);
        final l10n = AppLocalizations.of(context);
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              ble.connectedWatchName != null
                  ? l10n.garageBlePairedNamed(ble.connectedWatchName!)
                  : l10n.garageBlePaired,
            ),
          ),
        );
      }
    } catch (_) {
      messenger?.showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).blePairFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reconnect() async {
    if (_busy) return;
    final saved = _saved;
    if (saved == null) {
      await _pair();
      return;
    }
    setState(() => _busy = true);
    final ble = ref.read(bleCoreProvider);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final perm = await ble.ensurePermission();
      if (!mounted) return;
      if (perm != BlePermissionResult.granted) {
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).bleStatusDetailFor(
                ble.watchStatusDetail ??
                    AppLocalizations.of(context).watchCheckBluetooth,
              ),
            ),
          ),
        );
        return;
      }
      final ok = await ble.connectWatch(
        deviceId: saved.deviceId,
        scanIfMissing: true,
      );
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).bleStatusDetailFor(
              ok
                  ? (ble.watchStatusDetail ??
                      AppLocalizations.of(context).bleConnectedNamed(
                        AppLocalizations.of(context).bleWordWatch,
                      ))
                  : (ble.watchStatusDetail ??
                      AppLocalizations.of(context).watchOutOfRange),
            ),
          ),
        ),
      );
    } catch (_) {
      messenger?.showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).bleConnectFailed)),
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
              onTap: () => Navigator.pop(ctx, 'reconnect'),
            ),
            ListTile(
              leading: const Icon(Icons.watch_outlined),
              title: Text(l10n.watchOtherWatch),
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
    if (choice == 'reconnect') await _reconnect();
    if (choice == 'unlink') await _unlink();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final live = ref.read(bleCoreProvider).isWatchConnected;
    final saved = _saved != null;
    return Semantics(
      button: true,
      label: live
          ? l10n.watchLiveNamed(l10n.hofYourWatch)
          : saved
              ? l10n.watchRememberedOffline(l10n.hofYourWatch)
              : l10n.hofWatchPair,
      child: Tooltip(
        message: live
            ? l10n.hofYourWatch
            : saved
                ? l10n.hofWatchReconnect
                : l10n.hofWatchPair,
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
                        color: live
                            ? AppColors.chrome
                            : AppColors.muted,
                      ),
                      if (live)
                        Positioned(
                          right: -1,
                          top: -1,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.chrome,
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
