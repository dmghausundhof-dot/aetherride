/// Public pack bucket (not a secret). Used by local PMTiles download.
const kOfflinePacksPublicCdnRoot =
    'https://krmgatsugplouzrhhozn.supabase.co/storage/v1/object/public/offline-packs';

const kDachBasemapStyleUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/dach-z11-style.json';

const kFranceWestBasemapStyleUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/france-west-z11-style.json';

const kAlpsSouthBasemapStyleUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/alps-south-z11-style.json';

const kBeneluxBasemapStyleUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/benelux-z11-style.json';

const kItalyNorthBasemapStyleUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/italy-north-z11-style.json';

const kItalyCenterBasemapStyleUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/italy-center-z11-style.json';

const kItalySouthBasemapStyleUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/italy-south-z11-style.json';

const kCataloniaPyreneesBasemapStyleUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/catalonia-pyrenees-z11-style.json';

const kUkSouthBasemapStyleUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/uk-south-z11-style.json';

/// Signed OSM cycle routes (icn/ncn/rcn + MTB relations) on the live catalog.
const kOnlineCycleMeshPmtilesUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/cycle-routes.pmtiles';

const kOnlineCycleMeshGeojsonUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/cycle-routes.geojson';

/// DACH-wide OSM ways (cycleway/path/track) — whole Blatt, not Hausberg chips.
const kDachWaysPmtilesUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/dach-ways.pmtiles';

/// OpenStreetMap street-level style (buildings, residential, paths).
const kOpenFreeMapLibertyStyleUrl =
    'https://tiles.openfreemap.org/styles/liberty';

/// Gray streets from z8 — readable on Karte/HUD. Liberty/Outdoors paint
/// residential as white-on-beige, which looks like “only Autobahn”.
const kOpenFreeMapPositronStyleUrl =
    'https://tiles.openfreemap.org/styles/positron';

/// OSM-Bright: Parks grün, Wasser blau, Landuse — Straßen bleiben sichtbar.
/// Default-Live-Karte statt Alidade/Positron-Grau.
const kOpenFreeMapBrightStyleUrl =
    'https://tiles.openfreemap.org/styles/bright';

String stadiaAlidadeSmoothStyleUrl(String apiKey) {
  final k = apiKey.trim();
  if (k.isEmpty) return '';
  return 'https://tiles.stadiamaps.com/styles/alidade_smooth.json?api_key=$k';
}

String stadiaOsmBrightStyleUrl(String apiKey) {
  final k = apiKey.trim();
  if (k.isEmpty) return '';
  return 'https://tiles.stadiamaps.com/styles/osm_bright.json?api_key=$k';
}

/// Live Discover / Ride / HUD basemap. Overview PMTiles stay offline-only.
/// Bright statt Alidade/Positron — Parks/Wasser, Straßen nicht white-on-beige.
String liveMapStyleUrl({
  required String pmtilesOrStyleUrl,
  required String stadiaApiKey,
}) {
  final pm = pmtilesOrStyleUrl.trim();
  if (pm.isNotEmpty && isStreetLevelBasemap(pm)) return pm;
  final stadia = stadiaOsmBrightStyleUrl(stadiaApiKey);
  if (stadia.isNotEmpty) return stadia;
  return kOpenFreeMapBrightStyleUrl;
}

/// Discover /karten catalog — not Stadia. HUD/Ride stays on [liveMapStyleUrl].
String catalogBrowseMapStyleUrl({
  required String pmtilesOrStyleUrl,
  required double lng,
  required double lat,
}) {
  final pm = pmtilesOrStyleUrl.trim();
  if (pm.isNotEmpty && isStreetLevelBasemap(pm)) return pm;
  final id = basemapArchiveIdForLngLat(lng, lat) ?? kDachBasemapId;
  return styleUrlForArchiveId(id);
}

const kDachBasemapId = 'dach-z11';
const kFranceWestBasemapId = 'france-west-z11';
const kAlpsSouthBasemapId = 'alps-south-z11';
const kBeneluxBasemapId = 'benelux-z11';
const kItalyNorthBasemapId = 'italy-north-z11';
const kItalyCenterBasemapId = 'italy-center-z11';
const kItalySouthBasemapId = 'italy-south-z11';
const kCataloniaPyreneesBasemapId = 'catalonia-pyrenees-z11';
const kUkSouthBasemapId = 'uk-south-z11';

/// Signed icn/ncn/rcn PMTiles per online Blatt. DACH keeps the historic name.
const kOnlineCycleMeshFiles = <String, String>{
  kDachBasemapId: 'cycle-routes.pmtiles',
  kFranceWestBasemapId: 'cycle-routes-france-west.pmtiles',
  kAlpsSouthBasemapId: 'cycle-routes-alps-south.pmtiles',
  kBeneluxBasemapId: 'cycle-routes-benelux.pmtiles',
  kItalyNorthBasemapId: 'cycle-routes-italy-north.pmtiles',
  kCataloniaPyreneesBasemapId: 'cycle-routes-catalonia-pyrenees.pmtiles',
  kUkSouthBasemapId: 'cycle-routes-uk-south.pmtiles',
};

String? onlineCycleMeshPmtilesUrlForPoint(
  double lng,
  double lat, {
  String? currentId,
}) {
  final id = basemapArchiveIdForLngLat(lng, lat, currentId: currentId);
  if (id == null) return null;
  final file = kOnlineCycleMeshFiles[id];
  if (file == null) return null;
  return '$kOfflinePacksPublicCdnRoot/basemap/$file';
}

String? onlineCycleMeshGeojsonUrlForPoint(
  double lng,
  double lat, {
  String? currentId,
}) {
  final pm = onlineCycleMeshPmtilesUrlForPoint(
    lng,
    lat,
    currentId: currentId,
  );
  if (pm == null) return null;
  return pm.replaceFirst(RegExp(r'\.pmtiles$'), '.geojson');
}

/// MapLibre style URL checks (Basemap offline / prefs).
bool isMapLibreStyleJsonUrl(String raw) {
  final u = raw.trim().toLowerCase();
  if (u.isEmpty) return false;
  if (u.endsWith('.pmtiles') || u.contains('.pmtiles?')) return false;
  return u.endsWith('.json') ||
      u.contains('/styles/') ||
      u.contains('style.json');
}

bool isRawPmtilesUrl(String raw) {
  final u = raw.trim().toLowerCase();
  return u.endsWith('.pmtiles') ||
      u.contains('.pmtiles?') ||
      u.startsWith('pmtiles://');
}

/// west,south,east,north of the DACH z11 extract.
const kDachBasemapBbox = <double>[5.8, 45.75, 17.25, 55.15];

/// Mainland France west of the DACH cut (see france-west-z11.pmtiles).
const kFranceWestBasemapBbox = <double>[-5.3, 42.3, 5.85, 51.1];

/// SE France Alps + Côte d'Azur + N-Italy lakes (Nice, Grenoble, Garda).
const kAlpsSouthBasemapBbox = <double>[5.55, 43.40, 11.60, 45.90];

/// NL / BE / LU + NRW-west overlap.
const kBeneluxBasemapBbox = <double>[2.40, 49.40, 7.25, 53.75];

/// Veneto / Friuli / Emilia-Romagna east of alps-south (Venice, Trieste, Rimini).
const kItalyNorthBasemapBbox = <double>[11.50, 43.50, 14.10, 46.15];

/// Tuscany south / Umbria / Lazio / Rome / Naples (not Sicily).
const kItalyCenterBasemapBbox = <double>[10.15, 40.62, 14.90, 43.85];

/// Puglia / Calabria / Basilicata (not Sicily, not Sardinia).
const kItalySouthBasemapBbox = <double>[14.70, 37.95, 18.55, 41.30];

/// Catalonia + Pyrenees + Basque coast (not full Iberia).
const kCataloniaPyreneesBasemapBbox = <double>[-2.20, 41.15, 3.35, 43.55];

/// London + South-East England (not full UK).
const kUkSouthBasemapBbox = <double>[-1.50, 50.50, 1.80, 52.50];

class OnlineBasemapArchive {
  const OnlineBasemapArchive({
    required this.id,
    required this.bbox,
    required this.styleUrl,
  });

  final String id;
  final List<double> bbox;
  final String styleUrl;

  double get area {
    if (bbox.length < 4) return double.infinity;
    return (bbox[2] - bbox[0]) * (bbox[3] - bbox[1]);
  }

  bool containsLngLat(double lng, double lat) {
    if (bbox.length < 4) return false;
    return lng >= bbox[0] &&
        lat >= bbox[1] &&
        lng <= bbox[2] &&
        lat <= bbox[3];
  }
}

/// Smallest-area first so overlap prefers the tighter extract.
const kOnlineBasemapArchives = <OnlineBasemapArchive>[
  OnlineBasemapArchive(
    id: kUkSouthBasemapId,
    bbox: kUkSouthBasemapBbox,
    styleUrl: kUkSouthBasemapStyleUrl,
  ),
  OnlineBasemapArchive(
    id: kItalySouthBasemapId,
    bbox: kItalySouthBasemapBbox,
    styleUrl: kItalySouthBasemapStyleUrl,
  ),
  OnlineBasemapArchive(
    id: kItalyCenterBasemapId,
    bbox: kItalyCenterBasemapBbox,
    styleUrl: kItalyCenterBasemapStyleUrl,
  ),
  OnlineBasemapArchive(
    id: kItalyNorthBasemapId,
    bbox: kItalyNorthBasemapBbox,
    styleUrl: kItalyNorthBasemapStyleUrl,
  ),
  OnlineBasemapArchive(
    id: kCataloniaPyreneesBasemapId,
    bbox: kCataloniaPyreneesBasemapBbox,
    styleUrl: kCataloniaPyreneesBasemapStyleUrl,
  ),
  OnlineBasemapArchive(
    id: kAlpsSouthBasemapId,
    bbox: kAlpsSouthBasemapBbox,
    styleUrl: kAlpsSouthBasemapStyleUrl,
  ),
  OnlineBasemapArchive(
    id: kBeneluxBasemapId,
    bbox: kBeneluxBasemapBbox,
    styleUrl: kBeneluxBasemapStyleUrl,
  ),
  OnlineBasemapArchive(
    id: kFranceWestBasemapId,
    bbox: kFranceWestBasemapBbox,
    styleUrl: kFranceWestBasemapStyleUrl,
  ),
  OnlineBasemapArchive(
    id: kDachBasemapId,
    bbox: kDachBasemapBbox,
    styleUrl: kDachBasemapStyleUrl,
  ),
];

bool pointInBasemapBbox(double lng, double lat, List<double> bbox) {
  if (bbox.length < 4) return false;
  return lng >= bbox[0] && lat >= bbox[1] && lng <= bbox[2] && lat <= bbox[3];
}

bool bboxMostlyFranceWest(List<double> bbox) {
  if (bbox.length < 4) return false;
  final midLng = (bbox[0] + bbox[2]) / 2;
  final midLat = (bbox[1] + bbox[3]) / 2;
  return basemapArchiveIdForLngLat(midLng, midLat) == kFranceWestBasemapId;
}

OnlineBasemapArchive? onlineBasemapArchiveById(String id) {
  for (final a in kOnlineBasemapArchives) {
    if (a.id == id) return a;
  }
  return null;
}

String? archiveIdFromStyleUrl(String? raw) {
  if (raw == null) return null;
  final u = raw.trim().toLowerCase();
  if (u.isEmpty) return null;
  if (u.contains('catalonia-pyrenees-z')) return kCataloniaPyreneesBasemapId;
  if (u.contains('italy-center-z')) return kItalyCenterBasemapId;
  if (u.contains('italy-south-z')) return kItalySouthBasemapId;
  if (u.contains('italy-north-z')) return kItalyNorthBasemapId;
  if (u.contains('uk-south-z')) return kUkSouthBasemapId;
  if (u.contains('benelux-z')) return kBeneluxBasemapId;
  if (u.contains('alps-south-z')) return kAlpsSouthBasemapId;
  if (u.contains('france-west-z')) return kFranceWestBasemapId;
  if (u.contains('dach-z11') ||
      u.contains('dach-z12') ||
      u.contains('dach-z13') ||
      u.contains('/basemap/dach-z')) {
    return kDachBasemapId;
  }
  return null;
}

bool isCdnOverviewBasemap(String raw) => archiveIdFromStyleUrl(raw) != null;

/// All catalog z11 CDN archives are overview tiles, not street-level HUD.
bool isOverviewOnlyBasemap(String raw) => isCdnOverviewBasemap(raw);

bool isStreetLevelBasemap(String raw) =>
    isMapLibreStyleJsonUrl(raw) && !isOverviewOnlyBasemap(raw);

/// Empty PMTILES_URL / CDN overview styles switch by viewport. Custom
/// Liberty/Stadia/street-level URLs stay locked.
bool isOnlineSwitchableBasemap(String raw) => isCdnOverviewBasemap(raw);

String styleUrlForArchiveId(String id) {
  return onlineBasemapArchiveById(id)?.styleUrl ?? kDachBasemapStyleUrl;
}

/// Prefer [currentId] while the point stays inside that archive (no flicker).
String? basemapArchiveIdForLngLat(
  double lng,
  double lat, {
  String? currentId,
}) {
  if (currentId != null) {
    final cur = onlineBasemapArchiveById(currentId);
    if (cur != null && cur.containsLngLat(lng, lat)) return currentId;
  }
  final hits = [
    for (final a in kOnlineBasemapArchives)
      if (a.containsLngLat(lng, lat)) a,
  ];
  if (hits.isEmpty) return null;
  hits.sort((a, b) => a.area.compareTo(b.area));
  return hits.first.id;
}

String basemapArchiveIdForBbox(List<double>? bbox) {
  if (bbox == null || bbox.length < 4) return kDachBasemapId;
  final midLng = (bbox[0] + bbox[2]) / 2;
  final midLat = (bbox[1] + bbox[3]) / 2;
  return basemapArchiveIdForLngLat(midLng, midLat) ?? kDachBasemapId;
}

/// Next CDN style when the camera/GPS leaves the current archive.
/// Null = keep [currentStyle] (same archive, custom style, or outside coverage).
String? nextOnlineBasemapStyleUrl({
  required String currentStyle,
  required double lng,
  required double lat,
}) {
  if (!isOnlineSwitchableBasemap(currentStyle)) return null;
  final nextId = basemapArchiveIdForLngLat(
    lng,
    lat,
    currentId: archiveIdFromStyleUrl(currentStyle),
  );
  if (nextId == null) return null;
  if (archiveIdFromStyleUrl(currentStyle) == nextId) return null;
  return styleUrlForArchiveId(nextId);
}

/// MapLibre OfflineRegion cannot pack `pmtiles://` sources (progress stalls).
/// Copy the archive onto the device instead ([OfflinePmtilesStore]).
bool skipMapLibreOfflineRegion(String styleUrl) {
  final u = styleUrl.trim().toLowerCase();
  if (u.isEmpty) return false;
  if (isRawPmtilesUrl(u)) return true;
  return u.contains('pmtiles://') ||
      u.contains('/basemap/dach-z') ||
      u.contains('/basemap/france-west-z') ||
      u.contains('/basemap/alps-south-z') ||
      u.contains('/basemap/benelux-z') ||
      u.contains('/basemap/italy-north-z') ||
      u.contains('/basemap/italy-center-z') ||
      u.contains('/basemap/italy-south-z') ||
      u.contains('/basemap/catalonia-pyrenees-z') ||
      u.contains('/basemap/uk-south-z') ||
      u.contains('dach-z11-style.json') ||
      u.contains('dach-z12-style.json') ||
      u.contains('dach-z13-style.json') ||
      u.contains('france-west-z11-style.json') ||
      u.contains('alps-south-z11-style.json') ||
      u.contains('benelux-z11-style.json') ||
      u.contains('italy-north-z11-style.json') ||
      u.contains('italy-center-z11-style.json') ||
      u.contains('italy-south-z11-style.json') ||
      u.contains('catalonia-pyrenees-z11-style.json') ||
      u.contains('uk-south-z11-style.json');
}

String localPmtilesSourceUrl(String archivePath) =>
    'pmtiles://file://$archivePath';

/// Point the vector source at a local archive.
Map<String, dynamic> rewriteStyleProtomapsUrl(
  Map<String, dynamic> style,
  String archivePath,
) {
  final sources = style['sources'];
  if (sources is Map) {
    final proto = sources['protomaps'];
    if (proto is Map) {
      proto['url'] = localPmtilesSourceUrl(archivePath);
      proto['type'] = 'vector';
    }
  }
  return style;
}

/// Point glyphs/sprites at files under [basemapDir] (app documents).
Map<String, dynamic> rewriteStyleLocalAssets(
  Map<String, dynamic> style,
  String basemapDir,
) {
  final root = basemapDir.endsWith('/') ? basemapDir : '$basemapDir/';
  style['glyphs'] = 'file://${root}assets/fonts/{fontstack}/{range}.pbf';
  style['sprite'] = 'file://${root}assets/sprites/v4/light';
  return style;
}
