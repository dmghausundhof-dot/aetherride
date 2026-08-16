/// Kartenobjekt für Entdecken/Planen. Kein Feed, kein Fake-Highlight.
enum MapPlaceKind {
  cafe,
  water,
  viewpoint,
  shop,
  repair,
  trailhead,
  tip,
  meet,
  other,
}

enum MapPlaceSource { coverage, osm, seed, stimme, user, meet }

class MapPlace {
  const MapPlace({
    required this.id,
    required this.name,
    required this.kind,
    required this.lat,
    required this.lng,
    this.source = MapPlaceSource.coverage,
    this.mapsUrl,
    this.tourId,
    this.tip,
  });

  final String id;
  final String name;
  final MapPlaceKind kind;
  final double lat;
  final double lng;
  final MapPlaceSource source;
  final String? mapsUrl;
  final String? tourId;
  final String? tip;

  /// Wire-Wert für Pins / HUD (`cafe`, `shop`, …).
  String get kindWire => kind.wire;
}

extension MapPlaceKindWire on MapPlaceKind {
  String get wire => switch (this) {
        MapPlaceKind.cafe => 'cafe',
        MapPlaceKind.water => 'water',
        MapPlaceKind.viewpoint => 'viewpoint',
        MapPlaceKind.shop => 'shop',
        MapPlaceKind.repair => 'repair',
        MapPlaceKind.trailhead => 'trailhead',
        MapPlaceKind.tip => 'tip',
        MapPlaceKind.meet => 'meet',
        MapPlaceKind.other => 'other',
      };
}

/// Coverage/OSM/Google `kind` → kanonisch. `bike_shop` bleibt Shop, nie „POI“.
MapPlaceKind mapPlaceKindFromRaw(String? raw) {
  final k = (raw ?? '').trim().toLowerCase().replaceAll('-', '_');
  return switch (k) {
    'cafe' || 'bakery' || 'restaurant' => MapPlaceKind.cafe,
    'water' || 'drinking_water' || 'fountain' => MapPlaceKind.water,
    'viewpoint' || 'peak' || 'scenic' => MapPlaceKind.viewpoint,
    'shop' || 'bike_shop' || 'bicycle_store' => MapPlaceKind.shop,
    'repair' => MapPlaceKind.repair,
    'trailhead' || 'parking' => MapPlaceKind.trailhead,
    'tip' || 'highlight' => MapPlaceKind.tip,
    'meet' || 'meeting' => MapPlaceKind.meet,
    _ => MapPlaceKind.other,
  };
}

MapPlace mapPlaceFromRaw({
  required String id,
  required String name,
  required double lat,
  required double lng,
  String? kind,
  String? mapsUrl,
  MapPlaceSource source = MapPlaceSource.coverage,
  String? tourId,
  String? tip,
}) {
  return MapPlace(
    id: id,
    name: name.trim(),
    kind: mapPlaceKindFromRaw(kind),
    lat: lat,
    lng: lng,
    source: source,
    mapsUrl: (mapsUrl ?? '').trim().isEmpty ? null : mapsUrl!.trim(),
    tourId: tourId,
    tip: tip,
  );
}
