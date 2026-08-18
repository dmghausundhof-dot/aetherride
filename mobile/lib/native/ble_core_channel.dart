import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../domain/ble.dart';
import '../domain/ble/bike_ble_kind.dart';
import '../domain/ble/ble_link_status.dart';
import '../domain/ble/csc_measurement.dart';
import '../domain/ble/gatt_sensors.dart';
import '../domain/ble/manufacturer_ble.dart';
import '../domain/ble/watch_candidate.dart';
import 'native_channels.dart';

enum BlePermissionResult {
  granted,
  adapterOff,
  denied,
  unsupported,
}

final _cscServiceGuid = Guid('00001816-0000-1000-8000-00805f9b34fb');
final _hrServiceGuid = Guid('0000180d-0000-1000-8000-00805f9b34fb');
final _powerServiceGuid = Guid('00001818-0000-1000-8000-00805f9b34fb');
final _batteryServiceGuid = Guid('0000180f-0000-1000-8000-00805f9b34fb');

/// Standard BLE CSC (0x1816) + optional HR (0x180D) / Power (0x1818) / Battery (0x180F).
/// Bosch LDI: phone is accessory (advertise), bike is central. Never invent SoC/HR/W.
class BleCoreChannel {
  BleCoreChannel({
    MethodChannel? method,
    EventChannel? events,
  })  : _method = method ?? const MethodChannel(NativeChannels.bleCore),
        _events = events ?? const EventChannel('${NativeChannels.bleCore}/ldi');

  final MethodChannel _method;
  final EventChannel _events;

  StreamSubscription<dynamic>? _sub;
  StreamSubscription<List<int>>? _cscSub;
  StreamSubscription<List<int>>? _hrSub;
  StreamSubscription<List<int>>? _powerSub;
  StreamSubscription<List<int>>? _batterySub;
  StreamSubscription<List<int>>? _watchBatterySub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<BluetoothConnectionState>? _watchConnSub;
  StreamSubscription<List<ScanResult>>? _bikeScanSub;
  StreamSubscription<List<ScanResult>>? _watchScanSub;
  final _controller = StreamController<BoschLiveData>.broadcast();
  final _bikeScanController =
      StreamController<List<BikeBleScanHit>>.broadcast();
  final _watchScanController =
      StreamController<List<WatchBleScanHit>>.broadcast();
  bool _ldiConnected = false;
  bool _cscOnly = false;
  bool _wantConnection = false;
  bool _wantWatchConnection = false;
  bool _watchSim = false;
  bool _bikeScanActive = false;
  bool _watchScanActive = false;
  Timer? _stubTimer;
  Timer? _reconnectTimer;
  Timer? _watchReconnectTimer;
  Timer? _bikeScanTimeout;
  Timer? _watchScanTimeout;
  double _odo = 1247.4;
  double _speed = 0;
  double _cadence = 0;
  double? _hrBpm;
  double? _powerW;
  double? _socPercent;
  double? _watchBatteryPercent;
  BikeBleKind? _connectedKind;
  int? _prevWheelRevs;
  int? _prevWheelEventTime;
  int? _prevCrankRevs;
  int? _prevCrankEventTime;
  BluetoothDevice? _device;
  BluetoothDevice? _watchDevice;
  final List<BluetoothDevice> _auxDevices = [];
  final Map<String, BikeBleKind> _scanKindById = {};

  /// ScanResult devices keep Samsung's RANDOM vs PUBLIC address type.
  final Map<String, BluetoothDevice> _scanDevices = {};
  BikeBleKind? _kindHint;
  bool _preferScanDevice = true;
  bool _rideReconnect = false;
  bool _allowBondPrompt = false;
  bool _driveBonded = false;
  String? _driveRemoteId;
  final Map<String, StreamSubscription<BluetoothConnectionState>> _auxConnSubs =
      {};
  bool _rideWatchReconnect = false;
  int _reconnectAttempts = 0;
  int _watchReconnectAttempts = 0;
  void Function(String status)? _onProgress;
  String? _lastRemoteId;
  String? _lastWatchRemoteId;
  String? _hrSourceId;
  String? _statusDetail;
  String? _watchStatusDetail;

  /// Default ~29×2.25 / gravel-ish; garage wheel size can override.
  double wheelCircumferenceM = 2.105;

  Stream<BoschLiveData> get liveData => _controller.stream;
  Stream<List<BikeBleScanHit>> get bikeScanHits => _bikeScanController.stream;
  Stream<List<WatchBleScanHit>> get watchScanHits =>
      _watchScanController.stream;
  bool get isBikeScanning => _bikeScanActive;
  bool get isWatchScanning => _watchScanActive;
  bool get isConnected => _device != null || _ldiConnected;
  bool get isCscOnly => _cscOnly;

  /// CSC notify or native LDI — enough for wheel speed. Drive GATT alone is not.
  bool get hasWheelLive => _cscSub != null || _ldiConnected;
  bool get hasBikeLiveMetrics => bleHasLiveBikeMetrics(
        hasCscNotify: _cscSub != null,
        hasPowerNotify: _powerSub != null,
        hasSoc: _socPercent != null,
        ldiConnected: _ldiConnected,
      );
  bool get isDriveWithoutMetrics => bleDriveWithoutLiveMetrics(
        connected: isConnected,
        kind: _connectedKind,
        hasCscNotify: _cscSub != null,
        hasPowerNotify: _powerSub != null,
        hasSoc: _socPercent != null,
        ldiConnected: _ldiConnected,
      );
  bool get isWatchConnected => _watchDevice != null || _watchSim;

  /// Live BPM from 0x180D — never invented.
  double? get heartRateBpm => _hrBpm;

  /// Watch/strap battery if 0x180F on the watch. Never copied into bike SoC.
  double? get watchBatteryPercent => _watchBatteryPercent;
  BikeBleKind? get connectedKind => _connectedKind;
  String? get statusDetail => _statusDetail;
  String? get watchStatusDetail => _watchStatusDetail;
  String? get lastRemoteId => _lastRemoteId;
  String? get lastWatchRemoteId => _lastWatchRemoteId;

  /// Live GATT on this id — primary or aux (Intuvia beside CSC).
  bool isRemoteLive(String? id) {
    if (id == null || id.isEmpty) return false;
    if (id == boschLdiAccessoryId && _ldiConnected) return true;
    if (_device?.remoteId.str == id) return true;
    return _auxDevices.any((d) => d.remoteId.str == id);
  }

  /// True when the saved wheel or Bosch/Intuvia drive is actually streaming.
  bool isBindingLive({
    String? wheelId,
    String? driveId,
    String? driveKind,
  }) {
    return bleBindingLive(
      ldiConnected: _ldiConnected,
      hasLiveMetrics: hasBikeLiveMetrics,
      wheelId: wheelId,
      driveId: driveId,
      driveKind: driveKind,
      isRemoteLive: isRemoteLive,
    );
  }

  /// Platform-Name des verbundenen CSC-/LDI-Geräts (Garage-Speicher / HUD).
  String? get connectedDeviceName {
    if (_ldiConnected) {
      final n = _device?.platformName.trim();
      if (n != null && n.isNotEmpty) return n;
      return 'Intuvia';
    }
    final n = _device?.platformName.trim();
    if (n == null || n.isEmpty) return null;
    return n;
  }

  String? get connectedWatchName {
    if (_watchSim && (_watchDevice == null)) return 'Uhr (Sim)';
    final n = _watchDevice?.platformName.trim();
    if (n == null || n.isEmpty) return null;
    return n;
  }

  /// Request Android 12+ BLE runtime permissions via a short probe scan.
  Future<BlePermissionResult> ensurePermission() async {
    try {
      final supported = await FlutterBluePlus.isSupported;
      if (!supported) return BlePermissionResult.unsupported;

      if (!kIsWeb && Platform.isAndroid) {
        final scan = await ph.Permission.bluetoothScan.request();
        final connect = await ph.Permission.bluetoothConnect.request();
        final advertise = await ph.Permission.bluetoothAdvertise.request();
        if (scan.isDenied ||
            scan.isPermanentlyDenied ||
            connect.isDenied ||
            connect.isPermanentlyDenied ||
            advertise.isDenied ||
            advertise.isPermanentlyDenied) {
          return BlePermissionResult.denied;
        }
      } else if (!kIsWeb && Platform.isIOS) {
        final bt = await ph.Permission.bluetooth.request();
        if (bt.isDenied || bt.isPermanentlyDenied) {
          return BlePermissionResult.denied;
        }
      }

      var state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        try {
          await FlutterBluePlus.turnOn();
          state = await FlutterBluePlus.adapterState
              .where((s) => s == BluetoothAdapterState.on)
              .first
              .timeout(const Duration(seconds: 8));
        } catch (_) {
          return BlePermissionResult.adapterOff;
        }
        if (state != BluetoothAdapterState.on) {
          return BlePermissionResult.adapterOff;
        }
      }
      try {
        await _startOpenScan(timeout: const Duration(seconds: 2));
        await FlutterBluePlus.stopScan();
        return BlePermissionResult.granted;
      } catch (e) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('permission') || msg.contains('denied')) {
          return BlePermissionResult.denied;
        }
        return BlePermissionResult.granted;
      }
    } catch (_) {
      return BlePermissionResult.unsupported;
    }
  }

  Set<String> get capabilities => {
        if (isConnected) 'connected',
        'speed',
        'cadence',
        if (_hrBpm != null) 'hr',
        if (_powerW != null) 'power',
        if (_socPercent != null) 'battery',
        if (_connectedKind != null) _connectedKind!.name,
        if (isWatchConnected) 'watch',
      };

  Future<bool> connect({
    String? deviceId,
    bool scanIfMissing = true,
    BikeBleKind? kindHint,
    bool tryLdi = true,
    bool preferScanDevice = true,
    void Function(String status)? onProgress,
  }) async {
    _wantConnection = true;
    _rideReconnect = scanIfMissing;
    _allowBondPrompt = !scanIfMissing;
    _preferScanDevice = preferScanDevice;
    _onProgress = onProgress;
    _statusDetail = null;
    _kindHint = kindHint;
    await _loadLastRemoteId();

    try {
      final adapterOn =
          await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
      if (adapterOn) {
        final ok = await _connectStandardBle(
          preferredId: deviceId ?? _lastRemoteId,
          scanIfMissing: scanIfMissing,
        );
        if (ok) return true;
      } else {
        _statusDetail = 'Bluetooth aus';
      }
    } catch (e) {
      debugPrint('ble_core standard BLE: $e');
      _statusDetail ??= 'Suche fehlgeschlagen';
    }

    if (!tryLdi) {
      _onProgress = null;
      debugPrint(
        'ble_core connect: standard BLE failed, skip LDI '
        '(kind=${kindHint?.name} id=$deviceId status=$_statusDetail)',
      );
      return false;
    }

    try {
      return await startLdiAccessory(pairing: !scanIfMissing);
    } finally {
      _onProgress = null;
    }
  }

  /// Bosch LDI accessory: advertise, wait for the bike (Flow → Komponenten).
  Future<bool> startLdiAccessory({
    bool pairing = false,
    void Function(String status)? onProgress,
  }) async {
    final prev = _onProgress;
    if (onProgress != null) _onProgress = onProgress;
    _statusDetail = 'ldi_waiting_flow';
    _onProgress?.call(_statusDetail!);
    _sub ??=
        _events.receiveBroadcastStream().listen(_onEvent, onError: _onError);
    try {
      final ok = await _method.invokeMethod<bool>('connect', {
        'pairing': pairing,
      });
      _ldiConnected = ok ?? false;
      if (_ldiConnected) {
        _cscOnly = false;
        _connectedKind = BikeBleKind.bosch;
        _lastRemoteId = boschLdiAccessoryId;
      } else {
        _statusDetail ??= 'ldi_timeout';
      }
      return _ldiConnected;
    } on MissingPluginException {
      const sim = bool.fromEnvironment('AETHER_LDI_SIM', defaultValue: false);
      if (kDebugMode && sim) {
        debugPrint('ble_core: LDI Plugin fehlt — Simulator (AETHER_LDI_SIM)');
        _ldiConnected = true;
        _cscOnly = false;
        _connectedKind = BikeBleKind.bosch;
        _startStub();
        return true;
      }
      _statusDetail = 'ldi_ios_pending';
      return false;
    } finally {
      if (onProgress != null) _onProgress = prev;
    }
  }

  /// Ride: one-shot Display-GATT for 0x180F. No OS-bond dialog, no retries.
  /// If CSC is already primary, the drive lands as aux.
  Future<bool> attachSavedDrive({
    required String deviceId,
    BikeBleKind? kindHint,
  }) async {
    if (deviceId.isEmpty) return false;
    if (deviceId == boschLdiAccessoryId || kindHint == BikeBleKind.bosch) {
      return startLdiAccessory(pairing: false);
    }
    if (isRemoteLive(deviceId)) return true;
    final prevHint = _kindHint;
    final prevAllow = _allowBondPrompt;
    _kindHint = kindHint;
    _allowBondPrompt = false;
    try {
      return await _attachSensorDevice(
        _deviceForAttach(deviceId),
        gattAttempts: 1,
      );
    } finally {
      _kindHint = prevHint;
      _allowBondPrompt = prevAllow;
    }
  }

  /// Pair / reconnect a smartwatch or HR strap via Heart Rate 0x180D.
  /// Does not disconnect CSC / power. Does not invent BPM.
  /// Does not auto-grab the first scan hit — the Hof picker chooses [deviceId].
  Future<bool> connectWatch({
    String? deviceId,
    bool scanIfMissing = true,
  }) async {
    _wantWatchConnection = true;
    _rideWatchReconnect = scanIfMissing;
    _watchSim = false;
    await _loadLastWatchRemoteId();
    final preferred = deviceId ?? _lastWatchRemoteId;

    try {
      final adapterOn =
          await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
      if (!adapterOn) {
        _watchStatusDetail = 'Bluetooth aus';
        return false;
      }

      if (preferred != null && preferred.isNotEmpty) {
        try {
          final ok = await _attachWatchDevice(
            _deviceForAttach(preferred),
            gattAttempts: 3,
          );
          if (ok) return true;
        } catch (e) {
          debugPrint('ble_core watch preferred reconnect: $e');
        }
      }

      try {
        final system = await FlutterBluePlus.systemDevices([_hrServiceGuid]);
        for (final d in system) {
          if (preferred != null &&
              preferred.isNotEmpty &&
              d.remoteId.str != preferred) {
            continue;
          }
          if (preferred == null) continue;
          if (await _attachWatchDevice(d, gattAttempts: 2)) return true;
        }
      } catch (_) {}

      try {
        for (final d in FlutterBluePlus.connectedDevices) {
          if (preferred != null && d.remoteId.str == preferred) {
            if (await _attachWatchDevice(d, gattAttempts: 2)) return true;
          }
        }
      } catch (_) {}

      if (!scanIfMissing) {
        _watchStatusDetail ??= preferred == null
            ? 'Uhr in der Liste wählen'
            : 'Uhr nicht verbunden';
        return _watchDevice != null;
      }

      if (preferred == null || preferred.isEmpty) {
        if (_maybeWatchSim()) return true;
        _watchStatusDetail = 'Uhr in der Liste wählen';
        return false;
      }

      final scanned = await _scanForWatchId(preferred);
      if (scanned != null) {
        final ok = await _attachWatchDevice(scanned, gattAttempts: 3);
        if (ok) return true;
      }

      if (_maybeWatchSim()) return true;
      _watchStatusDetail ??=
          'Keine Uhr mit Standard-Puls-Service in Reichweite';
      return false;
    } catch (e) {
      debugPrint('ble_core watch: $e');
      _watchStatusDetail = 'Uhr-Suche fehlgeschlagen';
      return false;
    }
  }

  Future<BluetoothDevice?> _scanForWatchId(String id) async {
    await stopWatchScan();
    await stopBikeScan();
    BluetoothDevice? match;
    final sub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        _scanDevices[r.device.remoteId.str] = r.device;
        if (r.device.remoteId.str == id) match = r.device;
      }
    });
    try {
      await _startOpenScan(timeout: const Duration(seconds: 10));
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (match == null && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    } finally {
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}
      await sub.cancel();
    }
    return match ?? _scanDevices[id];
  }

  bool _maybeWatchSim() {
    const sim = bool.fromEnvironment('AETHER_LDI_SIM', defaultValue: false);
    if (kDebugMode && sim) {
      _watchSim = true;
      _watchStatusDetail = 'Uhr verbunden (Sim)';
      _ensureLiveTicker();
      return true;
    }
    return false;
  }

  String _scanName(ScanResult r) {
    final adv = r.advertisementData.advName.trim();
    if (adv.isNotEmpty) return adv;
    return r.device.platformName.trim();
  }

  Future<bool> _connectStandardBle({
    String? preferredId,
    bool scanIfMissing = true,
  }) async {
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      return false;
    }

    if (preferredId != null &&
        preferredId.isNotEmpty &&
        bleSkipPreferredDriveGatt(
          scanIfMissing: scanIfMissing,
          kindHint: _kindHint,
        )) {
      debugPrint(
        'ble_core: skip preferred drive GATT '
        'hint=${_kindHint?.name} id=$preferredId',
      );
    } else if (preferredId != null && preferredId.isNotEmpty) {
      try {
        debugPrint(
            'ble_core preferred attach $preferredId hint=${_kindHint?.name}');
        final device = _deviceForAttach(preferredId);
        final attempts = scanIfMissing ? 2 : 3;
        final attached = await _attachSensorDevice(
          device,
          gattAttempts: attempts,
          allowDriveAsPrimary: !scanIfMissing,
        );
        if (attached && _device != null && !scanIfMissing) {
          return true;
        }
        if (!scanIfMissing) {
          if (_device == null) {
            _statusDetail ??= 'Gerät nicht verbunden';
          }
          return _device != null;
        }
      } catch (e) {
        debugPrint('ble_core preferred reconnect: $e');
        if (!scanIfMissing) {
          _statusDetail ??=
              bleGattStatusHint(_codeFromError(e), kind: _kindHint);
          return _device != null;
        }
      }
    }

    try {
      final system = await FlutterBluePlus.systemDevices([
        _cscServiceGuid,
        _powerServiceGuid,
        if (!scanIfMissing) _batteryServiceGuid,
      ]);
      for (final d in system) {
        if (scanIfMissing && _looksLikeDrive(d)) continue;
        await _attachSensorDevice(d, allowDriveAsPrimary: !scanIfMissing);
      }
    } catch (_) {}

    try {
      for (final d in FlutterBluePlus.connectedDevices) {
        if (scanIfMissing && _looksLikeDrive(d)) continue;
        await _attachSensorDevice(d, allowDriveAsPrimary: !scanIfMissing);
      }
    } catch (_) {}

    if (_device != null &&
        _connectedKind != null &&
        bikeBleKindIsDrive(_connectedKind!)) {
      if (!scanIfMissing) return true;
    }
    if (_device != null && _powerSub != null) return true;
    if (_device != null && !scanIfMissing) return true;
    if (!scanIfMissing) {
      if (_device == null) {
        _statusDetail ??= 'Gerät nicht verbunden';
      }
      return _device != null;
    }

    final found = <String, BikeBleScanHit>{};
    final sub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final hit = _hitFromScan(r);
        if (hit != null) found[hit.deviceId] = hit;
      }
    });

    await _startOpenScan(timeout: const Duration(seconds: 12));

    final deadline = DateTime.now().add(const Duration(seconds: 12));
    while (found.isEmpty && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    final rest = deadline.difference(DateTime.now());
    if (rest > Duration.zero) {
      await Future<void>.delayed(rest);
    }
    await FlutterBluePlus.stopScan();
    await sub.cancel();

    for (final r in FlutterBluePlus.lastScanResults) {
      final hit = _hitFromScan(r);
      if (hit != null) found[hit.deviceId] = hit;
    }

    if (found.isEmpty) {
      if (_device == null) {
        _statusDetail = 'Kein Rad oder Sensor in Reichweite';
      }
      return _device != null;
    }

    final ranked = found.values.toList()
      ..sort((a, b) {
        final r = bikeBleRank(b.kind).compareTo(bikeBleRank(a.kind));
        if (r != 0) return r;
        return b.rssi.compareTo(a.rssi);
      });

    // Ride-Start ohne Picker: nur Standard-CSC/Power auto-koppeln.
    // Bosch/Shimano brauchen eine bewusste Wahl in der Werkstatt.
    for (final hit in ranked) {
      if (bikeBleKindIsDrive(hit.kind)) continue;
      await _attachSensorDevice(
        _deviceForAttach(hit.deviceId),
        allowDriveAsPrimary: false,
      );
      if (_device != null) return true;
    }

    if (_device == null) {
      final drives = ranked.where((h) => bikeBleKindIsDrive(h.kind)).length;
      _statusDetail = drives > 0
          ? 'Antrieb gesehen — in der Werkstatt koppeln (Bosch/Shimano)'
          : 'Kein Tempo-Sensor in Reichweite';
    }
    return _device != null;
  }

  BikeBleScanHit? _hitFromScan(ScanResult r) {
    final name = _scanName(r);
    final uuids =
        r.advertisementData.serviceUuids.map((x) => x.toString()).toList();
    final kind = classifyBikeBle(
      platformName: name,
      advertisedServiceUuids: uuids,
    );
    if (kind == null) return null;
    final id = r.device.remoteId.str;
    _scanKindById[id] = kind;
    _scanDevices[id] = r.device;
    return BikeBleScanHit(
      deviceId: id,
      name: name,
      kind: kind,
      rssi: r.rssi,
      caps: bikeBleCapsFromUuids(uuids, platformName: name),
      connectable: r.advertisementData.connectable,
    );
  }

  Future<void> _startOpenScan({required Duration timeout}) async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    await FlutterBluePlus.startScan(
      timeout: timeout,
      androidScanMode: AndroidScanMode.lowLatency,
      continuousUpdates: true,
    );
  }

  /// Live pairing scan: no GATT service filter (Bosch/Shimano omit 0x1816).
  Future<void> startBikeScan({
    Duration timeout = const Duration(seconds: 14),
  }) async {
    await stopBikeScan();
    await stopWatchScan();
    _bikeScanActive = true;
    if (!_bikeScanController.isClosed) {
      _bikeScanController.add(const []);
    }
    final found = <String, BikeBleScanHit>{};
    void emit() {
      final list = found.values.toList()
        ..sort((a, b) {
          final r = bikeBleRank(b.kind).compareTo(bikeBleRank(a.kind));
          if (r != 0) return r;
          return b.rssi.compareTo(a.rssi);
        });
      if (!_bikeScanController.isClosed) _bikeScanController.add(list);
    }

    _bikeScanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final hit = _hitFromScan(r);
        if (hit != null) found[hit.deviceId] = hit;
      }
      emit();
    });

    try {
      await _startOpenScan(timeout: timeout);
    } catch (e) {
      debugPrint('ble_core bike scan: $e');
      _bikeScanActive = false;
      rethrow;
    }

    for (final r in FlutterBluePlus.lastScanResults) {
      final hit = _hitFromScan(r);
      if (hit != null) found[hit.deviceId] = hit;
    }
    emit();

    _bikeScanTimeout = Timer(timeout, () {
      unawaited(stopBikeScan());
    });
  }

  Future<void> stopBikeScan() async {
    _bikeScanTimeout?.cancel();
    _bikeScanTimeout = null;
    _bikeScanActive = false;
    await _bikeScanSub?.cancel();
    _bikeScanSub = null;
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
  }

  WatchBleScanHit? _watchHitFromScan(ScanResult r) {
    final name = _scanName(r);
    final uuids =
        r.advertisementData.serviceUuids.map((x) => x.toString()).toList();
    if (!isWatchCandidate(
      platformName: name,
      advertisedServiceUuids: uuids,
    )) {
      return null;
    }
    final id = r.device.remoteId.str;
    _scanDevices[id] = r.device;
    return WatchBleScanHit(
      deviceId: id,
      name: name,
      rssi: r.rssi,
      hasHrService: advertisesHeartRateService(uuids),
      honesty: watchHonestyForName(name),
      connectable: r.advertisementData.connectable,
    );
  }

  /// Live watch / HR scan: open scan (many watches omit 0x180D in ads).
  Future<void> startWatchScan({
    Duration timeout = const Duration(seconds: 16),
  }) async {
    await stopWatchScan();
    await stopBikeScan();
    _watchScanActive = true;
    if (!_watchScanController.isClosed) {
      _watchScanController.add(const []);
    }
    final found = <String, WatchBleScanHit>{};
    void emit() {
      final list = found.values.toList()
        ..sort((a, b) {
          final hr = (b.hasHrService ? 1 : 0).compareTo(a.hasHrService ? 1 : 0);
          if (hr != 0) return hr;
          return b.rssi.compareTo(a.rssi);
        });
      if (!_watchScanController.isClosed) _watchScanController.add(list);
    }

    _watchScanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final hit = _watchHitFromScan(r);
        if (hit != null) found[hit.deviceId] = hit;
      }
      emit();
    });

    try {
      await _startOpenScan(timeout: timeout);
    } catch (e) {
      debugPrint('ble_core watch scan: $e');
      _watchScanActive = false;
      rethrow;
    }

    for (final r in FlutterBluePlus.lastScanResults) {
      final hit = _watchHitFromScan(r);
      if (hit != null) found[hit.deviceId] = hit;
    }
    emit();

    _watchScanTimeout = Timer(timeout, () {
      unawaited(stopWatchScan());
    });
  }

  Future<void> stopWatchScan() async {
    _watchScanTimeout?.cancel();
    _watchScanTimeout = null;
    _watchScanActive = false;
    await _watchScanSub?.cancel();
    _watchScanSub = null;
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
  }

  BikeBleKind? _kindHintFor(BluetoothDevice device) {
    final id = device.remoteId.str;
    return _scanKindById[id] ??
        classifyBikeBle(
          platformName: device.platformName,
          advertisedServiceUuids: const [],
        ) ??
        _kindHint;
  }

  bool _looksLikeDrive(BluetoothDevice device) {
    final kind = _kindHintFor(device);
    return kind != null && bikeBleKindIsDrive(kind);
  }

  BikeBleKind? _kindForDevice(
    BluetoothDevice device,
    List<BluetoothService> services,
  ) {
    final id = device.remoteId.str;
    return classifyBikeBle(
          platformName: device.platformName,
          advertisedServiceUuids: services.map((s) => s.uuid.toString()),
        ) ??
        _scanKindById[id] ??
        _kindHint;
  }

  bool _alreadyAttached(String id) {
    if (_device?.remoteId.str == id) return true;
    if (_watchDevice?.remoteId.str == id) return true;
    return _auxDevices.any((d) => d.remoteId.str == id);
  }

  BluetoothDevice _deviceForAttach(String id, {bool? preferScanDevice}) {
    final prefer = preferScanDevice ?? _preferScanDevice;
    if (prefer) {
      final scanned = _scanDevices[id];
      if (scanned != null) return scanned;
    }
    return BluetoothDevice.fromId(id);
  }

  int? _mtuForDevice(String id) {
    final kind = _kindHint ?? _scanKindById[id] ?? _connectedKind;
    if (kind != null && bikeBleKindIsDrive(kind)) return null;
    return 512;
  }

  Future<bool> _isBonded(BluetoothDevice device) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final s =
          await device.bondState.first.timeout(const Duration(seconds: 2));
      return s == BluetoothBondState.bonded;
    } catch (_) {
      return false;
    }
  }

  Future<void> _maybeBondDrive(BluetoothDevice device) async {
    if (kIsWeb || !Platform.isAndroid) return;
    final kind = _kindHintFor(device);
    if (kind == null || !bikeBleKindIsDrive(kind)) return;
    try {
      if (await _isBonded(device)) {
        _driveBonded = true;
        return;
      }
    } catch (_) {}
    if (!_allowBondPrompt) {
      debugPrint('ble_core: drive unbonded, skip pair dialog');
      _driveBonded = false;
      return;
    }
    _progress('System-Kopplung …');
    try {
      await device.createBond(timeout: 45);
      _driveBonded = true;
    } catch (e) {
      debugPrint('ble_core createBond: $e');
      _driveBonded = false;
      _statusDetail =
          'Display braucht eine Bluetooth-Bestätigung für den Akku.';
    }
  }

  void _listenAuxDisconnect(BluetoothDevice device, {required bool isDrive}) {
    final id = device.remoteId.str;
    unawaited(_auxConnSubs[id]?.cancel());
    _auxConnSubs[id] = device.connectionState.listen((state) {
      if (state != BluetoothConnectionState.disconnected) return;
      _auxDevices.removeWhere((d) => d.remoteId.str == id);
      unawaited(_auxConnSubs.remove(id)?.cancel());
      if (isDrive && _driveRemoteId == id) {
        unawaited(_batterySub?.cancel());
        _batterySub = null;
        _socPercent = null;
        _driveRemoteId = null;
      }
      _refreshStatus();
    });
  }

  Future<void> _cancelAuxListeners() async {
    final subs = List<StreamSubscription<BluetoothConnectionState>>.from(
      _auxConnSubs.values,
    );
    _auxConnSubs.clear();
    for (final s in subs) {
      await s.cancel();
    }
  }

  void _progress(String message) {
    _statusDetail = message;
    _onProgress?.call(message);
    debugPrint('ble_core: $message');
  }

  int? _codeFromError(Object error) {
    if (error is FlutterBluePlusException) return error.code;
    return parseGattErrorCode(error);
  }

  Future<void> _closeGattQuietly(BluetoothDevice device) async {
    try {
      await device.disconnect();
    } catch (_) {}
  }

  Future<bool> _ensureGattConnected(
    BluetoothDevice device, {
    required int attempts,
    bool skipMtu = false,
  }) async {
    if (!device.isDisconnected) return true;
    final mtu = skipMtu ? null : _mtuForDevice(device.remoteId.str);
    final max = attempts.clamp(1, 3);
    int? lastCode;
    for (var i = 0; i < max; i++) {
      if (i > 0) {
        _progress('Verbinde … Retry ${i + 1}/$max');
        await _closeGattQuietly(device);
        await Future<void>.delayed(
          Duration(milliseconds: i == 1 ? 1500 : 3000),
        );
      } else if (max > 1) {
        _progress('Verbinde … Versuch 1/$max');
      }
      try {
        await device.connect(
          timeout: const Duration(seconds: 14),
          autoConnect: false,
          mtu: mtu,
        );
        return true;
      } catch (e) {
        lastCode = _codeFromError(e);
        debugPrint('ble_core gatt attempt ${i + 1}/$max code=$lastCode $e');
        final transient = isTransientGattError(lastCode);
        if (!transient || i == max - 1) {
          _statusDetail =
              bleGattStatusHint(lastCode, kind: _kindHintFor(device));
          await _closeGattQuietly(device);
          return false;
        }
      }
    }
    _statusDetail = bleGattStatusHint(lastCode, kind: _kindHintFor(device));
    return false;
  }

  Future<bool> _attachSensorDevice(
    BluetoothDevice device, {
    int gattAttempts = 1,
    bool allowDriveAsPrimary = true,
  }) async {
    final id = device.remoteId.str;
    if (_alreadyAttached(id)) return true;
    try {
      final opened = await _ensureGattConnected(
        device,
        attempts: gattAttempts,
      );
      if (!opened) return false;
      await _maybeBondDrive(device);
      final services = await device.discoverServices();
      BluetoothCharacteristic? measurement;
      for (final s in services) {
        final su = s.uuid.toString().toLowerCase();
        if (!su.contains('1816')) continue;
        for (final c in s.characteristics) {
          final cu = c.uuid.toString().toLowerCase();
          if (cu.contains('2a5b') && c.properties.notify) {
            measurement = c;
            break;
          }
        }
      }
      if (measurement == null) {
        for (final s in services) {
          if (!s.uuid.toString().toLowerCase().contains('1816')) continue;
          for (final c in s.characteristics) {
            if (c.properties.notify) {
              measurement = c;
              break;
            }
          }
        }
      }

      var gotCsc = false;
      if (measurement != null) {
        await _cscSub?.cancel();
        await measurement.setNotifyValue(true);
        _cscSub = measurement.lastValueStream.listen(_onCscBytes);
        gotCsc = true;
      }
      final gotExtra = await _subscribeOptionalGatt(services, sourceId: id);
      final kind = _kindForDevice(device, services);

      if (!gotCsc && !gotExtra) {
        if (kind == null || !bikeBleKindIsDrive(kind)) {
          try {
            await device.disconnect();
          } catch (_) {}
          return false;
        }
      }

      final resolvedKind =
          kind ?? (gotCsc ? BikeBleKind.csc : BikeBleKind.power);
      final isDrive = bikeBleKindIsDrive(resolvedKind);

      if (gotCsc || isDrive) {
        if (isDrive) {
          _driveRemoteId = id;
        }
        if (_device == null) {
          if (isDrive && !gotCsc && !allowDriveAsPrimary) {
            await _batterySub?.cancel();
            _batterySub = null;
            _socPercent = null;
            await _closeGattQuietly(device);
            _driveRemoteId = null;
            return false;
          }
          await _connSub?.cancel();
          _connSub = device.connectionState.listen((state) {
            if (state == BluetoothConnectionState.disconnected) {
              if (_device?.remoteId.str == id) {
                final code = device.disconnectReason?.code;
                final kind = _connectedKind;
                final bonded = _driveBonded;
                _device = null;
                _statusDetail = 'Sensor getrennt';
                if (kind != null && bikeBleKindIsDrive(kind)) {
                  _driveRemoteId = null;
                }
                if (_watchDevice?.remoteId.str == id) {
                  _watchDevice = null;
                  _watchStatusDetail = 'Uhr getrennt';
                }
                if (_wantConnection) {
                  if (!bleShouldReconnectAfterDrop(
                    kind: kind,
                    disconnectCode: code,
                    bonded: bonded,
                  )) {
                    _statusDetail = bleGattStatusHint(code, kind: kind);
                    debugPrint(
                      'ble_core: skip reconnect kind=${kind?.name} '
                      'code=$code bonded=$bonded',
                    );
                    return;
                  }
                  _scheduleReconnect();
                }
              }
            } else if (state == BluetoothConnectionState.connected) {
              _refreshStatus();
            }
          });
          _device = device;
          _connectedKind = resolvedKind;
          _lastRemoteId = id;
          _reconnectAttempts = 0;
          _reconnectTimer?.cancel();
          _reconnectTimer = null;
          if (!isDrive) {
            await _saveLastRemoteId(id);
          }
        } else if (_device!.remoteId.str != id) {
          _auxDevices.add(device);
          _listenAuxDisconnect(device, isDrive: isDrive);
        }
      } else {
        // Power (or HR on a bike box) without CSC — keep beside the wheel sensor.
        _auxDevices.add(device);
        _listenAuxDisconnect(device, isDrive: false);
      }

      _cscOnly = !_ldiConnected;
      _refreshStatus();
      _ensureLiveTicker();
      return true;
    } catch (e) {
      debugPrint('ble_core attach: $e');
      _statusDetail ??= bleGattStatusHint(_codeFromError(e), kind: _kindHint);
      await _closeGattQuietly(device);
      return false;
    }
  }

  Future<bool> _attachWatchDevice(
    BluetoothDevice device, {
    int gattAttempts = 1,
  }) async {
    final id = device.remoteId.str;
    if (_watchDevice?.remoteId.str == id && _hrSub != null) return true;
    if (_device?.remoteId.str == id) {
      // Same physical box as CSC: subscribe HR there, still record as watch id.
      final services = await device.discoverServices();
      final gotHr = await _subscribeOptionalGatt(
        services,
        sourceId: id,
        bindBikeBattery: false,
      );
      if (gotHr && _hrSub != null) {
        _watchDevice = device;
        _lastWatchRemoteId = id;
        _watchReconnectAttempts = 0;
        await _saveLastWatchRemoteId(id);
        _refreshWatchStatus();
        _ensureLiveTicker();
        return true;
      }
      _watchStatusDetail = 'Uhr gefunden, aber ohne Standard-Puls-Service';
      return false;
    }
    if (_auxDevices.any((d) => d.remoteId.str == id) && _hrSub != null) {
      _watchDevice = device;
      _lastWatchRemoteId = id;
      await _saveLastWatchRemoteId(id);
      _refreshWatchStatus();
      return true;
    }
    try {
      final opened = await _ensureGattConnected(
        device,
        attempts: gattAttempts,
        skipMtu: true,
      );
      if (!opened) {
        _watchStatusDetail = _statusDetail ?? 'Uhr-Verbindung fehlgeschlagen';
        return false;
      }
      final services = await device.discoverServices();
      final gotHr = await _subscribeOptionalGatt(
        services,
        sourceId: id,
        bindBikeBattery: false,
      );
      final hasHrService = services.any(
        (s) => s.uuid.toString().toLowerCase().contains('180d'),
      );
      if (!gotHr || _hrSub == null) {
        if (hasHrService || nameLooksLikeWatch(device.platformName)) {
          _watchStatusDetail = 'Uhr gefunden, aber ohne Standard-Puls-Service';
        } else {
          _watchStatusDetail ??= 'Kein Puls-Signal auf diesem Gerät';
        }
        if (_watchDevice?.remoteId.str != id && _device?.remoteId.str != id) {
          await _closeGattQuietly(device);
        }
        return false;
      }

      await _watchConnSub?.cancel();
      _watchConnSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          if (_watchDevice?.remoteId.str == id) {
            _watchDevice = null;
            _watchStatusDetail = 'Uhr getrennt';
            if (_hrSourceId == id) {
              _hrBpm = null;
            }
            _watchBatteryPercent = null;
            unawaited(_watchBatterySub?.cancel());
            _watchBatterySub = null;
            if (_wantWatchConnection) _scheduleWatchReconnect();
          }
        } else if (state == BluetoothConnectionState.connected) {
          _refreshWatchStatus();
        }
      });
      _watchDevice = device;
      _lastWatchRemoteId = id;
      _watchReconnectAttempts = 0;
      _watchReconnectTimer?.cancel();
      _watchReconnectTimer = null;
      await _saveLastWatchRemoteId(id);
      _refreshWatchStatus();
      _ensureLiveTicker();
      return true;
    } catch (e) {
      debugPrint('ble_core watch attach: $e');
      _watchStatusDetail = 'Uhr-Verbindung fehlgeschlagen';
      return false;
    }
  }

  void _refreshStatus() {
    final names = <String>[
      if (_device != null && _device!.platformName.trim().isNotEmpty)
        _device!.platformName.trim(),
      ..._auxDevices
          .map((d) => d.platformName.trim())
          .where((n) => n.isNotEmpty),
    ];
    final caps = <String>[
      if (_ldiConnected) 'Intuvia',
      if (_connectedKind != null && !_ldiConnected)
        bikeBleKindLabel(_connectedKind!),
      if (_cscSub != null) 'Tempo',
      if (_powerSub != null) 'Leistung',
      if (_socPercent != null) 'Akku',
    ];
    final who = names.isEmpty
        ? (_ldiConnected ? 'Intuvia' : 'Sensor')
        : names.join(' · ');
    if (_ldiConnected) {
      _statusDetail =
          caps.length <= 1 ? '$who · live' : '$who · ${caps.join(', ')}';
    } else if (_connectedKind != null &&
        bikeBleKindIsDrive(_connectedKind!) &&
        _cscSub == null &&
        _socPercent == null) {
      _statusDetail = _driveBonded
          ? '$who · erkannt — Tempo über den Sensor am Rad'
          : '$who · erkannt — Akku nach Bestätigung in der Werkstatt';
    } else {
      _statusDetail =
          caps.isEmpty ? '$who verbunden' : '$who · ${caps.join(', ')}';
    }
    _refreshWatchStatus();
  }

  void _refreshWatchStatus() {
    if (_watchSim && _watchDevice == null) {
      _watchStatusDetail = 'Uhr verbunden (Sim)';
      return;
    }
    final watch = _watchDevice;
    if (watch == null) return;
    final n = watch.platformName.trim();
    final who = n.isEmpty ? 'Uhr' : n;
    final bits = <String>[
      if (_hrSub != null && _hrBpm != null) '${_hrBpm!.round()} bpm',
      if (_hrSub != null && _hrBpm == null) 'Puls',
      if (_watchBatteryPercent != null)
        'Uhr-Akku ${_watchBatteryPercent!.round()} %',
    ];
    _watchStatusDetail =
        bits.isEmpty ? '$who verbunden' : '$who · ${bits.join(' · ')}';
  }

  Future<bool> _subscribeOptionalGatt(
    List<BluetoothService> services, {
    required String sourceId,
    bool bindBikeBattery = true,
  }) async {
    var got = false;
    for (final s in services) {
      final su = s.uuid.toString().toLowerCase();
      for (final c in s.characteristics) {
        final cu = c.uuid.toString().toLowerCase();
        if (su.contains('180d') &&
            cu.contains('2a37') &&
            c.properties.notify &&
            _hrSub == null) {
          try {
            await c.setNotifyValue(true);
            _hrSourceId = sourceId;
            _hrSub = c.lastValueStream.listen((bytes) {
              final bpm = parseHeartRateBpm(bytes);
              if (bpm != null && bpm > 0 && bpm < 240) {
                _hrBpm = bpm.toDouble();
                _refreshWatchStatus();
              }
            });
            got = true;
          } catch (e) {
            debugPrint('ble_core HR notify: $e');
          }
        }
        if (bindBikeBattery &&
            su.contains('1818') &&
            cu.contains('2a63') &&
            c.properties.notify &&
            _powerSub == null) {
          try {
            await c.setNotifyValue(true);
            _powerSub = c.lastValueStream.listen((bytes) {
              final w = parseCyclingPowerWatts(bytes);
              if (w != null && w >= 0 && w < 2500) {
                _powerW = w.toDouble();
              }
            });
            got = true;
          } catch (e) {
            debugPrint('ble_core power notify: $e');
          }
        }
        if (su.contains('180f') && cu.contains('2a19')) {
          try {
            if (bindBikeBattery && _batterySub == null) {
              if (c.properties.notify) {
                await c.setNotifyValue(true);
                _batterySub = c.lastValueStream.listen((bytes) {
                  final pct = parseBatteryLevelPercent(bytes);
                  if (pct != null) _socPercent = pct.toDouble();
                });
                got = true;
              }
              if (c.properties.read) {
                final bytes = await c.read();
                final pct = parseBatteryLevelPercent(bytes);
                if (pct != null) {
                  _socPercent = pct.toDouble();
                  got = true;
                }
              }
            } else if (!bindBikeBattery && _watchBatterySub == null) {
              if (c.properties.notify) {
                await c.setNotifyValue(true);
                _watchBatterySub = c.lastValueStream.listen((bytes) {
                  final pct = parseBatteryLevelPercent(bytes);
                  if (pct != null) {
                    _watchBatteryPercent = pct.toDouble();
                    _refreshWatchStatus();
                  }
                });
                got = true;
              }
              if (c.properties.read) {
                final bytes = await c.read();
                final pct = parseBatteryLevelPercent(bytes);
                if (pct != null) {
                  _watchBatteryPercent = pct.toDouble();
                  got = true;
                }
              }
            }
          } catch (e) {
            debugPrint('ble_core battery: $e');
          }
        }
      }
    }
    return got;
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    final max = _rideReconnect
        ? kBleReconnectMaxDuringRide
        : kBleReconnectMaxOutsideRide;
    if (_reconnectAttempts >= max) {
      _statusDetail =
          'Verbindung verloren — Display prüfen, Flow/E-TUBE schließen, '
          'in der Werkstatt erneut koppeln.';
      debugPrint('ble_core reconnect: gave up after $_reconnectAttempts');
      return;
    }
    final delay = bleReconnectDelay(_reconnectAttempts);
    final attempt = _reconnectAttempts + 1;
    _reconnectAttempts++;
    _reconnectTimer = Timer(delay, () async {
      if (!_wantConnection || _device != null) return;
      final id = _lastRemoteId;
      if (id == null) return;
      _statusDetail = 'Verbinde erneut … ($attempt/$max)';
      try {
        final ok = await _attachSensorDevice(
          _deviceForAttach(id),
          gattAttempts: 1,
        );
        if (ok) {
          _reconnectAttempts = 0;
          return;
        }
        if (_wantConnection && _device == null) _scheduleReconnect();
      } catch (e) {
        debugPrint('ble_core reconnect: $e');
        if (_wantConnection && _device == null) _scheduleReconnect();
      }
    });
  }

  void _scheduleWatchReconnect() {
    _watchReconnectTimer?.cancel();
    final max = _rideWatchReconnect
        ? kBleReconnectMaxDuringRide
        : kBleReconnectMaxOutsideRide;
    if (_watchReconnectAttempts >= max) {
      _watchStatusDetail =
          'Uhr getrennt — Broadcast prüfen, in der Nähe erneut koppeln.';
      debugPrint(
        'ble_core watch reconnect: gave up after $_watchReconnectAttempts',
      );
      return;
    }
    final delay = bleReconnectDelay(_watchReconnectAttempts);
    final attempt = _watchReconnectAttempts + 1;
    _watchReconnectAttempts++;
    _watchReconnectTimer = Timer(delay, () async {
      if (!_wantWatchConnection || _watchDevice != null) return;
      final id = _lastWatchRemoteId;
      if (id == null) return;
      _watchStatusDetail = 'Uhr verbindet erneut … ($attempt/$max)';
      try {
        final ok = await _attachWatchDevice(
          _deviceForAttach(id),
          gattAttempts: 1,
        );
        if (ok) {
          _watchReconnectAttempts = 0;
          return;
        }
        if (_wantWatchConnection && _watchDevice == null) {
          _scheduleWatchReconnect();
        }
      } catch (e) {
        debugPrint('ble_core watch reconnect: $e');
        if (_wantWatchConnection && _watchDevice == null) {
          _scheduleWatchReconnect();
        }
      }
    });
  }

  void _onCscBytes(List<int> data) {
    final parsed = parseCscMeasurement(
      data,
      wheelCircumferenceM: wheelCircumferenceM,
      prevWheelRevs: _prevWheelRevs,
      prevWheelEventTime: _prevWheelEventTime,
      prevCrankRevs: _prevCrankRevs,
      prevCrankEventTime: _prevCrankEventTime,
      speedKmh: _speed,
      cadenceRpm: _cadence,
    );
    _speed = parsed.speedKmh;
    _cadence = parsed.cadenceRpm;
    _prevWheelRevs = parsed.prevWheelRevs;
    _prevWheelEventTime = parsed.prevWheelEventTime;
    _prevCrankRevs = parsed.prevCrankRevs;
    _prevCrankEventTime = parsed.prevCrankEventTime;
  }

  void _ensureLiveTicker() {
    if (_stubTimer != null) return;
    _startCscTicker();
  }

  void _startCscTicker() {
    _stubTimer?.cancel();
    _stubTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _emit(
        BoschLiveData(
          speedKmh: _speed,
          batterySocPercent: _socPercent,
          riderPowerW: _powerW,
          heartRateBpm: _hrBpm,
          cadenceRpm: _cadence,
          odometerKm: 0,
          lightStatus: false,
          ambientBrightness: 0,
          systemLock: false,
          bikeNotDriving: _speed < 1,
          chargerConnected: false,
          timestampMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    });
  }

  Future<void> disconnectCsc() async {
    _wantConnection = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    await _cscSub?.cancel();
    _cscSub = null;
    await _batterySub?.cancel();
    _batterySub = null;
    await _connSub?.cancel();
    _connSub = null;
    final cscId = _device?.remoteId.str;
    try {
      await _device?.disconnect();
    } catch (_) {}
    if (cscId != null && _watchDevice?.remoteId.str == cscId) {
      _watchDevice = null;
    }
    _device = null;
    _connectedKind = null;
    _socPercent = null;
    _driveBonded = false;
    if (_driveRemoteId == cscId) _driveRemoteId = null;
    _prevWheelRevs = null;
    _prevWheelEventTime = null;
    _prevCrankRevs = null;
    _prevCrankEventTime = null;
    _speed = 0;
    _cadence = 0;
    _statusDetail = null;
    if (_watchDevice == null && _auxDevices.isEmpty && !_ldiConnected) {
      _stubTimer?.cancel();
      _stubTimer = null;
    }
    _refreshStatus();
  }

  /// End of ride: drop CSC/power/drive, keep rider watch / HR.
  Future<void> disconnectBikeKeepWatch() async {
    await stopBikeScan();
    _wantConnection = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    await _cscSub?.cancel();
    _cscSub = null;
    await _powerSub?.cancel();
    _powerSub = null;
    await _batterySub?.cancel();
    _batterySub = null;
    await _connSub?.cancel();
    _connSub = null;
    final watchId = _watchDevice?.remoteId.str;
    if (_device != null &&
        (watchId == null || _device!.remoteId.str != watchId)) {
      try {
        await _device?.disconnect();
      } catch (_) {}
    }
    _device = null;
    try {
      await _method.invokeMethod<void>('disconnect');
    } on MissingPluginException {
      // LDI accessory may be absent on iOS.
    }
    await _cancelAuxListeners();
    for (final d in List<BluetoothDevice>.from(_auxDevices)) {
      if (watchId != null && d.remoteId.str == watchId) continue;
      try {
        await d.disconnect();
      } catch (_) {}
    }
    _auxDevices.removeWhere(
      (d) => watchId == null || d.remoteId.str != watchId,
    );
    _connectedKind = null;
    _socPercent = null;
    _powerW = null;
    _driveBonded = false;
    _driveRemoteId = null;
    _rideWatchReconnect = false;
    _prevWheelRevs = null;
    _prevWheelEventTime = null;
    _prevCrankRevs = null;
    _prevCrankEventTime = null;
    _speed = 0;
    _cadence = 0;
    _statusDetail = null;
    _ldiConnected = false;
    if (_watchDevice == null) {
      _stubTimer?.cancel();
      _stubTimer = null;
    } else {
      _ensureLiveTicker();
    }
    _refreshWatchStatus();
  }

  /// Forget the last CSC/drive id so unlink does not auto-reconnect it.
  Future<void> forgetLastBikeId() async {
    _lastRemoteId = null;
    await _deleteIdFile(kBleLastCscIdFile);
  }

  /// Forget the last watch / HR id.
  Future<void> forgetLastWatchId() async {
    _lastWatchRemoteId = null;
    await _deleteIdFile(kBleLastWatchIdFile);
  }

  Future<void> forgetAllPairedIds() async {
    await forgetLastBikeId();
    await forgetLastWatchId();
  }

  Future<void> _deleteIdFile(String name) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File(p.join(dir.path, name));
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// Drop LDI / drive GATT. Keep wheel CSC and rider watch.
  Future<void> disconnectDriveKeepWheel() async {
    try {
      await _method.invokeMethod<void>('disconnect');
    } on MissingPluginException {
      // LDI accessory may be absent on iOS.
    }
    _ldiConnected = false;
    await _batterySub?.cancel();
    _batterySub = null;
    _socPercent = null;
    _driveBonded = false;
    final driveId = _driveRemoteId;
    _driveRemoteId = null;
    final watchId = _watchDevice?.remoteId.str;
    final drop = <BluetoothDevice>[];
    for (final d in List<BluetoothDevice>.from(_auxDevices)) {
      final kind = _kindHintFor(d);
      final isDrive = kind != null && bikeBleKindIsDrive(kind);
      if (isDrive || d.remoteId.str == driveId) {
        if (watchId != null && d.remoteId.str == watchId) continue;
        drop.add(d);
      }
    }
    for (final d in drop) {
      _auxDevices.removeWhere((x) => x.remoteId.str == d.remoteId.str);
      unawaited(_auxConnSubs.remove(d.remoteId.str)?.cancel());
      try {
        await d.disconnect();
      } catch (_) {}
    }
    if (_device != null &&
        (_device!.remoteId.str == driveId ||
            (_connectedKind != null &&
                bikeBleKindIsDrive(_connectedKind!) &&
                _cscSub == null))) {
      if (watchId == null || _device!.remoteId.str != watchId) {
        try {
          await _device?.disconnect();
        } catch (_) {}
      }
      await _connSub?.cancel();
      _connSub = null;
      _device = null;
      _connectedKind = _cscSub != null ? BikeBleKind.csc : null;
    }
    _refreshStatus();
  }

  Future<void> disconnectWatch() async {
    _wantWatchConnection = false;
    _rideWatchReconnect = false;
    _watchReconnectTimer?.cancel();
    _watchReconnectTimer = null;
    _watchSim = false;
    await _watchConnSub?.cancel();
    _watchConnSub = null;
    _watchBatteryPercent = null;
    _watchReconnectAttempts = 0;
    await _watchBatterySub?.cancel();
    _watchBatterySub = null;
    _watchBatteryPercent = null;
    if (_hrSourceId != null &&
        (_hrSourceId == _lastWatchRemoteId ||
            _hrSourceId == _watchDevice?.remoteId.str)) {
      await _hrSub?.cancel();
      _hrSub = null;
      _hrBpm = null;
      _hrSourceId = null;
    }
    final watch = _watchDevice;
    _watchDevice = null;
    if (watch != null && watch.remoteId.str != _device?.remoteId.str) {
      try {
        await watch.disconnect();
      } catch (_) {}
    }
    _watchStatusDetail = null;
    if (_device == null && _auxDevices.isEmpty && !_ldiConnected) {
      _stubTimer?.cancel();
      _stubTimer = null;
    }
  }

  Future<void> disconnect() async {
    await stopBikeScan();
    await stopWatchScan();
    _wantConnection = false;
    _wantWatchConnection = false;
    _watchSim = false;
    _rideWatchReconnect = false;
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _watchReconnectTimer?.cancel();
    _watchReconnectTimer = null;
    _stubTimer?.cancel();
    _stubTimer = null;
    await _cscSub?.cancel();
    _cscSub = null;
    await _hrSub?.cancel();
    _hrSub = null;
    await _powerSub?.cancel();
    _powerSub = null;
    await _batterySub?.cancel();
    _batterySub = null;
    await _watchBatterySub?.cancel();
    _watchBatterySub = null;
    await _connSub?.cancel();
    _connSub = null;
    await _watchConnSub?.cancel();
    _watchConnSub = null;
    await _cancelAuxListeners();
    _ldiConnected = false;
    _cscOnly = false;
    _connectedKind = null;
    _socPercent = null;
    _watchBatteryPercent = null;
    _driveBonded = false;
    _driveRemoteId = null;
    _prevWheelRevs = null;
    _prevWheelEventTime = null;
    _prevCrankRevs = null;
    _prevCrankEventTime = null;
    _speed = 0;
    _cadence = 0;
    _hrBpm = null;
    _powerW = null;
    _hrSourceId = null;
    _statusDetail = null;
    _watchStatusDetail = null;
    try {
      await _device?.disconnect();
    } catch (_) {}
    _device = null;
    try {
      await _watchDevice?.disconnect();
    } catch (_) {}
    _watchDevice = null;
    final aux = List<BluetoothDevice>.from(_auxDevices);
    _auxDevices.clear();
    for (final d in aux) {
      try {
        await d.disconnect();
      } catch (_) {}
    }
    try {
      for (final d in FlutterBluePlus.connectedDevices) {
        await d.disconnect();
      }
    } catch (_) {}
    try {
      await _method.invokeMethod<void>('disconnect');
    } on MissingPluginException {
      // ignore
    }
  }

  Future<void> _loadLastRemoteId() async {
    if (_lastRemoteId != null) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File(p.join(dir.path, kBleLastCscIdFile));
      if (await f.exists()) {
        final id = (await f.readAsString()).trim();
        if (id.isNotEmpty) _lastRemoteId = id;
      }
    } catch (_) {}
  }

  Future<void> _saveLastRemoteId(String id) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File(p.join(dir.path, kBleLastCscIdFile));
      await f.writeAsString(id);
    } catch (_) {}
  }

  Future<void> _loadLastWatchRemoteId() async {
    if (_lastWatchRemoteId != null) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File(p.join(dir.path, kBleLastWatchIdFile));
      if (await f.exists()) {
        final id = (await f.readAsString()).trim();
        if (id.isNotEmpty) _lastWatchRemoteId = id;
      }
    } catch (_) {}
  }

  Future<void> _saveLastWatchRemoteId(String id) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File(p.join(dir.path, kBleLastWatchIdFile));
      await f.writeAsString(id);
    } catch (_) {}
  }

  void _onEvent(dynamic event) {
    if (event is! Map) return;
    final status = event['status'];
    if (status is String && status.isNotEmpty) {
      _statusDetail = status;
      _onProgress?.call(status);
      return;
    }
    _cscOnly = false;
    _connectedKind ??= BikeBleKind.bosch;
    _emit(BoschLiveData.fromMap(Map<Object?, Object?>.from(event)));
  }

  void _onError(Object error) {
    debugPrint('ble_core event error: $error');
  }

  void _emit(BoschLiveData d) {
    if (!_controller.isClosed) _controller.add(d);
  }

  void _startStub() {
    _stubTimer?.cancel();
    _stubTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _odo += 0.01;
      _emit(
        BoschLiveData(
          speedKmh: 22.4,
          batterySocPercent: null,
          riderPowerW: null,
          cadenceRpm: 78,
          odometerKm: _odo,
          lightStatus: false,
          ambientBrightness: 62,
          systemLock: false,
          bikeNotDriving: false,
          chargerConnected: false,
          timestampMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    });
  }

  Future<void> dispose() async {
    await disconnect();
    await _controller.close();
    await _bikeScanController.close();
    await _watchScanController.close();
  }
}
