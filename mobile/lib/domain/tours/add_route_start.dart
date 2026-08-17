/// Startpin für „Route hinzufügen“ — GPS, sonst Kartenmitte, sonst ohne Pin.
/// Kein Fake-Heidelberg, keine DACH-Übersicht als Tour-Origin.
enum AddRouteStartSource { gps, map }

class AddRouteStartPin {
  const AddRouteStartPin({
    required this.lat,
    required this.lng,
    required this.source,
  });

  final double lat;
  final double lng;
  final AddRouteStartSource source;
}

class DiscoverViewport {
  const DiscoverViewport({
    required this.lat,
    required this.lng,
    this.zoom = 12,
  });

  final double lat;
  final double lng;
  final double zoom;

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'zoom': zoom,
      };

  static DiscoverViewport? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final lat = (raw['lat'] as num?)?.toDouble();
    final lng = (raw['lng'] as num?)?.toDouble();
    final zoom = (raw['zoom'] as num?)?.toDouble() ?? 12;
    if (!_validCoord(lat, lng)) return null;
    return DiscoverViewport(lat: lat!, lng: lng!, zoom: zoom);
  }
}

/// Unter diesem Zoom ist die Karte Übersicht, kein Start.
const kMinLocalDiscoverZoom = 9.0;

bool isLocalDiscoverZoom(double zoom) => zoom >= kMinLocalDiscoverZoom;

/// Native Discover-Kaltstart (DACH+FR-Übersicht) — nie Tour-Start.
bool isPlaceholderDiscoverCenter(double lat, double lng) {
  if ((lat - 47.2).abs() < 0.05 && (lng - 6.5).abs() < 0.05) return true;
  // Web Discover FALLBACK_CENTER [8.2, 48.0]
  if ((lat - 48.0).abs() < 0.02 && (lng - 8.2).abs() < 0.02) return true;
  return false;
}

AddRouteStartPin? resolveAddRouteStart({
  double? gpsLat,
  double? gpsLng,
  double? mapLat,
  double? mapLng,
}) {
  if (_validCoord(gpsLat, gpsLng)) {
    return AddRouteStartPin(
      lat: gpsLat!,
      lng: gpsLng!,
      source: AddRouteStartSource.gps,
    );
  }
  if (_validCoord(mapLat, mapLng) &&
      !isPlaceholderDiscoverCenter(mapLat!, mapLng!)) {
    return AddRouteStartPin(
      lat: mapLat,
      lng: mapLng,
      source: AddRouteStartSource.map,
    );
  }
  return null;
}

bool _validCoord(double? lat, double? lng) {
  if (lat == null || lng == null) return false;
  if (lat.isNaN || lng.isNaN) return false;
  return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
}
