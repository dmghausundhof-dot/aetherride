import 'dart:math' as math;

import 'consents.dart';

const double kPrivacyZoneMinRadiusM = 50;
const double kPrivacyZoneMaxRadiusM = 2000;
const double kPrivacyZoneDefaultRadiusM = 500;
const List<double> kPrivacyZoneRadiusPresetsM = [200, 500, 1000];
const String kPrivacyZoneDefaultLabel = 'Zuhause';

/// Geographic center of Germany — last-resort camera, never Null Island.
const PrivacyMapPoint kPrivacyZoneGermanyCenter = PrivacyMapPoint(
  51.1657,
  10.4515,
);

enum PrivacyZoneMapOriginSource { gps, ride, country, germany, existing }

class PrivacyMapPoint {
  const PrivacyMapPoint(this.lat, this.lng);
  final double lat;
  final double lng;
}

class PrivacyZoneMapOrigin {
  const PrivacyZoneMapOrigin({
    required this.lat,
    required this.lng,
    required this.zoom,
    required this.source,
  });

  final double lat;
  final double lng;
  final double zoom;
  final PrivacyZoneMapOriginSource source;

  /// Nur eine bestehende Zone liegt schon; GPS/Ride nur als Kamera, kein
  /// stilles „Zuhause“ am aktuellen Standort.
  bool get shouldPrePlace => source == PrivacyZoneMapOriginSource.existing;
}

bool isPlausiblePrivacyCoord(double lat, double lng) {
  if (!lat.isFinite || !lng.isFinite) return false;
  if (lat.abs() > 90 || lng.abs() > 180) return false;
  if (lat.abs() < 1e-4 && lng.abs() < 1e-4) return false;
  return true;
}

double clampPrivacyZoneRadius(double meters) {
  if (!meters.isFinite || meters <= 0) return kPrivacyZoneDefaultRadiusM;
  if (meters < kPrivacyZoneMinRadiusM) return kPrivacyZoneMinRadiusM;
  if (meters > kPrivacyZoneMaxRadiusM) return kPrivacyZoneMaxRadiusM;
  return meters;
}

double parsePrivacyZoneRadius(String raw, {double fallback = kPrivacyZoneDefaultRadiusM}) {
  final n = double.tryParse(raw.trim().replaceAll(',', '.'));
  if (n == null || !n.isFinite) return clampPrivacyZoneRadius(fallback);
  return clampPrivacyZoneRadius(n);
}

double? parsePrivacyZoneCoord(String raw, {required bool isLat}) {
  final n = double.tryParse(raw.trim().replaceAll(',', '.'));
  if (n == null || !n.isFinite) return null;
  if (isLat && n.abs() > 90) return null;
  if (!isLat && n.abs() > 180) return null;
  return n;
}

String privacyZoneRadiusLabel(double radiusM) =>
    '${clampPrivacyZoneRadius(radiusM).round()} m';

String privacyZoneCoordHint(double lat, double lng) =>
    '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';

PrivacyZone privacyZoneFromDraft({
  required String id,
  required String label,
  required double lat,
  required double lng,
  required double radiusM,
}) {
  final trimmed = label.trim();
  return PrivacyZone(
    id: id,
    label: trimmed.isEmpty ? 'Zone' : trimmed,
    lat: lat,
    lng: lng,
    radiusM: clampPrivacyZoneRadius(radiusM),
  );
}

PrivacyMapPoint? firstPlausibleTrackPoint(List<Map<String, dynamic>> track) {
  for (final p in track) {
    final lat = (p['lat'] as num?)?.toDouble();
    final lng =
        (p['lng'] as num?)?.toDouble() ?? (p['lon'] as num?)?.toDouble();
    if (lat == null || lng == null) continue;
    if (isPlausiblePrivacyCoord(lat, lng)) {
      return PrivacyMapPoint(lat, lng);
    }
  }
  return null;
}

PrivacyZoneMapOrigin countryPrivacyMapCenter(String? countryCode) {
  switch (countryCode?.trim().toUpperCase()) {
    case 'AT':
      return const PrivacyZoneMapOrigin(
        lat: 47.5162,
        lng: 14.5501,
        zoom: 6.2,
        source: PrivacyZoneMapOriginSource.country,
      );
    case 'CH':
      return const PrivacyZoneMapOrigin(
        lat: 46.8182,
        lng: 8.2275,
        zoom: 7.0,
        source: PrivacyZoneMapOriginSource.country,
      );
    case 'FR':
      return const PrivacyZoneMapOrigin(
        lat: 46.6034,
        lng: 1.8883,
        zoom: 5.5,
        source: PrivacyZoneMapOriginSource.country,
      );
    case 'IT':
      return const PrivacyZoneMapOrigin(
        lat: 41.8719,
        lng: 12.5674,
        zoom: 5.4,
        source: PrivacyZoneMapOriginSource.country,
      );
    case 'NL':
      return const PrivacyZoneMapOrigin(
        lat: 52.1326,
        lng: 5.2913,
        zoom: 7.0,
        source: PrivacyZoneMapOriginSource.country,
      );
    case 'BE':
      return const PrivacyZoneMapOrigin(
        lat: 50.5039,
        lng: 4.4699,
        zoom: 7.2,
        source: PrivacyZoneMapOriginSource.country,
      );
    case 'DE':
    default:
      return PrivacyZoneMapOrigin(
        lat: kPrivacyZoneGermanyCenter.lat,
        lng: kPrivacyZoneGermanyCenter.lng,
        zoom: 5.8,
        source: countryCode?.trim().toUpperCase() == 'DE'
            ? PrivacyZoneMapOriginSource.country
            : PrivacyZoneMapOriginSource.germany,
      );
  }
}

PrivacyZoneMapOrigin resolvePrivacyZoneMapOrigin({
  double? gpsLat,
  double? gpsLng,
  List<Map<String, dynamic>>? lastRideTrack,
  String? countryCode,
}) {
  if (gpsLat != null &&
      gpsLng != null &&
      isPlausiblePrivacyCoord(gpsLat, gpsLng)) {
    return PrivacyZoneMapOrigin(
      lat: gpsLat,
      lng: gpsLng,
      zoom: cameraZoomForPrivacyRadius(kPrivacyZoneDefaultRadiusM, lat: gpsLat),
      source: PrivacyZoneMapOriginSource.gps,
    );
  }
  final ride = lastRideTrack == null
      ? null
      : firstPlausibleTrackPoint(lastRideTrack);
  if (ride != null) {
    return PrivacyZoneMapOrigin(
      lat: ride.lat,
      lng: ride.lng,
      zoom: cameraZoomForPrivacyRadius(kPrivacyZoneDefaultRadiusM, lat: ride.lat),
      source: PrivacyZoneMapOriginSource.ride,
    );
  }
  return countryPrivacyMapCenter(countryCode);
}

/// Zoom so the radius diameter is roughly visible (~180 px at [lat]).
double cameraZoomForPrivacyRadius(double radiusM, {double lat = 50}) {
  final m = clampPrivacyZoneRadius(radiusM);
  const targetDiameterPx = 180.0;
  final mpp = (2 * m) / targetDiameterPx;
  final cosLat = math.cos(lat * math.pi / 180).abs().clamp(0.2, 1.0);
  final z = math.log(156543.03392 * cosLat / mpp) / math.ln2;
  return z.clamp(10.0, 17.0);
}

double privacyHaversineM({
  required double lat1,
  required double lng1,
  required double lat2,
  required double lng2,
}) {
  const r = 6371000.0;
  final la1 = lat1 * math.pi / 180;
  final la2 = lat2 * math.pi / 180;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(la1) * math.cos(la2) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * r * math.asin(math.sqrt(h));
}

PrivacyMapPoint privacyDestinationPoint({
  required double lat,
  required double lng,
  required double distanceM,
  required double bearingRad,
}) {
  const r = 6371000.0;
  final lat1 = lat * math.pi / 180;
  final lng1 = lng * math.pi / 180;
  final ang = distanceM / r;
  final lat2 = math.asin(
    math.sin(lat1) * math.cos(ang) +
        math.cos(lat1) * math.sin(ang) * math.cos(bearingRad),
  );
  final lng2 = lng1 +
      math.atan2(
        math.sin(bearingRad) * math.sin(ang) * math.cos(lat1),
        math.cos(ang) - math.sin(lat1) * math.sin(lat2),
      );
  return PrivacyMapPoint(lat2 * 180 / math.pi, lng2 * 180 / math.pi);
}

/// Closed geodesic ring (first == last) for a MapLibre fill/line.
List<PrivacyMapPoint> privacyZoneCircleRing({
  required double lat,
  required double lng,
  required double radiusM,
  int steps = 64,
}) {
  final r = clampPrivacyZoneRadius(radiusM);
  final n = steps < 8 ? 8 : steps;
  return [
    for (var i = 0; i <= n; i++)
      privacyDestinationPoint(
        lat: lat,
        lng: lng,
        distanceM: r,
        bearingRad: 2 * math.pi * i / n,
      ),
  ];
}
