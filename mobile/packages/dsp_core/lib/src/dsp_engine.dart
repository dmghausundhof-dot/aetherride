import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;

import 'package:ffi/ffi.dart';

import 'models.dart';

/// Loads native `libdsp_core` when present; otherwise pure-Dart fallback.
class DspEngine {
  DspEngine({
    this.impactThresholdG = 2.8,
    this.leanAlpha = 0.15,
  });

  final double impactThresholdG;
  final double leanAlpha;
  double _lastLean = 0;
  DynamicLibrary? _lib;
  bool _triedNative = false;

  bool get usingNative => _lib != null;

  void _ensureLib() {
    if (_triedNative) return;
    _triedNative = true;
    try {
      if (Platform.isAndroid) {
        _lib = DynamicLibrary.open('libdsp_core.so');
      } else if (Platform.isIOS || Platform.isMacOS) {
        _lib = DynamicLibrary.process();
      } else if (Platform.isLinux) {
        _lib = DynamicLibrary.open('libdsp_core.so');
      }
    } catch (_) {
      _lib = null;
    }
  }

  DspFused? fuseBlock(List<DspSample> samples) {
    if (samples.length < 5) return null;
    _ensureLib();
    if (_lib != null) {
      final native = _fuseNative(samples);
      if (native != null) return native;
    }
    return _fuseDart(samples);
  }

  DspFused _fuseDart(List<DspSample> samples) {
    const g = 9.81;
    final gForces = samples.map((s) {
      return math.sqrt(s.ax * s.ax + s.ay * s.ay + s.az * s.az) / g;
    }).toList();
    final gPeak = gForces.reduce(math.max);
    final mean = gForces.reduce((a, b) => a + b) / gForces.length;
    final variance =
        gForces.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
            gForces.length;
    final gRms = math.sqrt(variance);
    final latest = samples.last;
    final accelLean = math.atan2(latest.ay, latest.az) * 180 / math.pi;
    final lean = leanAlpha * accelLean + (1 - leanAlpha) * _lastLean;
    _lastLean = lean;
    final impact = gPeak >= impactThresholdG;
    final flow = (1 / (1 + gRms * 2)).clamp(0.0, 1.0);
    return DspFused(
      timestampMs: latest.tMs,
      gForcePeak: gPeak,
      gForceRms: gRms,
      leanAngleDeg: lean,
      impactDetected: impact,
      impactMagnitude: impact ? gPeak : 0,
      flowContribution: flow,
    );
  }

  DspFused? _fuseNative(List<DspSample> samples) {
    try {
      final fuse = _lib!.lookupFunction<
          Int32 Function(
            Pointer<_RawSample>,
            Size,
            Double,
            Double,
            Pointer<_FusedOut>,
          ),
          int Function(
            Pointer<_RawSample>,
            int,
            double,
            double,
            Pointer<_FusedOut>,
          )>('dsp_fuse_block');

      final n = samples.length;
      final ptr = calloc<_RawSample>(n);
      final out = calloc<_FusedOut>();
      try {
        for (var i = 0; i < n; i++) {
          final s = samples[i];
          ptr[i]
            ..tMs = s.tMs
            ..ax = s.ax
            ..ay = s.ay
            ..az = s.az
            ..gx = s.gx
            ..gy = s.gy
            ..gz = s.gz;
        }
        final ok = fuse(ptr, n, impactThresholdG, leanAlpha, out);
        if (ok == 0) return null;
        return DspFused(
          timestampMs: out.ref.timestampMs,
          gForcePeak: out.ref.gForcePeak,
          gForceRms: out.ref.gForceRms,
          leanAngleDeg: out.ref.leanAngleDeg,
          impactDetected: out.ref.impactDetected != 0,
          impactMagnitude: out.ref.impactMagnitude,
          flowContribution: out.ref.flowContribution,
        );
      } finally {
        calloc.free(ptr);
        calloc.free(out);
      }
    } catch (_) {
      return null;
    }
  }
}

final class _RawSample extends Struct {
  @Int64()
  external int tMs;
  @Double()
  external double ax;
  @Double()
  external double ay;
  @Double()
  external double az;
  @Double()
  external double gx;
  @Double()
  external double gy;
  @Double()
  external double gz;
}

final class _FusedOut extends Struct {
  @Int64()
  external int timestampMs;
  @Double()
  external double gForcePeak;
  @Double()
  external double gForceRms;
  @Double()
  external double leanAngleDeg;
  @Int32()
  external int impactDetected;
  @Double()
  external double impactMagnitude;
  @Double()
  external double flowContribution;
}
