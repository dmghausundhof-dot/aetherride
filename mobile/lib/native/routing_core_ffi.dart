import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// Dart binding for routing_core Valhalla FFI (S7 scaffold).
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
        _lib = DynamicLibrary.open('librouting_core.so');
      } else if (Platform.isIOS || Platform.isMacOS) {
        _lib = DynamicLibrary.process();
      } else if (Platform.isLinux) {
        _lib = DynamicLibrary.open('librouting_core.so');
      }
    } catch (_) {
      _lib = null;
    }
  }

  /// Returns null when offline FFI is not linked (use RoutingClient HTTP).
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
    try {
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
      try {
        req.ref
          ..fromLat = fromLat
          ..fromLng = fromLng
          ..toLat = toLat
          ..toLng = toLng
          ..profile = profilePtr.cast()
          ..tilesPath = tilesPtr.cast();
        final code = fn(req, out, nullptr, 0);
        if (code != 0) return null;
        return OfflineRouteResult(
          distanceM: out.ref.distanceM,
          durationS: out.ref.durationS,
        );
      } finally {
        calloc.free(req);
        calloc.free(out);
        calloc.free(profilePtr);
        calloc.free(tilesPtr);
      }
    } catch (_) {
      return null;
    }
  }
}

class OfflineRouteResult {
  const OfflineRouteResult({
    required this.distanceM,
    required this.durationS,
  });
  final double distanceM;
  final double durationS;
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
