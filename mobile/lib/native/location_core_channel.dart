import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'native_channels.dart';

/// Stub für `location_core` (CoreLocation / FusedLocation + Foreground Service).
class LocationCoreChannel {
  LocationCoreChannel({MethodChannel? method})
      : _method = method ?? const MethodChannel(NativeChannels.locationCore);

  final MethodChannel _method;

  Future<void> startRideTracking() async {
    try {
      await _method.invokeMethod<void>('startRideTracking');
    } on MissingPluginException {
      debugPrint('location_core: Plugin fehlt — Stub');
    }
  }

  Future<void> stopRideTracking() async {
    try {
      await _method.invokeMethod<void>('stopRideTracking');
    } on MissingPluginException {
      // ignore
    }
  }
}
