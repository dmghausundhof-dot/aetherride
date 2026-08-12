import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/ble.dart';
import '../domain/ble/csc_measurement.dart';
import 'native_channels.dart';

enum BlePermissionResult {
  granted,
  adapterOff,
  denied,
  unsupported,
}

final _cscServiceGuid = Guid('00001816-0000-1000-8000-00805f9b34fb');

/// Standard BLE CSC (0x1816) + Bosch LDI shell (behind G-1).
/// Power Meter / HR are not implemented — do not invent SoC or power from cadence.
class BleCoreChannel {
  BleCoreChannel({
    MethodChannel? method,
    EventChannel? events,
  })  : _method = method ?? const MethodChannel(NativeChannels.bleCore),
        _events =
            events ?? const EventChannel('${NativeChannels.bleCore}/ldi');

  final MethodChannel _method;
  final EventChannel _events;

  StreamSubscription<dynamic>? _sub;
  StreamSubscription<List<int>>? _cscSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  final _controller = StreamController<BoschLiveData>.broadcast();
  bool _connected = false;
  bool _cscOnly = false;
  bool _wantConnection = false;
  Timer? _stubTimer;
  Timer? _reconnectTimer;
  double _odo = 1247.4;
  double _speed = 0;
  double _cadence = 0;
  int? _prevWheelRevs;
  int? _prevWheelEventTime;
  int? _prevCrankRevs;
  int? _prevCrankEventTime;
  BluetoothDevice? _device;
  String? _lastRemoteId;
  String? _statusDetail;

  /// Default ~29×2.25 / gravel-ish; garage wheel size can override.
  double wheelCircumferenceM = 2.105;

  Stream<BoschLiveData> get liveData => _controller.stream;
  bool get isConnected => _connected;
  bool get isCscOnly => _cscOnly;
  String? get statusDetail => _statusDetail;
  String? get lastRemoteId => _lastRemoteId;

  /// Platform-Name des verbundenen CSC-/LDI-Geräts (Garage-Speicher / HUD).
  String? get connectedDeviceName {
    final n = _device?.platformName.trim();
    if (n == null || n.isEmpty) return null;
    return n;
  }

  /// Request Android 12+ BLE runtime permissions via a short probe scan.
  Future<BlePermissionResult> ensurePermission() async {
    try {
      final supported = await FlutterBluePlus.isSupported;
      if (!supported) return BlePermissionResult.unsupported;
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
        await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 2),
          withServices: [_cscServiceGuid],
        );
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
        if (_connected) 'connected',
        'speed',
        'cadence',
      };

  Future<bool> connect({String? deviceId}) async {
    _wantConnection = true;
    _statusDetail = null;
    await _loadLastRemoteId();

    try {
      final adapterOn =
          await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
      if (adapterOn) {
        final ok = await _connectStandardBle(
          preferredId: deviceId ?? _lastRemoteId,
        );
        if (ok) return true;
      } else {
        _statusDetail = 'Bluetooth aus';
      }
    } catch (e) {
      debugPrint('ble_core standard BLE: $e');
      _statusDetail = 'Radsensor-Suche fehlgeschlagen';
    }

    try {
      final ok = await _method.invokeMethod<bool>('connect', {
        'deviceId': deviceId,
        'serviceUuid': boschLdiServiceUuid,
      });
      _connected = ok ?? false;
      if (_connected) {
        _cscOnly = false;
        _sub ??=
            _events.receiveBroadcastStream().listen(_onEvent, onError: _onError);
      }
      return _connected;
    } on MissingPluginException {
      const sim = bool.fromEnvironment('AETHER_LDI_SIM', defaultValue: false);
      if (kDebugMode && sim) {
        debugPrint('ble_core: LDI Plugin fehlt — Simulator (AETHER_LDI_SIM)');
        _connected = true;
        _cscOnly = false;
        _startStub();
        return true;
      }
      debugPrint(
        'ble_core: LDI unavailable (G-1 pending) — stay disconnected',
      );
      _connected = false;
      _statusDetail ??= 'Kein Radsensor gefunden';
      return false;
    }
  }

  Future<bool> _connectStandardBle({String? preferredId}) async {
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      return false;
    }

    // 1) Prefer known device (saved / preferred).
    if (preferredId != null && preferredId.isNotEmpty) {
      try {
        final known = BluetoothDevice.fromId(preferredId);
        final ok = await _attachCscDevice(known);
        if (ok) return true;
      } catch (e) {
        debugPrint('ble_core preferred reconnect: $e');
      }
    }

    // 2) Already connected / system devices with CSC.
    try {
      final system = await FlutterBluePlus.systemDevices([_cscServiceGuid]);
      for (final d in system) {
        final ok = await _attachCscDevice(d);
        if (ok) return true;
      }
    } catch (_) {}

    try {
      for (final d in FlutterBluePlus.connectedDevices) {
        final ok = await _attachCscDevice(d);
        if (ok) return true;
      }
    } catch (_) {}

    // 3) Active scan filtered by CSC service UUID (not AD heuristic alone).
    BluetoothDevice? target;
    final sub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final uuids = r.advertisementData.serviceUuids;
        final hasCsc = uuids.any(
          (u) => u.toString().toLowerCase().contains('1816'),
        );
        // Also accept strong names if service list empty (many Magene/Wahoo).
        final name = r.device.platformName.toLowerCase();
        final nameHint = name.contains('cadence') ||
            name.contains('speed') ||
            name.contains('csc') ||
            name.contains('wahoo') ||
            name.contains('magene') ||
            name.contains('coospo') ||
            name.contains('igpsport');
        if (hasCsc || (uuids.isEmpty && nameHint && r.rssi > -90)) {
          target ??= r.device;
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(
        withServices: [_cscServiceGuid],
        timeout: const Duration(seconds: 8),
      );
    } catch (_) {
      // Fallback: unfiltered scan if withServices fails on some OEMs.
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    }

    final deadline = DateTime.now().add(const Duration(seconds: 8));
    while (target == null && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    await FlutterBluePlus.stopScan();
    await sub.cancel();

    // 4) Last-resort: any scan result advertising 1816 from lastScanResults.
    if (target == null) {
      for (final r in FlutterBluePlus.lastScanResults) {
        if (r.advertisementData.serviceUuids
            .any((u) => u.toString().toLowerCase().contains('1816'))) {
          target = r.device;
          break;
        }
      }
    }

    if (target == null) {
      _statusDetail = 'Kein Radsensor in Reichweite';
      return false;
    }

    return _attachCscDevice(target!);
  }

  Future<bool> _attachCscDevice(BluetoothDevice device) async {
    try {
      if (device.isDisconnected) {
        await device.connect(
          timeout: const Duration(seconds: 12),
          autoConnect: false,
        );
      }
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
      // Fallback: first notify char in CSC service.
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
      if (measurement == null) {
        _statusDetail = 'Radsensor gefunden, aber ohne Messwert';
        try {
          await device.disconnect();
        } catch (_) {}
        return false;
      }

      await _cscSub?.cancel();
      await measurement.setNotifyValue(true);
      _cscSub = measurement.lastValueStream.listen(_onCscBytes);

      await _connSub?.cancel();
      _connSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _connected = false;
          _statusDetail = 'Radsensor getrennt';
          if (_wantConnection) _scheduleReconnect();
        } else if (state == BluetoothConnectionState.connected) {
          _connected = true;
          _statusDetail = 'Radsensor verbunden';
        }
      });

      _device = device;
      _lastRemoteId = device.remoteId.str;
      await _saveLastRemoteId(_lastRemoteId!);
      _connected = true;
      _cscOnly = true;
      _statusDetail = 'Radsensor verbunden · ${device.platformName}';
      _startCscTicker();
      return true;
    } catch (e) {
      debugPrint('ble_core attach: $e');
      _statusDetail = 'Radsensor-Verbindung fehlgeschlagen';
      return false;
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () async {
      if (!_wantConnection || _connected) return;
      final id = _lastRemoteId;
      if (id == null) return;
      _statusDetail = 'Radsensor verbindet erneut …';
      try {
        final ok = await _attachCscDevice(BluetoothDevice.fromId(id));
        if (!ok && _wantConnection && !_connected) {
          _reconnectTimer = Timer(const Duration(seconds: 8), _scheduleReconnect);
        }
      } catch (e) {
        debugPrint('ble_core reconnect: $e');
        if (_wantConnection && !_connected) {
          _reconnectTimer = Timer(const Duration(seconds: 8), _scheduleReconnect);
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

  void _startCscTicker() {
    _stubTimer?.cancel();
    _stubTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _emit(
        BoschLiveData(
          speedKmh: _speed,
          batterySocPercent: null,
          riderPowerW: null,
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

  Future<void> disconnect() async {
    _wantConnection = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _stubTimer?.cancel();
    await _cscSub?.cancel();
    _cscSub = null;
    await _connSub?.cancel();
    _connSub = null;
    _connected = false;
    _cscOnly = false;
    _prevWheelRevs = null;
    _prevWheelEventTime = null;
    _prevCrankRevs = null;
    _prevCrankEventTime = null;
    _speed = 0;
    _cadence = 0;
    _statusDetail = null;
    try {
      await _device?.disconnect();
    } catch (_) {}
    _device = null;
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
      final f = File(p.join(dir.path, 'ble_last_csc_id.txt'));
      if (await f.exists()) {
        final id = (await f.readAsString()).trim();
        if (id.isNotEmpty) _lastRemoteId = id;
      }
    } catch (_) {}
  }

  Future<void> _saveLastRemoteId(String id) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File(p.join(dir.path, 'ble_last_csc_id.txt'));
      await f.writeAsString(id);
    } catch (_) {}
  }

  void _onEvent(dynamic event) {
    if (event is! Map) return;
    _cscOnly = false;
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
  }
}
