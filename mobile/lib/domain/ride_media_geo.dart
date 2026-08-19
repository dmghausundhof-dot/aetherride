import 'privacy/consents.dart';
import 'privacy/track_trim.dart';
import 'ride_media.dart';
import 'routing/route_progress.dart';

/// Max offset when matching a gallery timestamp to the GPS track.
const kRideMediaTimeMatchMax = Duration(seconds: 90);

/// Personal pins keep the real GPS. [alongM] is still projected for the profile.
RideMedia stampRideMedia(
  RideMedia media, {
  double? lat,
  double? lng,
  List<Map<String, dynamic>> track = const [],
  List<PrivacyZone> zones = const [],
  bool fallbackLastTrack = false,
}) {
  var pinLat = _validLat(lat);
  var pinLng = pinLat == null ? null : _validLng(lng);

  if (pinLat == null || pinLng == null) {
    final near = nearestTrackPointByTime(track, media.capturedAt);
    if (near != null) {
      pinLat = near.lat;
      pinLng = near.lng;
    }
  }

  if ((pinLat == null || pinLng == null) &&
      fallbackLastTrack &&
      track.isNotEmpty) {
    final last = _pointOf(track.last);
    if (last != null) {
      pinLat = last.lat;
      pinLng = last.lng;
    }
  }

  var stripped = media.privacyStripped;
  if (pinLat != null &&
      pinLng != null &&
      pointInPrivacyZones(pinLat, pinLng, zones)) {
    pinLat = null;
    pinLng = null;
    stripped = true;
  }

  double? along;
  if (pinLat != null && pinLng != null) {
    along = alongMOnTrack(track, pinLat, pinLng);
  }

  return media.copyWith(
    lat: pinLat,
    lng: pinLng,
    alongM: along,
    privacyStripped: stripped,
    clearPin: pinLat == null || pinLng == null,
    clearAlong: along == null,
  );
}

List<RideMedia> enrichRideMedia(
  List<RideMedia> items, {
  required List<Map<String, dynamic>> track,
  List<PrivacyZone> zones = const [],
}) {
  return [
    for (final m in items)
      stampRideMedia(
        m,
        lat: m.lat,
        lng: m.lng,
        track: track,
        zones: zones,
      ),
  ];
}

({double lat, double lng, int timeMs})? nearestTrackPointByTime(
  List<Map<String, dynamic>> track,
  DateTime capturedAt,
) {
  if (track.isEmpty) return null;
  final t = capturedAt.toUtc().millisecondsSinceEpoch;
  ({double lat, double lng, int timeMs})? best;
  var bestDt = kRideMediaTimeMatchMax.inMilliseconds + 1;
  for (final raw in track) {
    final p = _pointOf(raw);
    if (p == null || p.timeMs <= 0) continue;
    final dt = (p.timeMs - t).abs();
    if (dt < bestDt) {
      bestDt = dt;
      best = p;
    }
  }
  if (best == null || bestDt > kRideMediaTimeMatchMax.inMilliseconds) {
    return null;
  }
  return best;
}

double? alongMOnTrack(
  List<Map<String, dynamic>> track,
  double lat,
  double lng,
) {
  final coords = <List<double>>[];
  for (final raw in track) {
    final p = _pointOf(raw);
    if (p == null) continue;
    coords.add([p.lng, p.lat]);
  }
  if (coords.length < 2) return null;
  final prog = projectOntoRoute(coordinates: coords, lat: lat, lng: lng);
  if (!prog.distanceAlongM.isFinite) return null;
  return prog.distanceAlongM;
}

double? _validLat(double? lat) {
  if (lat == null || !lat.isFinite || lat.abs() > 90) return null;
  return lat;
}

double? _validLng(double? lng) {
  if (lng == null || !lng.isFinite || lng.abs() > 180) return null;
  return lng;
}

({double lat, double lng, int timeMs})? _pointOf(Map<String, dynamic> p) {
  final lat = (p['lat'] as num?)?.toDouble();
  final lng = (p['lng'] as num?)?.toDouble() ?? (p['lon'] as num?)?.toDouble();
  if (lat == null || lng == null) return null;
  if (!lat.isFinite || !lng.isFinite) return null;
  if (lat.abs() > 90 || lng.abs() > 180) return null;
  final time = (p['time'] as num?)?.toInt() ?? (p['timeMs'] as num?)?.toInt() ?? 0;
  return (lat: lat, lng: lng, timeMs: time);
}
