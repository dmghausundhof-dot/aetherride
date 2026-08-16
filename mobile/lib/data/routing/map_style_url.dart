/// Public pack bucket (not a secret). Used by local PMTiles download.
const kOfflinePacksPublicCdnRoot =
    'https://krmgatsugplouzrhhozn.supabase.co/storage/v1/object/public/offline-packs';

const kDachBasemapId = 'dach-z11';
const kFranceWestBasemapId = 'france-west-z11';
const kAlpsSouthBasemapId = 'alps-south-z11';
const kBeneluxBasemapId = 'benelux-z11';
const kItalyNorthBasemapId = 'italy-north-z11';
const kCataloniaPyreneesBasemapId = 'catalonia-pyrenees-z11';
const kUkSouthBasemapId = 'uk-south-z11';

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

/// MapLibre style URL checks (Basemap offline / prefs).
bool isMapLibreStyleJsonUrl(String raw) {
  final u = raw.trim().toLowerCase();
  if (u.isEmpty) return false;
  if (u.endsWith('.pmtiles') || u.contains('.pmtiles?')) return false;
  return u.endsWith('.json') ||
      u.contains('/styles/') ||
      u.contains('style.json');
}

/// DACH/FR overview extracts (maxzoom 11–13). Fine as an offline pack,
/// unusable as the live nav map — at HUD zoom only motorways remain.
bool isOverviewOnlyBasemap(String raw) {
  final u = raw.trim().toLowerCase();
  if (u.isEmpty) return false;
  if (u.contains('dach-z11') ||
      u.contains('dach-z12') ||
      u.contains('dach-z13') ||
      u.contains('france-west-z11')) {
    return true;
  }
  return u.contains('/basemap/dach-z') || u.contains('/basemap/france-west-z');
}

/// Style JSON with street-level tiles (Liberty, Stadia, custom z14+).
bool isStreetLevelBasemap(String raw) =>
    isMapLibreStyleJsonUrl(raw) && !isOverviewOnlyBasemap(raw);

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

bool bboxMostlyFranceWest(List<double> bbox) {
  if (bbox.length < 4) return false;
  final midLng = (bbox[0] + bbox[2]) / 2;
  return midLng < 5.85;
}

String basemapArchiveIdForBbox(List<double>? bbox) {
  if (bbox != null && bboxMostlyFranceWest(bbox)) return 'france-west-z11';
  return 'dach-z11';
}

/// MapLibre OfflineRegion cannot pack `pmtiles://` sources (progress stalls).
/// Use [OfflinePmtilesStore] to copy the archive onto the device instead.
bool skipMapLibreOfflineRegion(String styleUrl) {
  final u = styleUrl.trim().toLowerCase();
  if (u.isEmpty) return false;
  if (isRawPmtilesUrl(u)) return true;
  return u.contains('pmtiles://') ||
      u.contains('/basemap/dach-z') ||
      u.contains('/basemap/france-west-z') ||
      u.contains('dach-z11-style.json') ||
      u.contains('dach-z12-style.json') ||
      u.contains('dach-z13-style.json') ||
      u.contains('france-west-z11-style.json');
}

String styleUrlForArchiveId(String id) =>
    '$kOfflinePacksPublicCdnRoot/basemap/$id-style.json';

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
