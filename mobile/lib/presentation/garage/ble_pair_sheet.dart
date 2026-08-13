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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_start());
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    unawaited(ref.read(bleCoreProvider).stopBikeScan());
    super.dispose();
  }

  Future<void> _start() async {
    final ble = ref.read(bleCoreProvider);
    setState(() {
      _busy = true;
      _error = null;
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
      await ble.startBikeScan();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _scanning = true;
      });
    } catch (e) {
      debugPrint('ble pair sheet: $e');
      if (mounted) {
        setState(() {
          _busy = false;
          _scanning = false;
          _error = 'Suche fehlgeschlagen';
        });
      }
    }
  }

  Future<void> _pair(BikeBleScanHit hit) async {
    if (_pairingId != null) return;
    final ble = ref.read(bleCoreProvider);
    setState(() {
      _pairingId = hit.deviceId;
      _error = null;
    });
    try {
      await ble.stopBikeScan();
      if (mounted) setState(() => _scanning = false);
      final ok = await ble.connect(
        deviceId: hit.deviceId,
        scanIfMissing: false,
        kindHint: hit.kind,
      );
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _pairingId = null;
          _error = ble.statusDetail ?? 'Verbindung fehlgeschlagen';
        });
        unawaited(_start());
        return;
      }
      final id = ble.lastRemoteId;
      if (id == null || id.isEmpty) {
        setState(() {
          _pairingId = null;
          _error = 'Verbunden, aber ohne Geräte-ID';
        });
        return;
      }
      await ref.read(bikeBleStoreProvider).saveForBike(
            widget.bikeId,
            BikeBleDevice(
              deviceId: id,
              name: ble.connectedDeviceName ?? hit.displayName,
              kind: bikeBleKindToStorage(ble.connectedKind ?? hit.kind),
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('ble pair: $e');
      if (mounted) {
        setState(() {
          _pairingId = null;
          _error = 'Kopplung fehlgeschlagen';
        });
      }
    }
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
                widget.isEbike
                    ? 'Display am Rad einschalten. Bosch Smart System erscheint oft als „SMART SYSTEM EBIKE“, Shimano als SC-E… / STEPS.'
                    : 'Radsensor am Rad, nicht am Fahrer. CSC und Powermeter erscheinen hier.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: AppSpacing.m),
              if (_scanning || _busy)
                const LinearProgressIndicator(minHeight: 2),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.s),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFFF8A80),
                    fontSize: 13,
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
                            for (final h in drives) _HitTile(
                              hit: h,
                              pairing: _pairingId == h.deviceId,
                              enabled: _pairingId == null,
                              onTap: () => unawaited(_pair(h)),
                            ),
                            const SizedBox(height: AppSpacing.m),
                          ],
                          if (sensors.isNotEmpty) ...[
                            const _SectionLabel('Sensoren'),
                            for (final h in sensors) _HitTile(
                              hit: h,
                              pairing: _pairingId == h.deviceId,
                              enabled: _pairingId == null,
                              onTap: () => unawaited(_pair(h)),
                            ),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Bosch-LDI und Shimano E-TUBE sind herstellereigen. Wir erkennen das System. Akku nur bei echtem Battery-GATT (0x180F) — kein erfundenes SoC.',
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
                  ? 'Rad einschalten, Display wecken, Handy nah halten. Flow/E-TUBE parallel schließen — viele Systeme erlauben nur eine BLE-Verbindung.'
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
  });

  final BikeBleScanHit hit;
  final bool pairing;
  final bool enabled;
  final VoidCallback onTap;

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
