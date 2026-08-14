import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/sensor/bike_ble_store.dart';
import '../../domain/ble/bike_ble_kind.dart';
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
          _error = 'Bluetooth ist aus — bitte einschalten.';
        });
        return;
      }
      if (perm == BlePermissionResult.denied) {
        setState(() {
          _busy = false;
          _error = 'Bluetooth-Berechtigung fehlt.';
        });
        return;
      }
      if (perm == BlePermissionResult.unsupported) {
        setState(() {
          _busy = false;
          _error = 'Bluetooth LE ist auf diesem Gerät nicht verfügbar.';
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
        _error = 'Suche fehlgeschlagen';
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
      _pairStatus = 'Verbinde …';
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
      if (!mounted) return;
      setState(() {
        _pairingId = null;
        _pairStatus = null;
        _error = ble.statusDetail ?? 'Verbindung fehlgeschlagen';
        _rememberHit =
            blePairAccepted(connected: false, kind: hit.kind) ? hit : null;
      });
    } catch (e) {
      debugPrint('ble pair: $e');
      if (!mounted) return;
      setState(() {
        _pairingId = null;
        _pairStatus = null;
        _error = 'Kopplung fehlgeschlagen';
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

  @override
  Widget build(BuildContext context) {
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
                'Rad koppeln',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                bikeBlePairLead(isEbike: widget.isEbike),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                      height: 1.35,
                    ),
              ),
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
                  _pairStatus!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.s),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFFF8A80),
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
                    child: const Text('Trotzdem merken'),
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
                            const _SectionLabel('Antrieb'),
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
                            const _SectionLabel('Sensoren'),
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
                'Akku und Assist nur bei echtem GATT — nichts erfinden.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: AppSpacing.s),
              Row(
                children: [
                  TextButton(
                    onPressed: _pairingId != null
                        ? null
                        : () => unawaited(_start()),
                    child: const Text('Erneut suchen'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Abbrechen'),
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
    final notes = bikeBleConnectNotes(isEbike: isEbike);
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
                    color: AppColors.forestOnDark.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  const Expanded(
                    child: Text(
                      'So verbindest du',
                      style: TextStyle(
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
                    _ConnectNoteRow(note: notes[i]),
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
  const _ConnectNoteRow({required this.note});

  final BikeBleConnectNote note;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            note.brand,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: AppColors.forestOnDark,
            ),
          ),
        ),
        Expanded(
          child: Text(
            note.line,
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
              scanning
                  ? 'Suche Antrieb und Sensoren …'
                  : 'Nichts gefunden',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              isEbike
                  ? 'Display wecken, Flow oder E-TUBE zu, Handy nah halten.'
                  : 'Sensor in die Nähe legen und am Rad aktivieren (Magnet/Kurbel).',
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
                  color: AppColors.forestOnDark,
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hit.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          bikeBleKindLabel(hit.kind),
                          if (hit.caps.contains(BikeBleCap.csc)) 'CSC',
                          if (hit.caps.contains(BikeBleCap.power)) 'Power',
                          if (hit.caps.contains(BikeBleCap.battery)) 'Akku',
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
                          bikeBleConnectTip(hit.kind),
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
                          pairingLabel!,
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
                                  ? AppColors.forestOnDark
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
