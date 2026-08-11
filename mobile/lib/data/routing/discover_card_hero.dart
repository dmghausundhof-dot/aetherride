/// Discover card hero imagery (D-60-CARD-01) — render wiring only.
///
/// Prefers seed `thumbnail_url` when present, then curated Wikimedia photos for
/// known P0 seed IDs (no seed JSON mutation), then a location static-map URL.
/// Never invents a rating.
library;

/// HTTP headers Wikimedia / OSM expect from automated clients.
const Map<String, String> kDiscoverHeroImageHeaders = {
  'User-Agent':
      'AetherRide/1.0 (Flutter Discover; https://aetherride.vercel.app)',
  'Accept': 'image/*,*/*;q=0.8',
};

/// Optional HTTP(S) thumbnail from seed envelope (`thumbnail_url`).
String? normalizeThumbnailUrl(String? raw) {
  final t = raw?.trim() ?? '';
  if (t.isEmpty) return null;
  if (t.startsWith('http://') || t.startsWith('https://')) return t;
  return null;
}

/// Curated hero photos for locked P0 seeds (Wikimedia Commons thumbs).
/// Keys = seed ids as shipped; values = hotlink-safe thumb URLs.
const Map<String, String> kCuratedDiscoverHeroBySeedId = {
  // Rhein-Neckar Premium-Pass (Wiesloch corridor) — ≥3 photo cards.
  'seed-dach-60-rn-1-heidelberg-neckarwiese':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/20230315_Alte_Br%C3%BCcke_Heidelberg_01.jpg/960px-20230315_Alte_Br%C3%BCcke_Heidelberg_01.jpg',
  'seed-dach-60-rn-2-mannheim-schloss-waldpark':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/7/72/20180714_Schloss_Mannheim_07.jpg/960px-20180714_Schloss_Mannheim_07.jpg',
  'seed-dach-60-rn-3-heidelberg-boxberg-gaisberg':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/6/61/Schloss_Philosophenweg_Heidelberg_Germany_-_panoramio.jpg/960px-Schloss_Philosophenweg_Heidelberg_Germany_-_panoramio.jpg',
  // Berlin Nähe-Peek ~60 loops
  'seed-loop-tempelhofer-60':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Aerial_view_of_Tempelhofer_Feld.jpg/960px-Aerial_view_of_Tempelhofer_Feld.jpg',
  'seed-loop-grunewald-kurz-60':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/b/bc/Berlin_Grunewaldturm.JPG/960px-Berlin_Grunewaldturm.JPG',
  'seed-loop-spree-feierabend-60':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/27/East_side_gallery%2C_Berlin_Wall_%28Ank_Kumar%2C_Infosys_Limited_%29_06.jpg/960px-East_side_gallery%2C_Berlin_Wall_%28Ank_Kumar%2C_Infosys_Limited_%29_06.jpg',
};

/// Wikimedia Maps static image for a route center (real place, not gray).
String staticMapHeroUrl({
  required double lat,
  required double lng,
  int width = 640,
  int height = 360,
  int zoom = 13,
}) {
  final w = width.clamp(120, 1280);
  final h = height.clamp(80, 1280);
  final z = zoom.clamp(10, 16);
  return 'https://maps.wikimedia.org/img/osm-intl,$z,'
      '${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)},${w}x$h.png';
}

/// Resolve the best hero image URL for a Discover tour card.
String resolveDiscoverCardHeroUrl({
  required String id,
  required double lat,
  required double lng,
  String? thumbnailUrl,
}) {
  final fromSeed = normalizeThumbnailUrl(thumbnailUrl);
  if (fromSeed != null) return fromSeed;
  final curated = kCuratedDiscoverHeroBySeedId[id];
  if (curated != null && curated.isNotEmpty) return curated;
  return staticMapHeroUrl(lat: lat, lng: lng);
}

/// True when [id] has a curated photographic hero (not only a static map).
bool hasCuratedDiscoverHero(String id) =>
    kCuratedDiscoverHeroBySeedId.containsKey(id);
