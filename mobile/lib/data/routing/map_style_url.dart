/// Public pack bucket (not a secret). Used by local PMTiles download.
const kOfflinePacksPublicCdnRoot =
    'https://krmgatsugplouzrhhozn.supabase.co/storage/v1/object/public/offline-packs';

const kDachBasemapStyleUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/dach-z11-style.json';

const kFranceWestBasemapStyleUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/france-west-z11-style.json';

const kAlpsSouthBasemapStyleUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/alps-south-z11-style.json';

const kDachBasemapId = 'dach-z11';
const kFranceWestBasemapId = 'france-west-z11';
const kAlpsSouthBasemapId = 'alps-south-z11';

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

/// Smallest-area first so overlap (Grenoble / Annecy) prefers Alps-south.
const kOnlineBasemapArchives = <OnlineBasemapArchive>[
  OnlineBasemapArchive(
    id: kAlpsSouthBasemapId,
    bbox: kAlpsSouthBasemapBbox,
    styleUrl: kAlpsSouthBasemapStyleUrl,
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
      u.contains('dach-z11-style.json') ||
      u.contains('dach-z12-style.json') ||
      u.contains('dach-z13-style.json') ||
      u.contains('france-west-z11-style.json') ||
      u.contains('alps-south-z11-style.json');
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
