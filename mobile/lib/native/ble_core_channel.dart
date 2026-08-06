import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/ble.dart';
import 'native_channels.dart';

/// Dart-Seite von `ble_core` (Bosch LDI read-only).
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
  final _controller = StreamController<BoschLiveData>.broadcast();
  bool _connected = false;

  Stream<BoschLiveData> get liveData => _controller.stream;
  bool get isConnected => _connected;

  Future<bool> connect({String? deviceId}) async {
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
      debugPrint('ble_core: Plugin fehlt — Simulator aktiv');
      _connected = true;
      _startStub();
      return true;
    }
  }

  Future<void> disconnect() async {
    _stubTimer?.cancel();
    await _sub?.cancel();
    _sub = null;
    _connected = false;
    try {
      await _method.invokeMethod<void>('disconnect');
    } on MissingPluginException {
      // ignore
    }
  }

  void _onEvent(dynamic event) {
    if (event is! Map) return;
    _controller.add(BoschLiveData.fromMap(Map<Object?, Object?>.from(event)));
  }

  void _onError(Object error) {
    debugPrint('ble_core event error: $error');
  }

  Timer? _stubTimer;
  double _soc = 87;
  double _odo = 1247.4;

  void _startStub() {
    _stubTimer?.cancel();
    _stubTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _soc = (_soc - 0.01).clamp(5, 100);
      _odo += 0.01;
      _controller.add(
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
