import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/sensor/bike_ble_store.dart';
import '../../domain/ble.dart';
import '../../l10n/app_localizations.dart';
import '../../native/ble_core_channel.dart';
import '../../providers/app_providers.dart';
import 'watch_pair_sheet.dart';

/// Rider-level watch / HR strap. Lives on Der Hof — never on a bike record.
/// Same BLE Heart Rate 0x180D path as `BleCoreChannel.connectWatch`.
class HofWatchCard extends ConsumerStatefulWidget {
  const HofWatchCard({
    super.key,
    this.compact = false,
    this.dense = false,
  });

  /// Ride HUD / Karte: small “Uhr verbinden” if not connected.
  final bool compact;

  /// Phone landscape: one row so pair stays above the nav.
  final bool dense;

  @override
  ConsumerState<HofWatchCard> createState() => _HofWatchCardState();
}

class _HofWatchCardState extends ConsumerState<HofWatchCard> {
  BikeBleDevice? _saved;
  bool _busy = false;
  String? _status;
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
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final ok = await showWatchPairSheet(context);
      await _reload();
      if (!mounted) return;
      if (ok) {
        final ble = ref.read(bleCoreProvider);
        setState(() {
          _status = ble.watchStatusDetail ??
              (ble.connectedWatchName != null
                  ? 'Gekoppelt: ${ble.connectedWatchName}'
                  : 'Uhr gekoppelt');
        });
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Kopplung fehlgeschlagen');
      debugPrint('hof watch pair: $e');
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
    setState(() {
      _busy = true;
      _status = 'Verbinde …';
    });
    final ble = ref.read(bleCoreProvider);
    try {
      final perm = await ble.ensurePermission();
      if (!mounted) return;
      if (perm != BlePermissionResult.granted) {
        setState(() => _status = ble.watchStatusDetail ?? 'Bluetooth prüfen');
        return;
      }
      final ok = await ble.connectWatch(
        deviceId: saved.deviceId,
        scanIfMissing: true,
      );
      if (!mounted) return;
      setState(() {
        _status = ok
            ? (ble.watchStatusDetail ?? 'Uhr verbunden')
            : (ble.watchStatusDetail ?? 'Uhr nicht in Reichweite');
      });
    } catch (e) {
      if (mounted) setState(() => _status = 'Verbindung fehlgeschlagen');
      debugPrint('hof watch reconnect: $e');
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
    if (mounted) setState(() => _status = 'Uhr entfernt');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ble = ref.read(bleCoreProvider);
    if (widget.compact) {
      if (ble.isWatchConnected) return const SizedBox.shrink();
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: const Key('hof-watch-connect'),
          onPressed: _busy
              ? null
              : () => unawaited(_saved == null ? _pair() : _reconnect()),
          icon: _busy
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.watch_outlined, size: 18),
          label: Text(l10n.hofWatchConnect),
        ),
      );
    }

    final name = _saved?.name?.trim();
    final live = ble.isWatchConnected;
    final bpm = ble.heartRateBpm;
    final subtitle = _saved == null
        ? l10n.hofWatchHint
        : live
            ? (ble.watchStatusDetail ??
                (bpm != null
                    ? '${name ?? 'Uhr'} · ${bpm.round()} bpm'
                    : '${name ?? 'Uhr'} · live'))
            : (name != null && name.isNotEmpty
                ? '$name · gemerkt, nicht live'
                : 'Gemerkt, nicht live');
    final liveColor =
        live ? AppColors.forestOnDark : AppColors.muted;

    if (widget.dense) {
      return Material(
        key: const Key('hof-watch'),
        color: Colors.transparent,
        child: InkWell(
          onTap: _busy
              ? null
              : () => unawaited(_saved == null ? _pair() : _reconnect()),
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.watch_outlined,
                  size: 18,
                  color: liveColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.hofYourWatch,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_busy)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      key: const Key('hof-watch'),
      color: Colors.transparent,
      child: InkWell(
        onTap: _busy
            ? null
            : () => unawaited(_saved == null ? _pair() : _reconnect()),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.hofYourWatch,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              if (_status != null) ...[
                const SizedBox(height: 2),
                Text(
                  _status!,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
              if (_saved != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _busy ? null : () => unawaited(_unlink()),
                    child: Text(l10n.hofWatchRemove),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
