import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// GPS / Fused-Location für Ride-Tracking.
/// Android: natives Foreground Service via Platform Channel; sonst Geolocator-Fallback.
class LocationFix {
  const LocationFix({
    required this.lat,
    required this.lng,
    required this.accuracyM,
    required this.speedMps,
    required this.altitudeM,
    required this.timestamp,
  });

  final double lat;
  final double lng;
  final double accuracyM;
  final double speedMps;
  final double altitudeM;
  final DateTime timestamp;
}

enum LocationPermissionResult {
  granted,
  servicesDisabled,
  denied,
  deniedForever,
}

class LocationCoreChannel {
  static const _methods = MethodChannel('com.aetherride/location_core');
  static const _events = EventChannel('com.aetherride/location_core/fixes');

  StreamSubscription? _nativeSub;
  StreamSubscription<Position>? _geoSub;
  final _controller = StreamController<LocationFix>.broadcast();
  LocationFix? _last;
  double _distanceM = 0;
  bool _native = false;
  int _fixCount = 0;

  Stream<LocationFix> get fixes => _controller.stream;
  LocationFix? get lastFix => _last;
  double get distanceM => _distanceM;
  int get fixCount => _fixCount;

  Future<LocationPermissionResult> checkPermissionDetailed() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return LocationPermissionResult.servicesDisabled;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      return LocationPermissionResult.denied;
    }
    if (perm == LocationPermission.deniedForever) {
      return LocationPermissionResult.deniedForever;
    }
    return LocationPermissionResult.granted;
  }

  Future<LocationPermissionResult> ensurePermissionDetailed() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      debugPrint('location_core: Location Services aus');
      return LocationPermissionResult.servicesDisabled;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      return LocationPermissionResult.deniedForever;
    }
    if (perm == LocationPermission.denied) {
      return LocationPermissionResult.denied;
    }
    return LocationPermissionResult.granted;
  }

  Future<bool> ensurePermission() async {
    final r = await ensurePermissionDetailed();
    return r == LocationPermissionResult.granted;
  }

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  Future<void> startRideTracking() async {
    await stopRideTracking();
    _distanceM = 0;
    _last = null;
    _fixCount = 0;
    final ok = await ensurePermission();
    if (!ok) return;

    // Android 13+ (API 33): RideLocationService's foreground-service
    // notification is otherwise silently suppressed without this — the
    // service still runs, but tracking becomes invisible to the rider.
    // Best-effort: never block ride start on the result.
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final status = await ph.Permission.notification.status;
        if (status.isDenied) {
          await ph.Permission.notification.request();
        }
      } catch (e) {
        debugPrint('location_core: notification permission request failed ($e)');
      }
    }

    var nativeOk = false;
    try {
      await _methods.invokeMethod<void>('start');
      _native = true;
      nativeOk = true;
      _nativeSub = _events.receiveBroadcastStream().listen((raw) {
        if (raw is! Map) return;
        final fix = LocationFix(
          lat: (raw['lat'] as num?)?.toDouble() ?? 0,
          lng: (raw['lng'] as num?)?.toDouble() ?? 0,
          accuracyM: (raw['accuracyM'] as num?)?.toDouble() ?? 0,
          speedMps: (raw['speedMps'] as num?)?.toDouble() ?? 0,
          altitudeM: (raw['altitudeM'] as num?)?.toDouble() ?? 0,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            (raw['timestampMs'] as num?)?.toInt() ??
                DateTime.now().millisecondsSinceEpoch,
          ),
        );
        _onFix(fix);
      });
      debugPrint('location_core: native Foreground Service aktiv');
    } on MissingPluginException {
      debugPrint('location_core: Plugin fehlt — Geolocator-Fallback');
      _native = false;
    } catch (e) {
      debugPrint('location_core: native start failed ($e) — Fallback');
      _native = false;
    }

    // Immer Geolocator parallel (Emulator: Native oft nur 1 Fix).
    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );
    _geoSub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (pos) {
        _onFix(
          LocationFix(
            lat: pos.latitude,
            lng: pos.longitude,
            accuracyM: pos.accuracy,
            speedMps: pos.speed.isNaN ? 0 : pos.speed.clamp(0, 50),
            altitudeM: pos.altitude,
            timestamp: pos.timestamp,
          ),
        );
      },
      onError: (e) => debugPrint('location_core: geolocator stream $e'),
    );
    if (!nativeOk) {
      debugPrint('location_core: nur Geolocator');
    }
  }

  void _onFix(LocationFix fix) {
    if (_last != null) {
      final d = Geolocator.distanceBetween(
        _last!.lat,
        _last!.lng,
        fix.lat,
        fix.lng,
      );
      // Ignoriere Micro-Jitter < 1 m
      if (d >= 1) _distanceM += d;
    }
    _last = fix;
    _fixCount += 1;
    if (!_controller.isClosed) _controller.add(fix);
  }

  Future<void> stopRideTracking() async {
    await _nativeSub?.cancel();
    _nativeSub = null;
    await _geoSub?.cancel();
    _geoSub = null;
    if (_native) {
      try {
        await _methods.invokeMethod<void>('stop');
      } catch (_) {}
      _native = false;
    }
  }

  void dispose() {
    unawaited(stopRideTracking());
    _controller.close();
  }
}
