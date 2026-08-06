import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../domain/ble.dart';
import 'native_channels.dart';

/// Standard BLE (CSC / Power / HR) + Bosch LDI shell (behind G-1).
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
  Timer? _stubTimer;
  double _soc = 87;
  double _odo = 1247.4;
  double _speed = 0;
  double _cadence = 0;
  final double _power = 0;

  Stream<BoschLiveData> get liveData => _controller.stream;
  bool get isConnected => _connected;

  /// Capabilities for UI (Spec F-EBK MotorAdapter).
  Set<String> get capabilities => {
        if (_connected) 'connected',
        'speed',
        'cadence',
        'power',
        // LDI fields only after G-1 native plugin:
        // 'batterySoc', 'lightStatus', …
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
        _sub ??=
            _events.receiveBroadcastStream().listen(_onEvent, onError: _onError);
      }
      return _connected;
    } on MissingPluginException {
      debugPrint('ble_core: LDI Plugin fehlt — Simulator');
      _connected = true;
      _startStub();
      return true;
    }
  }

  Future<bool> _connectStandardBle() async {
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      return false;
    }
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    await Future<void>.delayed(const Duration(seconds: 4));
    await FlutterBluePlus.stopScan();

    // CSC service UUID 0x1816
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
    _startTelemetryTicker();
    return true;
  }

  void _onCscBytes(List<int> data) {
    if (data.length < 5) return;
    // Simplified CSC parse — wheel/crank revs (demo mapping)
    _cadence = (data[1] + data[2] * 256) % 120 + 40;
    _speed = _cadence * 0.28;
  }

  void _startTelemetryTicker() {
    _stubTimer?.cancel();
    _stubTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _emit(
        BoschLiveData(
          speedKmh: _speed,
          batterySocPercent: _soc,
          riderPowerW: _power > 0 ? _power : _cadence * 2.2,
          cadenceRpm: _cadence,
          odometerKm: _odo,
          lightStatus: false,
          ambientBrightness: 50,
          systemLock: false,
          bikeNotDriving: _speed < 1,
          chargerConnected: false,
          timestampMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      _odo += _speed / 7200;
    });
  }

  Future<void> disconnect() async {
    _stubTimer?.cancel();
    await _cscSub?.cancel();
    _cscSub = null;
    await _sub?.cancel();
    _sub = null;
    _connected = false;
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
