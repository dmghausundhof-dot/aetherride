import 'map_place.dart';

/// Coverage zuerst, dann DB, Stimme, Treffpunkt. Gleiche Zelle behält den ersten.
List<MapPlace> mergeMapPlaces({
  List<MapPlace> coverage = const [],
  List<MapPlace> community = const [],
  List<MapPlace> stimme = const [],
  MapPlace? meet,
}) {
  final seen = <String>{};
  final out = <MapPlace>[];
  void push(MapPlace? p) {
    if (p == null) return;
    if (p.name.trim().isEmpty) return;
    if (p.lat.abs() > 90 || p.lng.abs() > 180) return;
    final key =
        '${p.lat.toStringAsFixed(4)}:${p.lng.toStringAsFixed(4)}:${p.kind.wire}';
    if (!seen.add(key)) return;
    out.add(p);
  }

  for (final p in coverage) {
    push(p);
  }
  for (final p in community) {
    push(p);
  }
  for (final p in stimme) {
    push(p);
  }
  push(meet);
  return out;
}

MapPlaceSource mapPlaceSourceFromRaw(String? raw) {
  switch ((raw ?? '').trim()) {
    case 'osm':
      return MapPlaceSource.osm;
    case 'seed':
      return MapPlaceSource.seed;
    case 'stimme':
      return MapPlaceSource.stimme;
    case 'user':
    case 'map_places':
      return MapPlaceSource.user;
    case 'meet':
      return MapPlaceSource.meet;
    default:
      return MapPlaceSource.coverage;
  }
}

MapPlace? mapPlaceFromApi(Object? raw) {
  if (raw is! Map) return null;
  final id = '${raw['id'] ?? ''}'.trim();
  final name = '${raw['name'] ?? ''}'.trim();
  final lat = (raw['lat'] as num?)?.toDouble();
  final lng = (raw['lng'] as num?)?.toDouble();
  if (id.isEmpty || name.isEmpty || lat == null || lng == null) return null;
  return mapPlaceFromRaw(
    id: id,
    name: name,
    lat: lat,
    lng: lng,
    kind: '${raw['kind'] ?? ''}',
    mapsUrl: raw['mapsUrl'] as String?,
    source: mapPlaceSourceFromRaw('${raw['source'] ?? ''}'),
    tourId: raw['tourId'] as String? ?? raw['tour_id'] as String?,
    tip: raw['tip'] as String?,
  );
}
