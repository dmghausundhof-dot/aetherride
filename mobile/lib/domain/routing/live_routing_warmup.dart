import 'dart:math' as math;

/// Dummy A–B used to compile GraphHopper `custom_model` before dest is pinned.
const kLiveRoutingWarmupOffsetM = 380.0;

/// ~5–11 km cells so pan/GPS jitter does not burn extra GH credits.
String liveRoutingWarmupCell({
  required String profile,
  required double lat,
  required double lng,
}) {
  return '$profile:${lng.toStringAsFixed(1)}:${lat.toStringAsFixed(1)}';
}

({double lat, double lng}) liveRoutingWarmupTo({
  required double lat,
  required double lng,
}) {
  final metersPerDegLng = 111320 * math.cos(lat * math.pi / 180);
  final dLng = metersPerDegLng.abs() > 40
      ? kLiveRoutingWarmupOffsetM / metersPerDegLng
      : 0.004;
  return (lat: lat, lng: lng + dLng);
}

/// Real A–B is the warmup — a dummy request must not race it.
bool shouldWarmLiveRouting({
  required bool hasStart,
  required bool hasEnd,
}) =>
    !(hasStart && hasEnd);
