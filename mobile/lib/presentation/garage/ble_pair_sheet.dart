import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/sensor/bike_ble_store.dart';
import '../../domain/ble.dart';
import '../../domain/ble/bike_ble_kind.dart';
import '../../domain/ble/manufacturer_live.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../native/ble_core_channel.dart';
import '../../providers/app_providers.dart';
import '../shared/chrome_glyph.dart';

/// Live BLE pairing: Bosch / Shimano / CSC / Power. Open scan, user picks.
/// Sheet chrome mirrors [WatchPairSheet] — one pairing design language.
Future<bool> showBlePairSheet(
  BuildContext context, {
  required String bikeId,
  bool isEbike = false,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (ctx) => BlePairSheet(bikeId: bikeId, isEbike: isEbike),
  );
  return result == true;
}

/// Manage saved wheel / drive without implying the link is live.
Future<String?> showBikeBleManageSheet(
  BuildContext context, {
  required bool hasWheel,
  required bool hasDrive,
  String? wheelName,
  String? driveName,
}) {
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx);
      final driveLabel = (driveName != null && driveName.trim().isNotEmpty)
          ? l10n.bleRemoveDriveNamed(driveName.trim())
          : l10n.bleRemoveDrive;
      final wheelLabel = (wheelName != null && wheelName.trim().isNotEmpty)
          ? l10n.bleRemoveWheelNamed(wheelName.trim())
          : l10n.bleRemoveWheel;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const ChromeGlyph('link', size: 22),
              title: Text(l10n.blePairAgain),
              onTap: () => Navigator.pop(ctx, 'pair'),
            ),
            if (hasWheel)
              ListTile(
                leading: const ChromeGlyph('heat', size: 22),
                title: Text(wheelLabel),
                onTap: () => Navigator.pop(ctx, 'unlinkWheel'),
              ),
            if (hasDrive)
              ListTile(
                leading: const ChromeGlyph('nav', size: 22),
                title: Text(driveLabel),
                onTap: () => Navigator.pop(ctx, 'unlinkDrive'),
              ),
            if (hasWheel && hasDrive)
              ListTile(
                leading: const ChromeGlyph('link', size: 22),
                title: Text(l10n.bleRemoveDevice),
                onTap: () => Navigator.pop(ctx, 'unlinkAll'),
              ),
          ],
        ),
      );
    },
  );
}

class BlePairSheet extends ConsumerStatefulWidget {
  const BlePairSheet({
    super.key,
    required this.bikeId,
    this.isEbike = false,
  });

  final String bikeId;
  final bool isEbike;

  @override
  ConsumerState<BlePairSheet> createState() => _BlePairSheetState();
}

class _BlePairSheetState extends ConsumerState<BlePairSheet> {
  StreamSubscription<List<BikeBleScanHit>>? _sub;
  List<BikeBleScanHit> _hits = const [];
  bool _scanning = false;
  bool _busy = false;
  String? _error;
  String? _pairingId;
  String? _pairStatus;
  BikeBleScanHit? _rememberHit;
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
    unawaited(_ble.stopBikeScan());
    super.dispose();
  }

  Future<void> _start() async {
    if (!mounted) return;
    final ble = _ble;
    setState(() {
      _busy = true;
      _error = null;
      _rememberHit = null;
      _hits = const [];
    });
    try {
      final perm = await ble.ensurePermission();
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
      _sub = ble.bikeScanHits.listen((hits) {
        if (!mounted) return;
        setState(() => _hits = hits);
      });
      await ble.startBikeScan(
        timeout: Duration(seconds: widget.isEbike ? 20 : 14),
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _scanning = true;
      });
    } catch (e) {
      debugPrint('ble pair sheet: $e');
      if (!mounted) return;
      setState(() {
        _busy = false;
        _scanning = false;
        _error = AppLocalizations.of(context).bleScanFailed;
      });
    }
  }

  Future<void> _pair(BikeBleScanHit hit) async {
    if (_pairingId != null) return;
    debugPrint(
      'ble pair: tap ${hit.displayName} kind=${hit.kind.name} id=${hit.deviceId}',
    );
    final ble = _ble;
    final store = _store;
    final bikeId = widget.bikeId;
    setState(() {
      _pairingId = hit.deviceId;
      _pairStatus = AppLocalizations.of(context).bleConnecting;
      _error = null;
      _rememberHit = null;
    });
    try {
      await ble.stopBikeScan();
      if (!mounted) return;
      setState(() => _scanning = false);
      // Samsung GATT 133 if connect is issued in the same tick as stopScan.
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      final ok = await ble.connect(
        deviceId: hit.deviceId,
        scanIfMissing: false,
        kindHint: hit.kind,
        tryLdi: false,
        preferScanDevice: true,
        onProgress: (s) {
          if (!mounted) return;
          setState(() => _pairStatus = s);
        },
      );
      debugPrint(
        'ble pair: connect ok=$ok '
        'status=${ble.statusDetail} last=${ble.lastRemoteId}',
      );
      final next = blePairNextStep(
        connected: ok,
        kind: hit.kind,
        hasLiveMetrics: ble.hasBikeLiveMetrics,
      );
      if (next == BlePairNextStep.tryBoschLdi) {
        if (ok) {
          await store.saveForBike(
            bikeId,
            BikeBleDevice(
              deviceId: blePairDeviceId(
                lastRemoteId: ble.lastRemoteId,
                scanDeviceId: hit.deviceId,
              ),
              name: ble.connectedDeviceName ?? hit.displayName,
              kind: bikeBleKindToStorage(ble.connectedKind ?? hit.kind),
            ),
          );
        }
        setState(() => _pairStatus = 'ldi_waiting_flow');
        final ldiOk = await ble.startLdiAccessory(pairing: true);
        if (ldiOk) {
          await store.saveForBike(
            bikeId,
            BikeBleDevice(
              deviceId: boschLdiAccessoryId,
              name: ble.connectedDeviceName ?? 'Intuvia',
              kind: bikeBleKindToStorage(BikeBleKind.bosch),
            ),
          );
          if (!mounted) return;
          Navigator.of(context).pop(true);
          return;
        }
        if (ok) {
          await _keepScanningForWheel(hit);
          return;
        }
      }
      if (next == BlePairNextStep.done && blePairSheetSuccess(connected: ok)) {
        final id = blePairDeviceId(
          lastRemoteId: ble.lastRemoteId,
          scanDeviceId: hit.deviceId,
        );
        await store.saveForBike(
          bikeId,
          BikeBleDevice(
            deviceId: id,
            name: ble.connectedDeviceName ?? hit.displayName,
            kind: bikeBleKindToStorage(ble.connectedKind ?? hit.kind),
          ),
        );
        if (!mounted) return;
        await Future<void>.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        Navigator.of(context).pop(true);
        return;
      }
      if (next == BlePairNextStep.keepScanningWheel) {
        if (ok || blePairAccepted(connected: false, kind: hit.kind)) {
          await store.saveForBike(
            bikeId,
            BikeBleDevice(
              deviceId: blePairDeviceId(
                lastRemoteId: ble.lastRemoteId,
                scanDeviceId: hit.deviceId,
              ),
              name: ble.connectedDeviceName ?? hit.displayName,
              kind: bikeBleKindToStorage(ble.connectedKind ?? hit.kind),
            ),
          );
        }
        await _keepScanningForWheel(hit);
        return;
      }
      if (!ok) {
        if (!mounted) return;
        setState(() {
          _pairingId = null;
          _pairStatus = null;
          _error = bikeBleKindIsDrive(hit.kind)
              ? AppLocalizations.of(context).bleDriveFailFor(
                  hit.kind,
                  detail: ble.statusDetail,
                )
              : AppLocalizations.of(context).bleStatusDetailFor(
                  ble.statusDetail ??
                      AppLocalizations.of(context).bleConnectFailed,
                );
          _rememberHit =
              blePairAccepted(connected: false, kind: hit.kind) ? hit : null;
        });
        return;
      }
    } catch (e) {
      debugPrint('ble pair: $e');
      if (!mounted) return;
      setState(() {
        _pairingId = null;
        _pairStatus = null;
        _error = bikeBleKindIsDrive(hit.kind)
            ? AppLocalizations.of(context).bleDriveFailFor(hit.kind)
            : AppLocalizations.of(context).blePairFailed;
        _rememberHit =
            blePairAccepted(connected: false, kind: hit.kind) ? hit : null;
      });
    }
  }

  Future<void> _keepScanningForWheel(BikeBleScanHit hit) async {
    if (!mounted) return;
    setState(() {
      _pairingId = null;
      _pairStatus = null;
      _error = AppLocalizations.of(context).bleDriveFailFor(hit.kind);
      _rememberHit = null;
    });
    await _start();
  }

  Future<void> _rememberWithoutGatt(BikeBleScanHit hit) async {
    final ble = _ble;
    final id = blePairDeviceId(
      lastRemoteId: ble.lastRemoteId,
      scanDeviceId: hit.deviceId,
    );
    await _store.saveForBike(
      widget.bikeId,
      BikeBleDevice(
        deviceId: id,
        name: ble.connectedDeviceName ?? hit.displayName,
        kind: bikeBleKindToStorage(ble.connectedKind ?? hit.kind),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _pairBoschLdi() async {
    if (_pairingId != null) return;
    final ble = _ble;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _pairingId = boschLdiAccessoryId;
      _pairStatus = 'ldi_waiting_flow';
      _error = null;
    });
    try {
      await ble.stopBikeScan();
      if (!mounted) return;
      setState(() => _scanning = false);
      final ok = await ble.startLdiAccessory(
        pairing: true,
        onProgress: (s) {
          if (!mounted) return;
          setState(() => _pairStatus = s);
        },
      );
      if (!mounted) return;
      if (ok) {
        await _store.saveForBike(
          widget.bikeId,
          BikeBleDevice(
            deviceId: boschLdiAccessoryId,
            name: ble.connectedDeviceName ?? 'Intuvia',
            kind: bikeBleKindToStorage(BikeBleKind.bosch),
          ),
        );
        if (!mounted) return;
        Navigator.of(context).pop(true);
        return;
      }
      setState(() {
        _pairingId = null;
        _pairStatus = null;
        _error = ble.statusDetail ?? l10n.bleLdiTimeout;
      });
    } catch (e) {
      debugPrint('ble ldi pair: $e');
      if (!mounted) return;
      setState(() {
        _pairingId = null;
        _pairStatus = null;
        _error = l10n.bleLdiTimeout;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final height = MediaQuery.sizeOf(context).height * 0.52;
    final ldiBusy = _pairingId == boschLdiAccessoryId;
    final pairStatus =
        ldiBusy ? (_pairStatus ?? 'ldi_waiting_flow') : _pairStatus;

    return SafeArea(
      child: SizedBox(
        key: const Key('ble-pair-sheet'),
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
                l10n.bleBikeTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.s),
              if (_scanning || _busy || _pairingId != null)
                const LinearProgressIndicator(minHeight: 2),
              if (pairStatus != null) ...[
                const SizedBox(height: AppSpacing.s),
                Text(
                  l10n.bleStatusDetailFor(pairStatus),
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
              if (_rememberHit != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _pairingId != null
                        ? null
                        : () => unawaited(_rememberWithoutGatt(_rememberHit!)),
                    child: Text(l10n.bleRememberAnyway),
                  ),
                ),
              const SizedBox(height: AppSpacing.s),
              Expanded(
                child: _hits.isEmpty && !_busy
                    ? _EmptyScan(
                        scanning: _scanning,
                        isEbike: widget.isEbike,
                      )
                    : ListView(
                        children: [
                          for (final h in _hits)
                            _HitTile(
                              hit: h,
                              pairing: _pairingId == h.deviceId,
                              enabled: _pairingId == null,
                              onTap: () => unawaited(_pair(h)),
                            ),
                        ],
                      ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed:
                        _pairingId != null ? null : () => unawaited(_start()),
                    child: Text(l10n.bleScanAgain),
                  ),
                  TextButton(
                    onPressed: _pairingId != null
                        ? null
                        : () => unawaited(_pairBoschLdi()),
                    child: ldiBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.bleLdiPairCta),
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

class _EmptyScan extends StatelessWidget {
  const _EmptyScan({required this.scanning, required this.isEbike});

  final bool scanning;
  final bool isEbike;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChromeGlyph(
            scanning ? 'bluetooth' : (isEbike ? 'nav' : 'bluetooth'),
            size: 28,
            color: AppColors.muted,
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            scanning ? l10n.bleScanningDrive : l10n.bleNothingFound,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.muted,
            ),
          ),
        ],
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
  });

  final BikeBleScanHit hit;
  final bool pairing;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Material(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.s + 2,
            ),
            child: Row(
              children: [
                ChromeGlyph(
                  bikeBleKindIsDrive(hit.kind) ? 'nav' : 'bluetooth',
                  size: 24,
                  color: enabled ? AppColors.chrome : AppColors.muted,
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Text(
                    l10n.bleScanName(hit),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (pairing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
