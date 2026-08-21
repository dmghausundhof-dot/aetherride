import 'package:http/http.dart' as http;

/// Public pack bucket (not a secret). Used by local PMTiles download.
const kOfflinePacksPublicCdnRoot =
    'https://krmgatsugplouzrhhozn.supabase.co/storage/v1/object/public/offline-packs';

/// Busts the 5-minute CDN cache after a sage restyle.
const kBasemapStylePaintRev = 'sage';

const kDachBasemapStyleUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/dach-z11-style.json?v=$kBasemapStylePaintRev';

const kFranceWestBasemapStyleUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/france-west-z11-style.json?v=$kBasemapStylePaintRev';

const kAlpsSouthBasemapStyleUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/alps-south-z11-style.json?v=$kBasemapStylePaintRev';

const kBeneluxBasemapStyleUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/benelux-z11-style.json?v=$kBasemapStylePaintRev';

const kItalyNorthBasemapStyleUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/italy-north-z11-style.json?v=$kBasemapStylePaintRev';

const kItalyCenterBasemapStyleUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/italy-center-z11-style.json?v=$kBasemapStylePaintRev';

const kItalySouthBasemapStyleUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/italy-south-z11-style.json?v=$kBasemapStylePaintRev';

const kCataloniaPyreneesBasemapStyleUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/catalonia-pyrenees-z11-style.json?v=$kBasemapStylePaintRev';

const kUkSouthBasemapStyleUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/uk-south-z11-style.json?v=$kBasemapStylePaintRev';

/// Signed OSM cycle routes (icn/ncn/rcn + MTB relations) on the live catalog.
const kOnlineCycleMeshPmtilesUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/cycle-routes.pmtiles';

const kOnlineCycleMeshGeojsonUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/cycle-routes.geojson';

/// Country-wide OSM ways (cycleway/path/track). Only files that exist on the CDN.
const kDachWaysPmtilesUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/dach-ways.pmtiles';

const kNlWaysPmtilesUrl = '$kOfflinePacksPublicCdnRoot/basemap/nl-ways.pmtiles';

const kBeWaysPmtilesUrl = '$kOfflinePacksPublicCdnRoot/basemap/be-ways.pmtiles';

const kItalyWaysPmtilesUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/italy-ways.pmtiles';

/// OpenFreeMap planet TileJSON — live cycleway/path/track on catalog styles.
const kOpenFreeMapPlanetSourceUrl = 'https://tiles.openfreemap.org/planet';

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
  kItalyCenterBasemapId: 'cycle-routes-italy-center.pmtiles',
  kItalySouthBasemapId: 'cycle-routes-italy-south.pmtiles',
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
    return lng >= bbox[0] && lat >= bbox[1] && lng <= bbox[2] && lat <= bbox[3];
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

/// Padded union of all catalog Blätter — sheet sketch, not DACH-only.
List<double> unionOnlineBasemapBbox({double pad = 0.8}) {
  var west = kOnlineBasemapArchives.first.bbox[0];
  var south = kOnlineBasemapArchives.first.bbox[1];
  var east = kOnlineBasemapArchives.first.bbox[2];
  var north = kOnlineBasemapArchives.first.bbox[3];
  for (final a in kOnlineBasemapArchives) {
    final b = a.bbox;
    if (b.length < 4) continue;
    if (b[0] < west) west = b[0];
    if (b[1] < south) south = b[1];
    if (b[2] > east) east = b[2];
    if (b[3] > north) north = b[3];
  }
  return [west - pad, south - pad, east + pad, north + pad];
}

/// Sheet mini-map: DACH packs on the DACH Blatt, others on their Blatt.
List<double> coverageSketchWorld(List<double> packBbox) {
  if (packBbox.length < 4) return List<double>.from(kDachBasemapBbox);
  final d = kDachBasemapBbox;
  final overlaps = packBbox[2] >= d[0] &&
      packBbox[0] <= d[2] &&
      packBbox[3] >= d[1] &&
      packBbox[1] <= d[3];
  if (overlaps) return List<double>.from(d);
  final midLng = (packBbox[0] + packBbox[2]) / 2;
  final midLat = (packBbox[1] + packBbox[3]) / 2;
  final id = basemapArchiveIdForLngLat(midLng, midLat);
  final archive = id == null ? null : onlineBasemapArchiveById(id);
  if (archive != null) return List<double>.from(archive.bbox);
  const pad = 0.6;
  return [
    packBbox[0] - pad,
    packBbox[1] - pad,
    packBbox[2] + pad,
    packBbox[3] + pad,
  ];
}

bool coverageSketchWorldIsDach(List<double> world) {
  if (world.length < 4) return false;
  const d = kDachBasemapBbox;
  return (world[0] - d[0]).abs() < 1e-6 &&
      (world[1] - d[1]).abs() < 1e-6 &&
      (world[2] - d[2]).abs() < 1e-6 &&
      (world[3] - d[3]).abs() < 1e-6;
}

/// Coarse DACH landmass for the sheet mini-map (lng/lat, closed).
const kDachLandRingLngLat = <List<double>>[
  [6.9, 53.4],
  [8.5, 53.7],
  [8.6, 54.4],
  [8.9, 54.9],
  [10.0, 54.5],
  [11.1, 54.4],
  [12.1, 54.4],
  [13.1, 54.4],
  [14.2, 54.0],
  [14.2, 53.2],
  [14.4, 52.5],
  [14.8, 51.9],
  [15.0, 51.2],
  [14.5, 50.8],
  [13.8, 50.3],
  [13.2, 49.5],
  [13.0, 48.6],
  [14.0, 48.2],
  [16.0, 48.0],
  [17.0, 48.0],
  [16.5, 47.5],
  [16.0, 46.8],
  [14.5, 46.5],
  [13.5, 46.5],
  [12.0, 46.6],
  [10.5, 46.8],
  [9.8, 46.3],
  [8.9, 45.9],
  [7.5, 45.9],
  [6.8, 46.1],
  [6.1, 46.5],
  [6.0, 47.0],
  [6.8, 47.6],
  [7.5, 47.6],
  [7.6, 48.6],
  [7.0, 49.1],
  [6.4, 49.5],
  [6.1, 50.2],
  [6.0, 51.0],
  [6.2, 51.8],
  [6.9, 53.4],
];

/// Land silhouette on the sketch: DACH outline, else an inset plate.
List<List<double>> coverageSketchLandRing(List<double> world) {
  if (coverageSketchWorldIsDach(world)) return kDachLandRingLngLat;
  if (world.length < 4) return const [];
  final padLng = (world[2] - world[0]) * 0.06;
  final padLat = (world[3] - world[1]) * 0.06;
  final w = world[0] + padLng;
  final s = world[1] + padLat;
  final e = world[2] - padLng;
  final n = world[3] - padLat;
  return [
    [w, s],
    [e, s],
    [e, n],
    [w, n],
    [w, s],
  ];
}

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

/// Ride HUD must stay on street-level tiles. Local/CDN z11 overviews
/// (`maxzoom: 11`) paint empty/black at nav zoom (~15–16).
String rideHudStyleUrl({
  required String liveStyle,
  String? resolvedStyle,
}) {
  final live = liveStyle.trim();
  final resolved = resolvedStyle?.trim() ?? '';
  if (resolved.isEmpty) return live;
  if (isOverviewOnlyBasemap(resolved)) return live;
  if (isStreetLevelBasemap(resolved)) return resolved;
  return live;
}

const kRideHudEmptyStyleFileName = 'hud-empty-style.json';

/// Charcoal paper — not the z11 Blatt. Route line still draws.
const kRideHudEmptyStyleJson =
    '{"version":8,"name":"AetherRide HUD empty","metadata":{"aetherride:hud-empty":true},"sources":{},"layers":[{"id":"background","type":"background","paint":{"background-color":"#1F1F1F"}}]}';

bool isRideHudEmptyStyle(String raw) {
  final u = raw.trim().toLowerCase();
  if (u.isEmpty) return false;
  return u.contains(kRideHudEmptyStyleFileName) ||
      u.contains('aetherride:hud-empty');
}

/// Offline HUD without street tiles: charcoal paper, not a black GL clear
/// and not the Explore-Blatt.
String rideHudMapStyle({
  required String liveStyle,
  String? resolvedStyle,
  required bool online,
  required bool offlineStreetTiles,
  String? emptyStyleUri,
}) {
  if (rideHudStreetMapNeedsNet(
        online: online,
        offlineStreetTiles: offlineStreetTiles,
      ) &&
      (emptyStyleUri ?? '').trim().isNotEmpty) {
    return emptyStyleUri!.trim();
  }
  return rideHudStyleUrl(liveStyle: liveStyle, resolvedStyle: resolvedStyle);
}

bool isLocalStyleUrl(String raw) {
  final u = raw.trim();
  if (u.isEmpty) return false;
  return u.startsWith('file:') ||
      u.startsWith('/') ||
      u.contains('asset://') ||
      u.startsWith('pmtiles://');
}

/// On-disk Übersicht (file:// style), not a CDN PMTiles URL.
bool isLocalOverviewStyleUrl(String raw) {
  final u = raw.trim().toLowerCase();
  if (u.isEmpty) return false;
  return u.startsWith('file:') || u.startsWith('pmtiles://file:');
}

/// Offline Explore: Blatt if the archive is on disk. Never swap to a CDN
/// PMTiles style that cannot load without network.
String browseStyleWhenOffline({
  required String? localStyleUri,
  required String currentStyle,
  required String streetsFallback,
}) {
  final local = localStyleUri?.trim() ?? '';
  if (local.isNotEmpty) return local;
  if (isLocalOverviewStyleUrl(currentStyle) ||
      isCdnOverviewBasemap(currentStyle)) {
    return streetsFallback;
  }
  final cur = currentStyle.trim();
  if (cur.isNotEmpty) return cur;
  return streetsFallback;
}

/// True when the HUD would actually paint from local street tiles.
/// DACH/z11 overview is never an offline ride map (black at z15).
bool rideHudUsesOfflineStreetTiles({
  required String liveStyle,
  String? resolvedStyle,
}) {
  final hud = rideHudStyleUrl(
    liveStyle: liveStyle,
    resolvedStyle: resolvedStyle,
  );
  if (!isLocalStyleUrl(hud)) return false;
  if (isOverviewOnlyBasemap(hud)) return false;
  return isStreetLevelBasemap(hud);
}

/// Offline HUD at street zoom without local street tiles: canvas is empty,
/// not a missing pack download.
bool rideHudStreetMapNeedsNet({
  required bool online,
  required bool offlineStreetTiles,
}) =>
    !online && !offlineStreetTiles;

bool isStreetLevelBasemap(String raw) =>
    isMapLibreStyleJsonUrl(raw) && !isOverviewOnlyBasemap(raw);

/// Empty PMTILES_URL / CDN overview styles switch by viewport. Custom
/// Liberty/Stadia/street-level URLs stay locked. Local PMTiles must not
/// jump back to a live CDN Blatt while the device is offline.
bool isOnlineSwitchableBasemap(String raw) {
  if (isLocalStyleUrl(raw)) return false;
  return isCdnOverviewBasemap(raw);
}

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

/// CDN archive sizes (HEAD 18.08.2026). UI must not pretend a 2 MB graph
/// includes this Blatt.
const kBasemapArchiveBytes = <String, int>{
  kDachBasemapId: 540000000,
  kFranceWestBasemapId: 307500000,
  kBeneluxBasemapId: 115600000,
  kAlpsSouthBasemapId: 68700000,
  kCataloniaPyreneesBasemapId: 46500000,
  kItalyCenterBasemapId: 35200000,
  kUkSouthBasemapId: 33800000,
  kItalyNorthBasemapId: 29500000,
  kItalySouthBasemapId: 14500000,
};

int estimatedBasemapBytesForId(String id) => kBasemapArchiveBytes[id] ?? 0;

int estimatedBasemapBytesForBbox(List<double>? bbox) =>
    estimatedBasemapBytesForId(basemapArchiveIdForBbox(bbox));

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

/// Warm HTTP cache for MapLibre style JSON before the Karte tab mounts.
Future<void> prefetchMapStyleJson(String url) async {
  final u = url.trim();
  if (u.isEmpty || u.startsWith('file:') || u.startsWith('asset:')) return;
  if (!u.startsWith('http://') && !u.startsWith('https://')) return;
  try {
    await http.get(Uri.parse(u)).timeout(const Duration(seconds: 8));
  } catch (_) {}
}
