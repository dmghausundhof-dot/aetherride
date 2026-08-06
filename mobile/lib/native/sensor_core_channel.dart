import 'dart:async';
import 'dart:math' as math;

import 'package:dsp_core/dsp_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/sensor.dart';
import 'native_channels.dart';

/// Dart-Seite von `sensor_core`.
/// Native: Ringpuffer → 1-s-Blöcke. DSP via dsp_core (Rust FFI oder Dart-Fallback).
class SensorCoreChannel {
  SensorCoreChannel({
    MethodChannel? method,
    EventChannel? events,
    DspEngine? dsp,
  })  : _method = method ?? const MethodChannel(NativeChannels.sensorCore),
        _events = events ??
            const EventChannel('${NativeChannels.sensorCore}/blocks'),
        _dsp = dsp ?? DspEngine();

  final MethodChannel _method;
  final EventChannel _events;
  final DspEngine _dsp;

  StreamSubscription<dynamic>? _sub;
  final _controller = StreamController<SensorBlock>.broadcast();
  Timer? _stubTimer;

  Stream<SensorBlock> get blocks => _controller.stream;

  Future<void> start({int sampleRateHz = 100}) async {
    try {
      await _method.invokeMethod<void>('start', {'sampleRateHz': sampleRateHz});
      _sub ??=
          _events.receiveBroadcastStream().listen(_onEvent, onError: _onError);
    } on MissingPluginException {
      debugPrint('sensor_core: Plugin fehlt — Stub + dsp_core');
      _startStub(sampleRateHz);
    }
  }

  Future<void> stop() async {
    _stubTimer?.cancel();
    _stubTimer = null;
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

    FusedMetrics? fused;
    final rawSamples = map['samples'];
    if (rawSamples is List && rawSamples.isNotEmpty) {
      final samples = <DspSample>[];
      for (final s in rawSamples) {
        if (s is! Map) continue;
        samples.add(
          DspSample(
            tMs: (s['t'] as num?)?.toInt() ?? 0,
            ax: (s['ax'] as num?)?.toDouble() ?? 0,
            ay: (s['ay'] as num?)?.toDouble() ?? 0,
            az: (s['az'] as num?)?.toDouble() ?? 9.81,
            gx: (s['gx'] as num?)?.toDouble() ?? 0,
            gy: (s['gy'] as num?)?.toDouble() ?? 0,
            gz: (s['gz'] as num?)?.toDouble() ?? 0,
          ),
        );
      }
      final d = _dsp.fuseBlock(samples);
      if (d != null) {
        fused = FusedMetrics(
          timestampMs: d.timestampMs,
          gForcePeak: d.gForcePeak,
          gForceRms: d.gForceRms,
          leanAngleDeg: d.leanAngleDeg,
          impactDetected: d.impactDetected,
          impactMagnitude: d.impactMagnitude,
          flowContribution: d.flowContribution,
        );
      }
    } else {
      fused = FusedMetrics(
        timestampMs: end,
        gForcePeak: (map['gForcePeak'] as num?)?.toDouble() ?? 1.0,
        gForceRms: (map['gForceRms'] as num?)?.toDouble() ?? 1.0,
        leanAngleDeg: (map['leanAngleDeg'] as num?)?.toDouble() ?? 0,
        impactDetected: map['impactDetected'] == true,
        impactMagnitude: (map['impactMagnitude'] as num?)?.toDouble() ?? 0,
        flowContribution: (map['flowContribution'] as num?)?.toDouble() ?? 0.5,
      );
    }

    _controller.add(
      SensorBlock(
        windowStartMs: start,
        windowEndMs: end,
        sampleRateHz: rate,
        samples: const [],
        fused: fused,
      ),
    );
  }

  void _onError(Object error) {
    debugPrint('sensor_core event error: $error');
  }

  void _startStub(int sampleRateHz) {
    _stubTimer?.cancel();
    final rnd = math.Random();
    _stubTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final samples = <DspSample>[];
      for (var i = 0; i < sampleRateHz; i++) {
        final t = now - 1000 + (i * (1000 ~/ sampleRateHz));
        samples.add(
          DspSample(
            tMs: t,
            ax: rnd.nextDouble() * 0.4 - 0.2,
            ay: rnd.nextDouble() * 0.4 - 0.2,
            az: 9.81 + rnd.nextDouble() * 0.3,
            gx: 0,
            gy: 0,
            gz: 0,
          ),
        );
      }
      // occasional impact
      if (rnd.nextDouble() < 0.05) {
        samples[sampleRateHz ~/ 2] = DspSample(
          tMs: samples[sampleRateHz ~/ 2].tMs,
          ax: 0,
          ay: 0,
          az: 9.81 * 4.2,
          gx: 0,
          gy: 0,
          gz: 0,
        );
      }
      final d = _dsp.fuseBlock(samples)!;
      _controller.add(
        SensorBlock(
          windowStartMs: now - 1000,
          windowEndMs: now,
          sampleRateHz: sampleRateHz,
          samples: const [],
          fused: FusedMetrics(
            timestampMs: d.timestampMs,
            gForcePeak: d.gForcePeak,
            gForceRms: d.gForceRms,
            leanAngleDeg: d.leanAngleDeg,
            impactDetected: d.impactDetected,
            impactMagnitude: d.impactMagnitude,
            flowContribution: d.flowContribution,
          ),
        ),
      );
    });
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}
