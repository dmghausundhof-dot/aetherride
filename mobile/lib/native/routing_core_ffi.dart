import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// Result codes — keep in sync with `routing_core` Rust crate.
abstract final class RoutingCoreCodes {
  static const ok = 0;
  static const valhallaUnlinked = 1;
  static const invalidArgs = 2;
  static const noTiles = 3;
  static const noRoute = 4;
  static const bufferTooSmall = 5;
  static const unknownProfile = 6;
}

/// Dart binding for routing_core offline FFI (Spec §5.1 / §5.4).
///
/// Android: expects `librouting_core.so` in jniLibs (plus `libprotobuf.so` /
/// `libc++_shared.so` when built with `--features valhalla`). Install via
/// `scripts/routing/install-android-jni.sh`.
class RoutingCoreFfi {
  DynamicLibrary? _lib;
  bool _tried = false;

  bool get available {
    _ensure();
    return _lib != null;
  }

  void _ensure() {
    if (_tried) return;
    _tried = true;
    try {
      if (Platform.isAndroid) {
        _preloadAndroidDeps();
        _lib = DynamicLibrary.open('librouting_core.so');
      } else if (Platform.isIOS || Platform.isMacOS) {
        _lib = DynamicLibrary.process();
      } else if (Platform.isLinux) {
        final env = Platform.environment['ROUTING_CORE_LIB'];
        if (env != null && File(env).existsSync()) {
          _lib = DynamicLibrary.open(env);
        } else {
          _lib = DynamicLibrary.open('librouting_core.so');
        }
      }
    } catch (_) {
      _lib = null;
    }
  }

  /// Load DT_NEEDED partners before routing_core (same jniLibs ABI folder).
  static void _preloadAndroidDeps() {
    for (final name in ['libc++_shared.so', 'libprotobuf.so']) {
      try {
        DynamicLibrary.open(name);
      } catch (_) {
        // graph-only builds omit protobuf; c++_shared may already be loaded.
      }
    }
  }

  bool tilesOk(String tilesPath) {
    _ensure();
    if (_lib == null) return false;
    try {
      final fn = _lib!.lookupFunction<Int32 Function(Pointer<Utf8>), int Function(Pointer<Utf8>)>(
        'routing_core_tiles_ok',
      );
      final p = tilesPath.toNativeUtf8();
      try {
        return fn(p) == 1;
      } finally {
        calloc.free(p);
      }
    } catch (_) {
      return false;
    }
  }

  /// `"offline_graph"` | `"valhalla"` | `"none"` | `null` if native missing.
  String? engineForTiles(String tilesPath) {
    _ensure();
    if (_lib == null) return null;
    try {
      final fn = _lib!.lookupFunction<Pointer<Utf8> Function(Pointer<Utf8>), Pointer<Utf8> Function(Pointer<Utf8>)>(
        'routing_core_engine_for_tiles',
      );
      final p = tilesPath.toNativeUtf8();
      try {
        final r = fn(p);
        if (r == nullptr) return 'none';
        return r.toDartString();
      } finally {
        calloc.free(p);
      }
    } catch (_) {
      return null;
    }
  }

  /// Offline route. Returns null if native lib missing; throws [RoutingCoreException] on error codes.
  OfflineRouteResult? tryOfflineRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    required String profile,
    required String tilesPath,
  }) {
    _ensure();
    if (_lib == null) return null;

    final fn = _lib!.lookupFunction<
        Int32 Function(
          Pointer<_RouteRequest>,
          Pointer<_RouteSummary>,
          Pointer<Double>,
          Uint32,
        ),
        int Function(
          Pointer<_RouteRequest>,
          Pointer<_RouteSummary>,
          Pointer<Double>,
          int,
        )>('routing_core_route');

    final req = calloc<_RouteRequest>();
    final out = calloc<_RouteSummary>();
    final profilePtr = profile.toNativeUtf8();
    final tilesPtr = tilesPath.toNativeUtf8();
    final engine = engineForTiles(tilesPath) ?? 'offline_graph';

    try {
      req.ref
        ..fromLat = fromLat
        ..fromLng = fromLng
        ..toLat = toLat
        ..toLng = toLng
        ..profile = profilePtr.cast()
        ..tilesPath = tilesPtr.cast();

      var code = fn(req, out, nullptr, 0);
      if (code == RoutingCoreCodes.bufferTooSmall || code == RoutingCoreCodes.ok) {
        final n = out.ref.coordinateCount;
        if (n == 0 && code == RoutingCoreCodes.ok) {
          return OfflineRouteResult(
            distanceM: out.ref.distanceM,
            durationS: out.ref.durationS,
            coordinatesLngLat: const [],
            engine: engine,
          );
        }
        final buf = calloc<Double>(n * 2);
        try {
          code = fn(req, out, buf, n);
          if (code != RoutingCoreCodes.ok) {
            throw RoutingCoreException(code);
          }
          final coords = <List<double>>[];
          for (var i = 0; i < out.ref.coordinateCount; i++) {
            coords.add([buf[i * 2], buf[i * 2 + 1]]);
          }
          return OfflineRouteResult(
            distanceM: out.ref.distanceM,
            durationS: out.ref.durationS,
            coordinatesLngLat: coords,
            engine: engine,
          );
        } finally {
          calloc.free(buf);
        }
      }
      throw RoutingCoreException(code);
    } finally {
      calloc.free(req);
      calloc.free(out);
      calloc.free(profilePtr);
      calloc.free(tilesPtr);
    }
  }
}

class RoutingCoreException implements Exception {
  RoutingCoreException(this.code);
  final int code;

  @override
  String toString() {
    final name = switch (code) {
      RoutingCoreCodes.valhallaUnlinked => 'VALHALLA_UNLINKED',
      RoutingCoreCodes.invalidArgs => 'INVALID_ARGS',
      RoutingCoreCodes.noTiles => 'NO_TILES',
      RoutingCoreCodes.noRoute => 'NO_ROUTE',
      RoutingCoreCodes.bufferTooSmall => 'BUFFER_TOO_SMALL',
      RoutingCoreCodes.unknownProfile => 'UNKNOWN_PROFILE',
      _ => 'CODE_$code',
    };
    return 'RoutingCoreException($name)';
  }
}

class OfflineRouteResult {
  const OfflineRouteResult({
    required this.distanceM,
    required this.durationS,
    required this.coordinatesLngLat,
    this.engine = 'offline_graph',
  });

  final double distanceM;
  final double durationS;
  /// Each entry: [lng, lat]
  final List<List<double>> coordinatesLngLat;
  final String engine;
}

final class _RouteRequest extends Struct {
  @Double()
  external double fromLat;
  @Double()
  external double fromLng;
  @Double()
  external double toLat;
  @Double()
  external double toLng;
  external Pointer<Char> profile;
  external Pointer<Char> tilesPath;
}

final class _RouteSummary extends Struct {
  @Double()
  external double distanceM;
  @Double()
  external double durationS;
  @Uint32()
  external int coordinateCount;
}
