/// Public pack bucket (not a secret). Used by local PMTiles download.
const kOfflinePacksPublicCdnRoot =
    'https://krmgatsugplouzrhhozn.supabase.co/storage/v1/object/public/offline-packs';

const kDachBasemapStyleUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/dach-z11-style.json';

const kFranceWestBasemapStyleUrl =
    '$kOfflinePacksPublicCdnRoot/basemap/france-west-z11-style.json';

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
/// Copy the archive onto the device instead ([OfflinePmtilesStore]).
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

String localPmtilesSourceUrl(String archivePath) =>
    'pmtiles://file://$archivePath';

/// Point the vector source at a local archive. Glyphs/sprites stay remote.
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
