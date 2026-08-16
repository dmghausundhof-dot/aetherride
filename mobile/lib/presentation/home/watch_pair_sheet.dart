import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/sensor/bike_ble_store.dart';
import '../../domain/ble/watch_candidate.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../native/ble_core_channel.dart';
import '../../providers/app_providers.dart';

Future<bool> showWatchPairSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => const WatchPairSheet(),
  );
  return result == true;
}

class WatchPairSheet extends ConsumerStatefulWidget {
  const WatchPairSheet({super.key});

  @override
  ConsumerState<WatchPairSheet> createState() => _WatchPairSheetState();
}

class _WatchPairSheetState extends ConsumerState<WatchPairSheet> {
  StreamSubscription<List<WatchBleScanHit>>? _sub;
  List<WatchBleScanHit> _hits = const [];
  bool _scanning = false;
  bool _busy = false;
  bool _guideOpen = false;
  String? _error;
  String? _pairingId;
  String? _pairStatus;
  late final BleCoreChannel _ble;
  late final BikeBleStore _store;

  @override
  void initState() {
    super.initState();
    _ble = ref.read(bleCoreProvider);
    _store = ref.read(bikeBleStoreProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_start());
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    unawaited(_ble.stopWatchScan());
    super.dispose();
  }

  Future<void> _start() async {
    if (!mounted) return;
    setState(() {
      _busy = true;
      _error = null;
      _hits = const [];
    });
    try {
      final perm = await _ble.ensurePermission();
      if (!mounted) return;
      if (perm == BlePermissionResult.adapterOff) {
        setState(() {
          _busy = false;
          _error = AppLocalizations.of(context).bleOff;
        });
        return;
      }
      if (perm == BlePermissionResult.denied) {
        setState(() {
          _busy = false;
          _error = AppLocalizations.of(context).bleDenied;
        });
        return;
      }
      if (perm == BlePermissionResult.unsupported) {
        setState(() {
          _busy = false;
          _error = AppLocalizations.of(context).bleUnavailable;
        });
        return;
      }

      await _sub?.cancel();
      _sub = _ble.watchScanHits.listen((hits) {
        if (!mounted) return;
        setState(() => _hits = hits);
      });
      await _ble.startWatchScan();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _scanning = true;
      });
    } catch (e) {
      debugPrint('watch pair sheet: $e');
      if (!mounted) return;
      setState(() {
        _busy = false;
        _scanning = false;
        _error = AppLocalizations.of(context).bleScanFailed;
      });
    }
  }

  Future<void> _pair(WatchBleScanHit hit) async {
    if (_pairingId != null) return;
    if (!hit.pairable) {
      setState(() {
        _error = AppLocalizations.of(context).watchConnectTipFor(hit.honesty);
      });
      return;
    }
    setState(() {
      _pairingId = hit.deviceId;
      _pairStatus = AppLocalizations.of(context).bleConnecting;
      _error = null;
    });
    try {
      await _ble.stopWatchScan();
      if (!mounted) return;
      setState(() => _scanning = false);
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      final ok = await _ble.connectWatch(
        deviceId: hit.deviceId,
        scanIfMissing: false,
      );
      debugPrint(
        'watch pair: ok=$ok status=${_ble.watchStatusDetail} '
        'hr=${_ble.heartRateBpm}',
      );
      if (!ok) {
        if (!mounted) return;
        setState(() {
          _pairingId = null;
          _pairStatus = null;
          _error = AppLocalizations.of(context).bleStatusDetailFor(
            _ble.watchStatusDetail ?? AppLocalizations.of(context).watchNoHr,
          );
        });
        return;
      }
      final id = _ble.lastWatchRemoteId;
      if (id == null || id.isEmpty) {
        if (!mounted) return;
        setState(() {
          _pairingId = null;
          _pairStatus = null;
          _error = AppLocalizations.of(context).watchNoDeviceId;
        });
        return;
      }
      await _store.saveWatch(
        BikeBleDevice(
          deviceId: id,
          name: _ble.connectedWatchName ?? hit.displayName,
        ),
      );
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('watch pair: $e');
      if (!mounted) return;
      setState(() {
        _pairingId = null;
        _pairStatus = null;
        _error = AppLocalizations.of(context).blePairFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final height = MediaQuery.sizeOf(context).height * 0.78;
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            0,
            AppSpacing.l,
            AppSpacing.l,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.watchPairTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.watchPairLeadText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: AppSpacing.s),
              _HowToConnect(
                open: _hits.isEmpty || _guideOpen,
                toggleable: _hits.isNotEmpty,
                onToggle: () => setState(() => _guideOpen = !_guideOpen),
              ),
              const SizedBox(height: AppSpacing.m),
              if (_scanning || _busy || _pairingId != null)
                const LinearProgressIndicator(minHeight: 2),
              if (_pairStatus != null) ...[
                const SizedBox(height: AppSpacing.s),
                Text(
                  l10n.bleStatusDetailFor(_pairStatus!),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.s),
                Text(
                  l10n.bleStatusDetailFor(_error!),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.s),
              Expanded(
                child: _hits.isEmpty && !_busy
                    ? _EmptyScan(scanning: _scanning)
                    : ListView(
                        children: [
                          for (final h in _hits)
                            _HitTile(
                              hit: h,
                              pairing: _pairingId == h.deviceId,
                              pairingLabel:
                                  _pairingId == h.deviceId ? _pairStatus : null,
                              enabled: _pairingId == null && h.pairable,
                              onTap: () => unawaited(_pair(h)),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                l10n.watchPairHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: AppSpacing.s),
              Row(
                children: [
                  TextButton(
                    onPressed:
                        _pairingId != null ? null : () => unawaited(_start()),
                    child: Text(l10n.bleScanAgain),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.cancel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowToConnect extends StatelessWidget {
  const _HowToConnect({
    required this.open,
    required this.toggleable,
    required this.onToggle,
  });

  final bool open;
  final bool toggleable;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final notes = AppLocalizations.of(context).watchConnectNotesFor();
    return Material(
      color: AppColors.chipIdle,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: toggleable ? onToggle : null,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.s,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.watch_outlined,
                    size: 16,
                    color: AppColors.chrome.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).bleHowTo,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  if (toggleable)
                    Icon(
                      open
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.muted,
                    ),
                ],
              ),
            ),
          ),
          if (open) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                AppSpacing.s,
                AppSpacing.m,
                AppSpacing.m,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < notes.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.s),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 108,
                          child: Text(
                            notes[i].brand,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                              color: AppColors.chrome,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            notes[i].line,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyScan extends StatelessWidget {
  const _EmptyScan({required this.scanning});

  final bool scanning;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              scanning ? Icons.bluetooth_searching : Icons.watch_off_outlined,
              size: 36,
              color: AppColors.muted,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              scanning ? l10n.watchScanning : l10n.bleNothingFound,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              l10n.watchEmptyHint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                height: 1.4,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HitTile extends StatelessWidget {
  const _HitTile({
    required this.hit,
    required this.pairing,
    required this.enabled,
    required this.onTap,
    this.pairingLabel,
  });

  final WatchBleScanHit hit;
  final bool pairing;
  final bool enabled;
  final VoidCallback onTap;
  final String? pairingLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rssi = hit.rssi;
    final bars = rssi >= -60
        ? 3
        : rssi >= -75
            ? 2
            : 1;
    final blocked =
        hit.honesty == WatchHonesty.appleUnsupported && !hit.hasHrService;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Material(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Row(
              children: [
                Icon(
                  Icons.watch_outlined,
                  color: blocked ? AppColors.muted : AppColors.chrome,
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.watchScanName(hit),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          l10n.watchHonestyLabelFor(hit.honesty),
                          if (hit.hasHrService) '0x180D',
                          '$rssi dBm',
                        ].join(' · '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.watchConnectTipFor(hit.honesty),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                          height: 1.3,
                        ),
                      ),
                      if (pairing && pairingLabel != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          l10n.bleStatusDetailFor(pairingLabel!),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (pairing)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Container(
                            width: 3,
                            height: 6.0 + i * 4,
                            decoration: BoxDecoration(
                              color: i < bars
                                  ? AppColors.chrome
                                  : AppColors.border,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
