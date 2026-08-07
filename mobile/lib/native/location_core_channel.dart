import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// GPS / Fused-Location für Ride-Tracking (Emulator + Device).
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
  StreamSubscription<Position>? _sub;
  final _controller = StreamController<LocationFix>.broadcast();
  LocationFix? _last;
  double _distanceM = 0;

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

    const settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 3,
    );
    _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (pos) {
        final fix = LocationFix(
          lat: pos.latitude,
          lng: pos.longitude,
          accuracyM: pos.accuracy,
          speedMps: pos.speed.isNaN ? 0 : pos.speed.clamp(0, 50),
          altitudeM: pos.altitude,
          timestamp: pos.timestamp,
        );
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
      },
      onError: (e) => debugPrint('location_core stream: $e'),
    );
    debugPrint('location_core: Tracking gestartet');
  }

  Future<void> stopRideTracking() async {
    await _sub?.cancel();
    _sub = null;
  }

  void dispose() {
    unawaited(stopRideTracking());
    _controller.close();
  }
}
