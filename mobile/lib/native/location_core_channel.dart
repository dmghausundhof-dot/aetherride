import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

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

class LocationCoreChannel {
  static const _methods = MethodChannel('com.aetherride/location_core');
  static const _events = EventChannel('com.aetherride/location_core/fixes');

  StreamSubscription? _nativeSub;
  StreamSubscription<Position>? _geoSub;
  final _controller = StreamController<LocationFix>.broadcast();
  LocationFix? _last;
  double _distanceM = 0;
  bool _native = false;

  Stream<LocationFix> get fixes => _controller.stream;
  LocationFix? get lastFix => _last;
  double get distanceM => _distanceM;

  Future<bool> ensurePermission() async {
    var enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      debugPrint('location_core: Location Services aus');
      return false;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      debugPrint('location_core: keine Permission');
      return false;
    }
    return true;
  }

  Future<void> startRideTracking() async {
    await stopRideTracking();
    _distanceM = 0;
    _last = null;
    final ok = await ensurePermission();
    if (!ok) return;

    try {
      await _methods.invokeMethod<void>('start');
      _native = true;
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
      return;
    } on MissingPluginException {
      debugPrint('location_core: Plugin fehlt — Geolocator-Fallback');
      _native = false;
    } catch (e) {
      debugPrint('location_core: native start failed ($e) — Fallback');
      _native = false;
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 3,
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
    );
  }

  void _onFix(LocationFix fix) {
    if (_last != null) {
      _distanceM += Geolocator.distanceBetween(
        _last!.lat,
        _last!.lng,
        fix.lat,
        fix.lng,
      );
    }
    _last = fix;
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

  Future<void> dispose() async {
    await stopRideTracking();
    await _controller.close();
  }
}
