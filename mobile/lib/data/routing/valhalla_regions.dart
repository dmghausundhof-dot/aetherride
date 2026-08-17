/// Valhalla tile region envelopes — mirror of `src/lib/routing/valhallaRegions.ts`.
/// Selection: smallest covering bbox. Keep in sync with TS + data/routing/regions.

class ValhallaRegion {
  const ValhallaRegion({
    required this.id,
    required this.name,
    required this.bbox,
    this.geofabrik,
  });

  final String id;
  final String name;

  /// [west, south, east, north]
  final List<double> bbox;

  /// Relative Geofabrik path under europe/ — null = Overpass clip only.
  final String? geofabrik;

  bool contains(double lng, double lat) =>
      lng >= bbox[0] && lat >= bbox[1] && lng <= bbox[2] && lat <= bbox[3];

  double get area => (bbox[2] - bbox[0]) * (bbox[3] - bbox[1]);
}

const kValhallaRegions = <ValhallaRegion>[
  // —— City / trail packs ——
  ValhallaRegion(
    id: 'schwarzwald-nord',
    name: 'Schwarzwald Nord',
    bbox: [7.7, 47.8, 8.2, 48.15],
  ),
  ValhallaRegion(
    id: 'amsterdam',
    name: 'Amsterdam',
    bbox: [4.75, 52.3, 5.02, 52.43],
  ),
  ValhallaRegion(
    id: 'utrecht',
    name: 'Utrecht',
    bbox: [5.0, 52.0, 5.2, 52.15],
  ),
  ValhallaRegion(
    id: 'rotterdam',
    name: 'Rotterdam',
    bbox: [4.35, 51.85, 4.6, 52.0],
  ),
  ValhallaRegion(
    id: 'den-haag',
    name: 'Den Haag',
    bbox: [4.15, 52.0, 4.4, 52.15],
  ),
  ValhallaRegion(
    id: 'eindhoven',
    name: 'Eindhoven',
    bbox: [5.35, 51.4, 5.55, 51.5],
  ),
  ValhallaRegion(
    id: 'groningen',
    name: 'Groningen',
    bbox: [6.45, 53.15, 6.65, 53.3],
  ),

  // —— Benelux ——
  ValhallaRegion(
    id: 'nl-netherlands',
    name: 'Niederlande',
    bbox: [3.2, 50.75, 7.25, 53.7],
    geofabrik: 'netherlands-latest.osm.pbf',
  ),
  ValhallaRegion(
    id: 'be-belgium',
    name: 'Belgien',
    bbox: [2.4, 49.45, 6.45, 51.55],
    geofabrik: 'belgium-latest.osm.pbf',
  ),

  // —— DE Länder ——
  ValhallaRegion(
    id: 'de-saarland',
    name: 'Saarland',
    bbox: [6.3, 49.1, 7.4, 49.65],
    geofabrik: 'germany/saarland-latest.osm.pbf',
  ),
  ValhallaRegion(
    id: 'de-rlp',
    name: 'Rheinland-Pfalz',
    bbox: [6.1, 48.95, 8.55, 50.95],
    geofabrik: 'germany/rheinland-pfalz-latest.osm.pbf',
  ),
  ValhallaRegion(
    id: 'de-hessen',
    name: 'Hessen',
    bbox: [7.75, 49.35, 10.3, 51.7],
    geofabrik: 'germany/hessen-latest.osm.pbf',
  ),
  ValhallaRegion(
    id: 'de-thueringen',
    name: 'Thüringen',
    bbox: [9.85, 50.2, 12.65, 51.65],
    geofabrik: 'germany/thueringen-latest.osm.pbf',
  ),
  ValhallaRegion(
    id: 'de-sachsen',
    name: 'Sachsen',
    bbox: [11.85, 50.17, 15.05, 51.7],
    geofabrik: 'germany/sachsen-latest.osm.pbf',
  ),
  ValhallaRegion(
    id: 'de-baden-wuerttemberg',
    name: 'Baden-Württemberg',
    bbox: [7.5, 47.53, 10.5, 49.8],
    geofabrik: 'germany/baden-wuerttemberg-latest.osm.pbf',
  ),
  ValhallaRegion(
    id: 'de-nrw',
    name: 'Nordrhein-Westfalen',
    bbox: [5.86, 50.3, 9.5, 52.55],
    geofabrik: 'germany/nordrhein-westfalen-latest.osm.pbf',
  ),
  ValhallaRegion(
    id: 'de-sachsen-anhalt',
    name: 'Sachsen-Anhalt',
    bbox: [10.5, 50.9, 13.25, 53.05],
    geofabrik: 'germany/sachsen-anhalt-latest.osm.pbf',
  ),
  ValhallaRegion(
    id: 'de-schleswig-holstein',
    name: 'Schleswig-Holstein',
    bbox: [8.3, 53.3, 11.4, 55.1],
    geofabrik: 'germany/schleswig-holstein-latest.osm.pbf',
  ),
  ValhallaRegion(
    id: 'de-mecklenburg-vorpommern',
    name: 'Mecklenburg-Vorpommern',
    bbox: [10.5, 53.05, 14.5, 54.7],
    geofabrik: 'germany/mecklenburg-vorpommern-latest.osm.pbf',
  ),
  ValhallaRegion(
    id: 'de-brandenburg',
    name: 'Brandenburg',
    bbox: [11.2, 51.3, 15.05, 53.6],
    geofabrik: 'germany/brandenburg-latest.osm.pbf',
  ),
  ValhallaRegion(
    id: 'de-niedersachsen',
    name: 'Niedersachsen',
    bbox: [6.6, 51.3, 11.65, 53.9],
    geofabrik: 'germany/niedersachsen-latest.osm.pbf',
  ),
  ValhallaRegion(
    id: 'de-bayern',
    name: 'Bayern',
    bbox: [8.97, 47.27, 13.84, 50.57],
    geofabrik: 'germany/bayern-latest.osm.pbf',
  ),

  // —— AT / CH ——
  ValhallaRegion(
    id: 'ch-zuerichsee',
    name: 'Zürichsee / Zürcher Oberland',
    bbox: [8.25, 47.18, 9.05, 47.65],
    geofabrik: 'switzerland-latest.osm.pbf',
  ),
  ValhallaRegion(
    id: 'ch-mittelland',
    name: 'Schweizer Mittelland',
    bbox: [6.85, 46.72, 8.05, 47.35],
    geofabrik: 'switzerland-latest.osm.pbf',
  ),
  ValhallaRegion(
    id: 'ch-genfersee',
    name: 'Genfersee / Romandie',
    bbox: [5.96, 46.08, 7.25, 46.62],
    geofabrik: 'switzerland-latest.osm.pbf',
  ),
  ValhallaRegion(
    id: 'at-tirol',
    name: 'Tirol',
    bbox: [10.1, 46.62, 12.95, 47.78],
    geofabrik: 'austria-latest.osm.pbf',
  ),
  ValhallaRegion(
    id: 'at-salzburg',
    name: 'Land Salzburg',
    bbox: [12.05, 46.9, 13.85, 48.05],
    geofabrik: 'austria-latest.osm.pbf',
  ),
  ValhallaRegion(
    id: 'at-niederoesterreich',
    name: 'Niederösterreich',
    bbox: [14.4, 47.4, 17.17, 49.02],
    geofabrik: 'austria-latest.osm.pbf',
  ),

  // —— FR ——
  ValhallaRegion(
    id: 'fr-ile-de-france',
    name: 'Île-de-France',
    bbox: [1.45, 48.12, 3.55, 49.25],
    geofabrik: 'france/ile-de-france-latest.osm.pbf',
  ),
  ValhallaRegion(
    id: 'fr-nord-pas-de-calais',
    name: 'Nord-Pas-de-Calais',
    bbox: [1.55, 50.0, 4.25, 51.1],
    geofabrik: 'france/nord-pas-de-calais-latest.osm.pbf',
  ),
  ValhallaRegion(
    id: 'fr-bretagne',
    name: 'Bretagne',
    bbox: [-5.15, 47.25, -1.0, 48.9],
    geofabrik: 'france/bretagne-latest.osm.pbf',
  ),
  ValhallaRegion(
    id: 'fr-rhone-alpes',
    name: 'Rhône-Alpes',
    bbox: [3.85, 44.1, 7.25, 46.4],
    geofabrik: 'france/rhone-alpes-latest.osm.pbf',
  ),
  ValhallaRegion(
    id: 'fr-provence-alpes-cote-d-azur',
    name: "Provence-Alpes-Côte d'Azur",
    bbox: [4.2, 42.95, 7.75, 45.15],
    geofabrik: 'france/provence-alpes-cote-d-azur-latest.osm.pbf',
  ),

  // —— IT ——
  ValhallaRegion(
    id: 'it-nord-ovest',
    name: 'Nord-Ovest',
    bbox: [6.6, 43.75, 10.6, 46.55],
    geofabrik: 'italy/nord-ovest-latest.osm.pbf',
  ),
  ValhallaRegion(
    id: 'it-nord-est',
    name: 'Nord-Est',
    bbox: [10.35, 43.7, 13.95, 47.1],
    geofabrik: 'italy/nord-est-latest.osm.pbf',
  ),
  ValhallaRegion(
    id: 'it-centro',
    name: 'Centro',
    bbox: [9.7, 41.2, 14.05, 44.5],
    geofabrik: 'italy/centro-latest.osm.pbf',
  ),
  ValhallaRegion(
    id: 'it-sud',
    name: 'Sud',
    bbox: [12.9, 37.9, 18.55, 42.15],
    geofabrik: 'italy/sud-latest.osm.pbf',
  ),
];

/// Smallest registered Valhalla region covering the point, or null.
ValhallaRegion? valhallaRegionForPoint(double lng, double lat) {
  final hits = [
    for (final r in kValhallaRegions)
      if (r.contains(lng, lat)) r,
  ];
  if (hits.isEmpty) return null;
  hits.sort((a, b) => a.area.compareTo(b.area));
  return hits.first;
}

String valhallaTilesCdnPath(String regionId) => '$regionId/valhalla_tiles.tar';

/// Suggest Valhalla pack id for map center, else selected region bbox center.
String? suggestedValhallaRegionId({
  double? mapLng,
  double? mapLat,
  List<double>? regionBbox,
}) {
  double? lng = mapLng;
  double? lat = mapLat;
  if ((lng == null || lat == null) &&
      regionBbox != null &&
      regionBbox.length >= 4) {
    lng = (regionBbox[0] + regionBbox[2]) / 2;
    lat = (regionBbox[1] + regionBbox[3]) / 2;
  }
  if (lng == null || lat == null) return null;
  return valhallaRegionForPoint(lng, lat)?.id;
}
