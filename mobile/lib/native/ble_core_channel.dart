import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../domain/ble.dart';
import '../domain/ble/csc_measurement.dart';
import 'native_channels.dart';

enum BlePermissionResult {
  granted,
  adapterOff,
  denied,
  unsupported,
}

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
  final _controller = StreamController<BoschLiveData>.broadcast();
  bool _connected = false;
  /// True when live data comes from CSC only (no LDI SoC/power).
  bool _cscOnly = false;
  Timer? _stubTimer;
  double _soc = 87;
  double _odo = 1247.4;
  double _speed = 0;
  double _cadence = 0;
  int? _prevWheelRevs;
  int? _prevWheelEventTime;
  int? _prevCrankRevs;
  int? _prevCrankEventTime;

  /// Default ~29×2.25 / gravel-ish; garage wheel size can override later.
  double wheelCircumferenceM = 2.105;

  Stream<BoschLiveData> get liveData => _controller.stream;
  bool get isConnected => _connected;
  bool get isCscOnly => _cscOnly;

  /// Request Android 12+ BLE runtime permissions via a short probe scan.
  /// Does not require a sensor — Freeride remains usable without CSC.
  Future<BlePermissionResult> ensurePermission() async {
    try {
      final supported = await FlutterBluePlus.isSupported;
      if (!supported) return BlePermissionResult.unsupported;
      var state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        try {
          await FlutterBluePlus.turnOn();
          state = await FlutterBluePlus.adapterState.first;
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
        );
        await FlutterBluePlus.stopScan();
        return BlePermissionResult.granted;
      } catch (e) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('permission') || msg.contains('denied')) {
          return BlePermissionResult.denied;
        }
        // Adapter on but no devices / scan quirk — treat as usable.
        return BlePermissionResult.granted;
      }
    } catch (_) {
      return BlePermissionResult.unsupported;
    }
  }

  /// Capabilities for UI (Spec F-EBK MotorAdapter).
  Set<String> get capabilities => {
        if (_connected) 'connected',
        'speed',
        'cadence',
        // LDI / Power Meter not wired yet:
        // 'power', 'batterySoc', 'lightStatus', …
      };

  Future<bool> connect({String? deviceId}) async {
    // Prefer Standard BLE CSC when Bluetooth is on.
    try {
      final adapterOn = await FlutterBluePlus.isSupported;
      if (adapterOn) {
        final ok = await _connectStandardBle();
        if (ok) return true;
      }
    } catch (e) {
      debugPrint('ble_core standard BLE: $e');
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
      // LDI stub only in debug + explicit dart-define (never in release).
      // CSC path above is unchanged. See packages/ble_core/README.md (G-1).
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
      return false;
    }
  }

  Future<bool> _connectStandardBle() async {
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      return false;
    }
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    await Future<void>.delayed(const Duration(seconds: 4));
    await FlutterBluePlus.stopScan();

    // CSC service UUID 0x1816 only (no Power 0x1818 / HR 0x180D yet).
    BluetoothDevice? target;
    for (final r in FlutterBluePlus.lastScanResults) {
      if (r.advertisementData.serviceUuids
          .any((u) => u.toString().toLowerCase().contains('1816'))) {
        target = r.device;
        break;
      }
    }
    if (target == null) return false;

    await target.connect(timeout: const Duration(seconds: 8));
    final services = await target.discoverServices();
    for (final s in services) {
      if (!s.uuid.toString().toLowerCase().contains('1816')) continue;
      for (final c in s.characteristics) {
        if (c.properties.notify) {
          await c.setNotifyValue(true);
          _cscSub = c.lastValueStream.listen(_onCscBytes);
        }
      }
    }
    _connected = true;
    _cscOnly = true;
    _startCscTicker();
    return true;
  }

  /// BLE CSC Measurement (0x2A5B) — flags + optional wheel/crank fields.
  /// Speed only from wheel revs; cadence only from crank. No invented SoC/power.
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

  /// CSC-only telemetry: speed + cadence. SoC/Power stay null (no LDI).
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
    _stubTimer?.cancel();
    await _cscSub?.cancel();
    _cscSub = null;
    await _sub?.cancel();
    _sub = null;
    _connected = false;
    _cscOnly = false;
    _prevWheelRevs = null;
    _prevWheelEventTime = null;
    _prevCrankRevs = null;
    _prevCrankEventTime = null;
    _speed = 0;
    _cadence = 0;
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
      _soc = (_soc - 0.01).clamp(5, 100);
      _odo += 0.01;
      _emit(
        BoschLiveData(
          speedKmh: 22.4,
          batterySocPercent: _soc,
          riderPowerW: 180,
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
