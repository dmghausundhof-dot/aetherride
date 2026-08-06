import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/sensor.dart';
import 'native_channels.dart';

/// Dart-Seite von `sensor_core`.
/// Produktion: native Ringpuffer → EventChannel mit 1-s-Blöcken.
/// Scaffold: Stub/Simulator ohne Method-Channel-Samples.
class SensorCoreChannel {
  SensorCoreChannel({
    MethodChannel? method,
    EventChannel? events,
  })  : _method = method ?? const MethodChannel(NativeChannels.sensorCore),
        _events = events ??
            const EventChannel('${NativeChannels.sensorCore}/blocks');

  final MethodChannel _method;
  final EventChannel _events;

  StreamSubscription<dynamic>? _sub;
  final _controller = StreamController<SensorBlock>.broadcast();

  Stream<SensorBlock> get blocks => _controller.stream;

  Future<void> start({int sampleRateHz = 100}) async {
    try {
      await _method.invokeMethod<void>('start', {'sampleRateHz': sampleRateHz});
      _sub ??= _events.receiveBroadcastStream().listen(_onEvent, onError: _onError);
    } on MissingPluginException {
      debugPrint('sensor_core: Plugin fehlt — Stub-Stream aktiv');
      _startStub(sampleRateHz);
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await _method.invokeMethod<void>('stop');
    } on MissingPluginException {
      // ignore
    }
  }

  void _onEvent(dynamic event) {
    if (event is! Map) return;
    final map = Map<Object?, Object?>.from(event);
    final start = (map['windowStartMs'] as num?)?.toInt() ?? 0;
    final end = (map['windowEndMs'] as num?)?.toInt() ?? start + 1000;
    final rate = (map['sampleRateHz'] as num?)?.toInt() ?? 100;
    _controller.add(
      SensorBlock(
        windowStartMs: start,
        windowEndMs: end,
        sampleRateHz: rate,
        samples: const [],
        fused: FusedMetrics(
          timestampMs: end,
          gForcePeak: (map['gForcePeak'] as num?)?.toDouble() ?? 1.0,
          gForceRms: (map['gForceRms'] as num?)?.toDouble() ?? 1.0,
          leanAngleDeg: (map['leanAngleDeg'] as num?)?.toDouble() ?? 0,
          impactDetected: map['impactDetected'] == true,
          impactMagnitude: (map['impactMagnitude'] as num?)?.toDouble() ?? 0,
          flowContribution: (map['flowContribution'] as num?)?.toDouble() ?? 0.5,
        ),
      ),
    );
  }

  void _onError(Object error) {
    debugPrint('sensor_core event error: $error');
  }

  Timer? _stubTimer;

  void _startStub(int sampleRateHz) {
    _stubTimer?.cancel();
    _stubTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now().millisecondsSinceEpoch;
      _controller.add(
        SensorBlock(
          windowStartMs: now - 1000,
          windowEndMs: now,
          sampleRateHz: sampleRateHz,
          samples: const [],
          fused: FusedMetrics(
            timestampMs: now,
            gForcePeak: 1.1,
            gForceRms: 1.0,
            leanAngleDeg: 3.2,
            impactDetected: false,
            impactMagnitude: 0,
            flowContribution: 0.72,
          ),
        ),
      );
    });
  }

  Future<void> dispose() async {
    _stubTimer?.cancel();
    await stop();
    await _controller.close();
  }
}
