import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/sensor/bike_ble_store.dart';
import '../../domain/ble.dart';
import '../../domain/ble/bike_ble_kind.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../native/ble_core_channel.dart';
import '../../providers/app_providers.dart';

/// Live BLE pairing: Bosch / Shimano / CSC / Power. Open scan, user picks.
Future<bool> showBlePairSheet(
  BuildContext context, {
  required String bikeId,
  bool isEbike = false,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
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
}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: Text(l10n.blePairAgain),
              onTap: () => Navigator.pop(ctx, 'pair'),
            ),
            if (hasWheel)
              ListTile(
                leading: const Icon(Icons.speed),
                title: Text(l10n.bleRemoveWheel),
                onTap: () => Navigator.pop(ctx, 'unlinkWheel'),
              ),
            if (hasDrive)
              ListTile(
                leading: const Icon(Icons.electric_bike),
                title: Text(l10n.bleRemoveDrive),
                onTap: () => Navigator.pop(ctx, 'unlinkDrive'),
              ),
            if (hasWheel && hasDrive)
              ListTile(
                leading: const Icon(Icons.link_off),
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
  bool _guideOpen = false;
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
      if (blePairSheetSuccess(connected: ok)) {
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
      if (!ok && hit.kind == BikeBleKind.bosch) {
        setState(() => _pairStatus = 'ldi_waiting_flow');
        final ldiOk = await ble.startLdiAccessory(pairing: true);
        if (ldiOk) {
          await store.saveForBike(
            bikeId,
            BikeBleDevice(
              deviceId: boschLdiAccessoryId,
              name: 'Bosch LDI',
              kind: bikeBleKindToStorage(BikeBleKind.bosch),
            ),
          );
          if (!mounted) return;
          Navigator.of(context).pop(true);
          return;
        }
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
            name: 'Bosch LDI',
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
    final height = MediaQuery.sizeOf(context).height * 0.78;
    final drives = _hits.where((h) => bikeBleKindIsDrive(h.kind)).toList();
    final sensors = _hits.where((h) => !bikeBleKindIsDrive(h.kind)).toList();

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
                l10n.bleBikeTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.blePairLeadFor(isEbike: widget.isEbike),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: AppSpacing.s),
              if (widget.isEbike)
                OutlinedButton(
                  onPressed: _pairingId != null ? null : () => unawaited(_pairBoschLdi()),
                  child: Text(l10n.bleLdiPairCta),
                ),
              if (widget.isEbike) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.bleLdiPairHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        height: 1.35,
                      ),
                ),
              ],
              const SizedBox(height: AppSpacing.s),
              _HowToConnect(
                isEbike: widget.isEbike,
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
              if (_rememberHit != null) ...[
                const SizedBox(height: AppSpacing.s),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _pairingId != null
                        ? null
                        : () => unawaited(_rememberWithoutGatt(_rememberHit!)),
                    child: Text(l10n.bleRememberAnyway),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.s),
              Expanded(
                child: _hits.isEmpty && !_busy
                    ? _EmptyScan(scanning: _scanning, isEbike: widget.isEbike)
                    : ListView(
                        children: [
                          if (drives.isNotEmpty) ...[
                            _SectionLabel(l10n.bleSectionDrive),
                            for (final h in drives)
                              _HitTile(
                                hit: h,
                                pairing: _pairingId == h.deviceId,
                                pairingLabel: _pairingId == h.deviceId
                                    ? _pairStatus
                                    : null,
                                enabled: _pairingId == null,
                                onTap: () => unawaited(_pair(h)),
                              ),
                            const SizedBox(height: AppSpacing.m),
                          ],
                          if (sensors.isNotEmpty) ...[
                            _SectionLabel(l10n.bleSectionSensors),
                            for (final h in sensors)
                              _HitTile(
                                hit: h,
                                pairing: _pairingId == h.deviceId,
                                pairingLabel: _pairingId == h.deviceId
                                    ? _pairStatus
                                    : null,
                                enabled: _pairingId == null,
                                onTap: () => unawaited(_pair(h)),
                              ),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                l10n.bleBikeHint,
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
    required this.isEbike,
    required this.open,
    required this.toggleable,
    required this.onToggle,
  });

  final bool isEbike;
  final bool open;
  final bool toggleable;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final notes = AppLocalizations.of(context).bleConnectNotesFor(
      isEbike: isEbike,
    );
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
                    Icons.bluetooth,
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
                    _ConnectNoteRow(brand: notes[i].brand, line: notes[i].line),
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

class _ConnectNoteRow extends StatelessWidget {
  const _ConnectNoteRow({required this.brand, required this.line});

  final String brand;
  final String line;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            brand,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: AppColors.chrome,
            ),
          ),
        ),
        Expanded(
          child: Text(
            line,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              color: AppColors.muted,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s, top: AppSpacing.xs),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              scanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
              size: 36,
              color: AppColors.muted,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              scanning ? l10n.bleScanningDrive : l10n.bleNothingFound,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              isEbike ? l10n.bleEmptyEbike : l10n.bleEmptySensor,
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

  final BikeBleScanHit hit;
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
                  bikeBleKindIsDrive(hit.kind)
                      ? Icons.electric_bike
                      : Icons.sensors,
                  color: AppColors.chrome,
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.bleScanName(hit),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          l10n.bleKindLabel(hit.kind),
                          if (hit.caps.contains(BikeBleCap.csc)) 'CSC',
                          if (hit.caps.contains(BikeBleCap.power)) 'Power',
                          if (hit.caps.contains(BikeBleCap.battery))
                            l10n.rideBatteryChip,
                          '$rssi dBm',
                        ].join(' · '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                      if (bikeBleKindIsDrive(hit.kind) ||
                          hit.kind == BikeBleKind.csc ||
                          hit.kind == BikeBleKind.power) ...[
                        const SizedBox(height: 2),
                        Text(
                          l10n.bleConnectTipFor(hit.kind),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                            height: 1.3,
                          ),
                        ),
                      ],
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
