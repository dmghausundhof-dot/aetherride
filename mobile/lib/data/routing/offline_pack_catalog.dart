// DACH offline-pack catalog rows (API + local fallback).
// `downloadable` is false for catalog stubs that have no tarball / graph.

import 'overlay_regions.dart';

/// Bundled `assets/routing/offline_graph.json` is the Freiburg / Feldberg
/// extract. CDN id stays `schwarzwald-nord`; display is Schwarzwald Süd.
const kBundledOfflineGraphRegionId = 'schwarzwald-nord';

/// SHA-256 of the bundled demo graph (must not be activated as another region).
const kBundledOfflineGraphSha256 =
    '849a4ec629b4ca0a513c8bb8475589e49cfb3d6a3f1be877557f073543b4e8f8';

enum OfflinePackKind { city, envelope, europe }

class OfflinePackRow {
  const OfflinePackRow({
    required this.id,
    required this.name,
    this.bbox,
    this.downloadable = false,
    this.bytes,
    this.graphBytes,
    this.status = 'stub',
    this.valhallaTiles = false,
    this.bikeOverlay = false,
    this.builtAt,
  });

  final String id;
  final String name;

  /// [west, south, east, north]
  final List<double>? bbox;
  final bool downloadable;

  /// tar.gz size when known (download), not the 540 MB basemap.
  final int? bytes;

  /// Uncompressed `offline_graph.json` when the catalog sends it.
  final int? graphBytes;
  final String status;
  final bool valhallaTiles;
  final bool bikeOverlay;
  final String? builtAt;

  bool get isReady => downloadable && status != 'stub';

  int? get routingBytes => graphBytes ?? bytes;

  OfflinePackRow copyWith({
    String? name,
    List<double>? bbox,
    bool? downloadable,
    int? bytes,
    int? graphBytes,
    String? status,
    bool? valhallaTiles,
    bool? bikeOverlay,
    String? builtAt,
  }) {
    return OfflinePackRow(
      id: id,
      name: name ?? this.name,
      bbox: bbox ?? this.bbox,
      downloadable: downloadable ?? this.downloadable,
      bytes: bytes ?? this.bytes,
      graphBytes: graphBytes ?? this.graphBytes,
      status: status ?? this.status,
      valhallaTiles: valhallaTiles ?? this.valhallaTiles,
      bikeOverlay: bikeOverlay ?? this.bikeOverlay,
      builtAt: builtAt ?? this.builtAt,
    );
  }
}

class OfflinePackCountryGroup {
  const OfflinePackCountryGroup({
    required this.code,
    required this.packs,
    required this.envelopes,
  });

  /// `DE`, `CH`, `AT`, `FR`, `NL`, `IT`, `LI`, `DACH`, `OTHER`.
  final String code;
  final List<OfflinePackRow> packs;
  final List<OfflinePackRow> envelopes;

  int get totalCount => packs.length + envelopes.length;
}

class OfflinePackSections {
  const OfflinePackSections({
    this.suggested,
    this.focusCountry,
    required this.installed,
    required this.countries,
    required this.stubs,
  });

  final OfflinePackRow? suggested;
  final String? focusCountry;
  final List<OfflinePackRow> installed;
  final List<OfflinePackCountryGroup> countries;
  final List<OfflinePackRow> stubs;
}

/// Länderflächen in der Registry (`de-bayern`, `ch-wallis`, `li-liechtenstein`).
bool isEnvelopePackId(String id) =>
    RegExp(r'^(de|at|ch|li)-', caseSensitive: false).hasMatch(id);

/// Whole-country envelopes zoom the browse camera to a useless scale.
bool skipFitCameraForPackId(String? id) {
  final s = id?.trim() ?? '';
  return s.isNotEmpty && isEnvelopePackId(s);
}

/// Viewport-Land zuerst, dann DACH-Kern, dann Nachbarn.
const kOfflineCountryOrder = <String>[
  'DE',
  'CH',
  'AT',
  'FR',
  'NL',
  'IT',
  'DACH',
  'LI',
  'OTHER',
];

/// From `data/routing/dach-regions.json` plus catalog-only IT/FR ids.
const kPackCountryById = <String, String>{
  'aachen': 'DE',
  'allgaeu': 'DE',
  'alsace-vins': 'FR',
  'amsterdam': 'NL',
  'annecy': 'FR',
  'at-burgenland': 'AT',
  'at-kaernten': 'AT',
  'at-niederoesterreich': 'AT',
  'at-oberoesterreich': 'AT',
  'at-salzburg': 'AT',
  'at-steiermark': 'AT',
  'at-tirol': 'AT',
  'at-vorarlberg': 'AT',
  'augsburg': 'DE',
  'bari': 'IT',
  'basel': 'CH',
  'bayerischer-wald': 'DE',
  'berlin': 'DE',
  'bern': 'CH',
  'bodensee': 'DACH',
  'bordeaux': 'FR',
  'bregenz': 'AT',
  'bremen': 'DE',
  'ch-berner-oberland': 'CH',
  'ch-genfersee': 'CH',
  'ch-graubuenden': 'CH',
  'ch-jura': 'CH',
  'ch-mittelland': 'CH',
  'ch-nordwest': 'CH',
  'ch-ostschweiz': 'CH',
  'ch-tessin': 'CH',
  'ch-wallis': 'CH',
  'ch-zentralschweiz': 'CH',
  'ch-zuerichsee': 'CH',
  'chambery': 'FR',
  'chiemgau': 'DE',
  'chur': 'CH',
  'clermont-ferrand': 'FR',
  'davos': 'CH',
  'de-baden-wuerttemberg': 'DE',
  'de-bayern': 'DE',
  'de-brandenburg': 'DE',
  'de-hessen': 'DE',
  'de-mecklenburg-vorpommern': 'DE',
  'de-niedersachsen': 'DE',
  'de-nrw': 'DE',
  'de-rlp': 'DE',
  'de-saarland': 'DE',
  'de-sachsen': 'DE',
  'de-sachsen-anhalt': 'DE',
  'de-schleswig-holstein': 'DE',
  'de-thueringen': 'DE',
  'den-haag': 'NL',
  'dijon': 'FR',
  'dresden-elbland': 'DE',
  'duesseldorf': 'DE',
  'eifel-trails': 'DE',
  'eindhoven': 'NL',
  'erfurt': 'DE',
  'firenze': 'IT',
  'frankfurt-rhein-main': 'DE',
  'freiburg': 'DE',
  'genf': 'CH',
  'graz': 'AT',
  'grenoble': 'FR',
  'groningen': 'NL',
  'hamburg': 'DE',
  'hannover': 'DE',
  'harz': 'DE',
  'innsbruck': 'AT',
  'interlaken': 'CH',
  'jura-fr': 'FR',
  'karlsruhe': 'DE',
  'kassel': 'DE',
  'kiel': 'DE',
  'kitzbuehel': 'AT',
  'klagenfurt': 'AT',
  'koblenz': 'DE',
  'koeln-rhein': 'DE',
  'lausanne': 'CH',
  'leipzig': 'DE',
  'li-liechtenstein': 'LI',
  'lille': 'FR',
  'linz': 'AT',
  'luebeck': 'DE',
  'lugano': 'CH',
  'luzern': 'CH',
  'lyon': 'FR',
  'magdeburg': 'DE',
  'marseille': 'FR',
  'milano': 'IT',
  'montpellier': 'FR',
  'morzine': 'FR',
  'muenchen': 'DE',
  'muenster': 'DE',
  'nancy-moselle': 'FR',
  'nantes': 'FR',
  'napoli': 'IT',
  'nice': 'FR',
  'nuernberg': 'DE',
  'paris': 'FR',
  'pfalz': 'DE',
  'reims': 'FR',
  'rennes': 'FR',
  'rhein-neckar': 'DE',
  'roma': 'IT',
  'rostock': 'DE',
  'rotterdam': 'NL',
  'rouen': 'FR',
  'ruhrgebiet': 'DE',
  'saarbruecken': 'DE',
  'salzburg': 'AT',
  'sauerland': 'DE',
  'schwarzwald-nord': 'DE',
  'st-gallen': 'CH',
  'st-moritz': 'CH',
  'strasbourg': 'FR',
  'stuttgart': 'DE',
  'thueringer-wald': 'DE',
  'torino': 'IT',
  'toulouse': 'FR',
  'trier-mosel': 'DE',
  'utrecht': 'NL',
  'villach': 'AT',
  'vosges': 'FR',
  'wien': 'AT',
  'zermatt': 'CH',
  'zuerich': 'CH',
};

/// Registry names for country-area packs (`de-bayern`, `ch-wallis`, …).
const kEnvelopePackNames = <String, String>{
  'de-schleswig-holstein': 'Schleswig-Holstein',
  'de-niedersachsen': 'Niedersachsen',
  'de-mecklenburg-vorpommern': 'Mecklenburg-Vorpommern',
  'de-brandenburg': 'Brandenburg',
  'de-sachsen-anhalt': 'Sachsen-Anhalt',
  'de-sachsen': 'Sachsen',
  'de-thueringen': 'Thüringen',
  'de-hessen': 'Hessen',
  'de-nrw': 'Nordrhein-Westfalen',
  'de-rlp': 'Rheinland-Pfalz',
  'de-saarland': 'Saarland',
  'de-baden-wuerttemberg': 'Baden-Württemberg',
  'de-bayern': 'Bayern',
  'at-vorarlberg': 'Vorarlberg',
  'at-tirol': 'Tirol',
  'at-salzburg': 'Land Salzburg',
  'at-oberoesterreich': 'Oberösterreich',
  'at-niederoesterreich': 'Niederösterreich',
  'at-steiermark': 'Steiermark',
  'at-kaernten': 'Kärnten',
  'at-burgenland': 'Burgenland',
  'ch-genfersee': 'Genfersee / Romandie',
  'ch-jura': 'Jura / Westschweiz',
  'ch-mittelland': 'Schweizer Mittelland',
  'ch-nordwest': 'Nordwestschweiz',
  'ch-zuerichsee': 'Zürichsee / Zürcher Oberland',
  'ch-ostschweiz': 'Ostschweiz',
  'ch-zentralschweiz': 'Zentralschweiz',
  'ch-tessin': 'Tessin',
  'ch-graubuenden': 'Graubünden',
  'ch-wallis': 'Wallis',
  'ch-berner-oberland': 'Berner Oberland',
  'li-liechtenstein': 'Liechtenstein',
};

/// Bilingual CH envelopes follow the UI language; others keep the DE registry.
String envelopePackDisplayName({
  required String id,
  required String languageCode,
  String? fallback,
}) {
  final lang = languageCode.toLowerCase().split('_').first.split('-').first;
  final named = switch ((lang, id)) {
    ('fr', 'ch-wallis') => 'Valais',
    ('fr', 'ch-tessin') => 'Tessin',
    ('fr', 'ch-graubuenden') => 'Grisons',
    ('fr', 'ch-genfersee') => 'Léman / Romandie',
    ('it', 'ch-wallis') => 'Vallese',
    ('it', 'ch-tessin') => 'Ticino',
    ('it', 'ch-graubuenden') => 'Grigioni',
    ('it', 'ch-genfersee') => 'Lago Lemano / Romandia',
    ('en', 'ch-wallis') => 'Valais',
    ('en', 'ch-tessin') => 'Ticino',
    ('en', 'ch-graubuenden') => 'Graubünden',
    ('en', 'ch-genfersee') => 'Lake Geneva / Romandy',
    _ => null,
  };
  return named ?? kEnvelopePackNames[id] ?? fallback ?? id;
}

String packCountryCode(OfflinePackRow r) {
  final known = kPackCountryById[r.id];
  if (known != null && known.isNotEmpty) return known;
  final id = r.id.toLowerCase();
  if (id.startsWith('de-')) return 'DE';
  if (id.startsWith('at-')) return 'AT';
  if (id.startsWith('ch-')) return 'CH';
  if (id.startsWith('li-')) return 'LI';
  return 'OTHER';
}

List<String> sortOfflineCountryCodes(
  Iterable<String> codes, {
  String? focus,
}) {
  final list = codes.toSet().toList();
  int rank(String c) {
    if (focus != null && c == focus) return -1;
    final i = kOfflineCountryOrder.indexOf(c);
    return i < 0 ? 99 : i;
  }

  list.sort((a, b) {
    final c = rank(a).compareTo(rank(b));
    return c != 0 ? c : a.compareTo(b);
  });
  return list;
}

/// Same cut as the DACH z11 basemap extract.
const kDachOverviewBbox = <double>[5.8, 45.75, 17.25, 55.15];

OfflinePackKind inferPackKind(OfflinePackRow r) {
  if (isEnvelopePackId(r.id)) return OfflinePackKind.envelope;
  final b = r.bbox;
  if (b != null && b.length >= 4) {
    final cx = (b[0] + b[2]) / 2;
    final cy = (b[1] + b[3]) / 2;
    if (!pointInLngLatBbox(kDachOverviewBbox, cx, cy)) {
      return OfflinePackKind.europe;
    }
  }
  return OfflinePackKind.city;
}

bool pointInLngLatBbox(List<double> bbox, double lng, double lat) {
  if (bbox.length < 4) return false;
  return lng >= bbox[0] && lat >= bbox[1] && lng <= bbox[2] && lat <= bbox[3];
}

bool bboxCoversLngLats(
  List<double> bbox,
  Iterable<({double lng, double lat})> points,
) {
  for (final p in points) {
    if (!pointInLngLatBbox(bbox, p.lng, p.lat)) return false;
  }
  return true;
}

/// Manifest/overlay bbox wins. Inflated prefs must not claim the Alps.
List<double>? preferDiskPackBbox({
  List<double>? fromDisk,
  List<double>? fromPrefs,
}) {
  if (fromDisk != null && fromDisk.length >= 4) return fromDisk;
  if (fromPrefs != null && fromPrefs.length >= 4) return fromPrefs;
  return null;
}

/// Keep shape; cap at [maxPoints] evenly spaced samples (includes ends).
List<({double lng, double lat})> sampleLngLats(
  List<({double lng, double lat})> points, {
  int maxPoints = 24,
}) {
  if (points.length <= maxPoints) return points;
  if (maxPoints < 2) return [points.first];
  final out = <({double lng, double lat})>[];
  for (var i = 0; i < maxPoints; i++) {
    final idx = (i * (points.length - 1) / (maxPoints - 1)).round();
    out.add(points[idx]);
  }
  return out;
}

OfflinePackRow? parseOfflinePackRow(Object? raw) {
  if (raw is! Map) return null;
  final id = raw['id'] as String?;
  if (id == null || id.isEmpty) return null;
  List<double>? bbox;
  final b = raw['bbox'];
  if (b is List && b.length >= 4) {
    bbox = [
      for (final x in b.take(4))
        if (x is num) x.toDouble(),
    ];
    if (bbox.length < 4) bbox = null;
  }
  final files = raw['files'];
  final inferred = files is Map && files.isNotEmpty;
  final downloadable = raw['downloadable'] as bool? ?? inferred;
  final status =
      (raw['status'] as String?) ?? (downloadable ? 'ready' : 'stub');
  int? bytes = (raw['bytes'] as num?)?.toInt();
  int? graphBytes = (raw['graphBytes'] as num?)?.toInt();
  if (files is Map) {
    final graph = files['offline_graph.json'];
    if (graph is Map && graph['bytes'] is num) {
      graphBytes ??= (graph['bytes'] as num).toInt();
    }
    if (bytes == null) {
      for (final e in files.entries) {
        final k = e.key.toString();
        if ((k.endsWith('.tar.gz') || k.endsWith('.tgz')) && e.value is Map) {
          final n = (e.value as Map)['bytes'];
          if (n is num) {
            bytes = n.toInt();
            break;
          }
        }
      }
    }
  }
  var valhallaTiles = false;
  var bikeOverlay = false;
  final engines = raw['engines'];
  if (engines is Map) {
    valhallaTiles = engines['valhalla_tiles'] == true;
    bikeOverlay = engines['bike_overlay'] == true;
  }
  return OfflinePackRow(
    id: id,
    name: (raw['name'] as String?) ?? id,
    bbox: bbox,
    downloadable: downloadable,
    bytes: bytes,
    graphBytes: graphBytes,
    status: status,
    valhallaTiles: valhallaTiles,
    bikeOverlay: bikeOverlay,
    builtAt: raw['builtAt'] as String?,
  );
}

/// Parse `catalog.json` / `/api/offline/packs` (`{ "packs": [ ... ] }`).
List<OfflinePackRow> parseOfflineCatalogPacks(Object? data) {
  if (data is! Map) return const [];
  final packs = <OfflinePackRow>[];
  for (final raw in (data['packs'] as List? ?? const [])) {
    final row = parseOfflinePackRow(raw);
    if (row != null) packs.add(row);
  }
  return packs;
}

List<OfflinePackRow> mergeOfflineCatalog({
  required List<OfflinePackRow> api,
  required List<OverlayRegion> local,
}) {
  final byId = <String, OfflinePackRow>{
    for (final p in api) p.id: p,
  };
  for (final r in local) {
    final existing = byId[r.id];
    if (existing == null) {
      byId[r.id] = OfflinePackRow(
        id: r.id,
        name: r.name,
        bbox: r.bbox,
        downloadable: false,
        status: 'stub',
      );
    } else if (existing.bbox == null || existing.bbox!.length < 4) {
      byId[r.id] = existing.copyWith(bbox: r.bbox);
    }
  }
  return byId.values.toList();
}

/// Prefer [ready] rows when merging two catalog sources (API + Storage CDN).
List<OfflinePackRow> mergePreferReady(
  List<OfflinePackRow> primary,
  List<OfflinePackRow> extra,
) {
  final byId = <String, OfflinePackRow>{
    for (final p in primary) p.id: p,
  };
  for (final p in extra) {
    final existing = byId[p.id];
    if (existing == null || (p.isReady && !existing.isReady)) {
      byId[p.id] = p;
    }
  }
  return byId.values.toList();
}

double? packDistanceDeg(OfflinePackRow r, double lng, double lat) {
  final b = r.bbox;
  if (b == null || b.length < 4) return null;
  final cx = (b[0] + b[2]) / 2;
  final cy = (b[1] + b[3]) / 2;
  final dx = cx - lng;
  final dy = cy - lat;
  return dx * dx + dy * dy;
}

List<OfflinePackRow> sortOfflinePacks(
  List<OfflinePackRow> packs, {
  double? userLng,
  double? userLat,
}) {
  final copy = [...packs];
  copy.sort((a, b) {
    final da = a.isReady ? 0 : 1;
    final db = b.isReady ? 0 : 1;
    if (da != db) return da - db;
    if (userLng != null && userLat != null) {
      final ra = packDistanceDeg(a, userLng, userLat) ?? 1e9;
      final rb = packDistanceDeg(b, userLng, userLat) ?? 1e9;
      final c = ra.compareTo(rb);
      if (c != 0) return c;
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return copy;
}

String formatPackBytes(int? bytes) {
  if (bytes == null || bytes <= 0) return '';
  if (bytes < 1000000) {
    return '${(bytes / 1000).round()} KB';
  }
  return '${(bytes / 1000000).toStringAsFixed(1)} MB';
}

/// tar.gz bigger than this: confirm before download (Saarland, Schwarzwald).
const kLargePackConfirmBytes = 20000000;

bool packNeedsDownloadConfirm(OfflinePackRow r) {
  final n = r.bytes ?? 0;
  return n >= kLargePackConfirmBytes;
}

/// Closed ring `[lng, lat]` for a pack bbox `[west, south, east, north]`.
List<List<double>> offlinePackBboxRing(List<double> bbox) {
  if (bbox.length < 4) return const [];
  final w = bbox[0];
  final s = bbox[1];
  final e = bbox[2];
  final n = bbox[3];
  return [
    [w, s],
    [e, s],
    [e, n],
    [w, n],
    [w, s],
  ];
}

/// Chamfered bbox so the map wash reads as coverage, not a country border.
List<List<double>> offlinePackCoverageRing(List<double> bbox) {
  if (bbox.length < 4) return const [];
  final w = bbox[0];
  final s = bbox[1];
  final e = bbox[2];
  final n = bbox[3];
  final spanLng = (e - w).abs();
  final spanLat = (n - s).abs();
  if (spanLng < 1e-5 || spanLat < 1e-5) return offlinePackBboxRing(bbox);
  final dx = spanLng * 0.12;
  final dy = spanLat * 0.12;
  return [
    [w + dx, s],
    [e - dx, s],
    [e, s + dy],
    [e, n - dy],
    [e - dx, n],
    [w + dx, n],
    [w, n - dy],
    [w, s + dy],
    [w + dx, s],
  ];
}

DateTime? parsePackBuiltAt(String? raw) {
  final s = raw?.trim() ?? '';
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}

/// True when the CDN/catalog timestamp is newer than the copy on disk.
bool packRemoteIsNewer({
  String? localBuiltAt,
  String? remoteBuiltAt,
}) {
  final remote = parsePackBuiltAt(remoteBuiltAt);
  if (remote == null) return false;
  final local = parsePackBuiltAt(localBuiltAt);
  if (local == null) return false;
  return remote.toUtc().isAfter(
        local.toUtc().add(const Duration(minutes: 5)),
      );
}

bool networkInterfaceLooksLikeWifi(String name) {
  final n = name.toLowerCase();
  if (n.contains('pdp_ip') ||
      n.contains('rmnet') ||
      n.contains('ccmni') ||
      n.contains('wwan') ||
      n.contains('rmnet_data') ||
      n.contains('cellular')) {
    return false;
  }
  return n.contains('wlan') ||
      n.contains('wifi') ||
      n == 'en0' ||
      n.startsWith('en');
}

bool networkInterfaceLooksLikeCellular(String name) {
  final n = name.toLowerCase();
  return n.contains('pdp_ip') ||
      n.contains('rmnet') ||
      n.contains('ccmni') ||
      n.contains('wwan') ||
      n.contains('cellular');
}

String offlinePackSubtitle(
  OfflinePackRow r, {
  required bool active,
  required bool installed,
}) {
  if (active) return 'Aktiv';
  if (installed) return 'Installiert';
  if (!r.isReady) {
    if (r.id == kBundledOfflineGraphRegionId) {
      return 'Demo-Graph in der App (kein Remote-Pack)';
    }
    return 'Noch nicht gebaut';
  }
  final size = formatPackBytes(r.routingBytes);
  if (isEnvelopePackId(r.id)) {
    return size.isEmpty
        ? 'Routing · Landesfläche'
        : '$size · Routing · Landesfläche';
  }
  return size.isEmpty ? 'Routing laden' : '$size · Routing';
}

double? packBboxArea(OfflinePackRow r) {
  final b = r.bbox;
  if (b == null || b.length < 4) return null;
  return (b[2] - b[0]) * (b[3] - b[1]);
}

bool _packSuggestable(OfflinePackRow p, {required bool readyOnly}) {
  final b = p.bbox;
  if (b == null || b.length < 4) return false;
  if (!readyOnly) return true;
  return p.isReady || p.id == kBundledOfflineGraphRegionId;
}

OfflinePackRow? _smallestWhere(
  Iterable<OfflinePackRow> packs,
  bool Function(OfflinePackRow) test,
) {
  final hits = [
    for (final p in packs)
      if (test(p)) p
  ];
  if (hits.isEmpty) return null;
  hits.sort((a, b) {
    final aa = packBboxArea(a) ?? 1e18;
    final bb = packBboxArea(b) ?? 1e18;
    return aa.compareTo(bb);
  });
  return hits.first;
}

OfflinePackRow? suggestedPackForPoint({
  required List<OfflinePackRow> packs,
  required double lng,
  required double lat,
}) {
  return _smallestWhere(
    packs,
    (p) =>
        _packSuggestable(p, readyOnly: true) &&
        pointInLngLatBbox(p.bbox!, lng, lat),
  );
}

/// Smallest bbox covering start, end and extras (vias / samples). Else midpoint.
OfflinePackRow? suggestedPackForRoute({
  required List<OfflinePackRow> packs,
  required double fromLng,
  required double fromLat,
  required double toLng,
  required double toLat,
  List<({double lng, double lat})> extra = const [],
}) {
  final points = <({double lng, double lat})>[
    (lng: fromLng, lat: fromLat),
    (lng: toLng, lat: toLat),
    ...extra,
  ];
  final midLng = (fromLng + toLng) / 2;
  final midLat = (fromLat + toLat) / 2;
  for (final readyOnly in [true, false]) {
    final all = _smallestWhere(
      packs,
      (p) =>
          _packSuggestable(p, readyOnly: readyOnly) &&
          bboxCoversLngLats(p.bbox!, points),
    );
    if (all != null) return all;
    final mid = _smallestWhere(
      packs,
      (p) =>
          _packSuggestable(p, readyOnly: readyOnly) &&
          pointInLngLatBbox(p.bbox!, midLng, midLat),
    );
    if (mid != null) return mid;
  }
  return null;
}

/// Visible metro packs near the map, rest behind „Weitere“.
const kOfflineCountryVisiblePacks = 8;

({List<OfflinePackRow> shown, List<OfflinePackRow> more}) collapseCountryPacks({
  required List<OfflinePackRow> packs,
  double? userLng,
  double? userLat,
  String? pinId,
  bool searching = false,
  int keep = kOfflineCountryVisiblePacks,
}) {
  final sorted = sortOfflinePacks(packs, userLng: userLng, userLat: userLat);
  if (searching || sorted.length <= keep) {
    return (shown: sorted, more: const []);
  }
  final shown = sorted.take(keep).toList();
  final more = sorted.skip(keep).toList();
  if (pinId == null) return (shown: shown, more: more);
  final i = more.indexWhere((p) => p.id == pinId);
  if (i < 0) return (shown: shown, more: more);
  return (
    shown: [...shown, more[i]],
    more: [...more]..removeAt(i),
  );
}

OfflinePackRow? packById(Iterable<OfflinePackRow> packs, String? id) {
  final want = id?.trim() ?? '';
  if (want.isEmpty) return null;
  for (final p in packs) {
    if (p.id == want) return p;
  }
  return null;
}

/// Stubs are not a primary CTA — they are not tappable in the sheet.
bool packIsPinTarget(
  OfflinePackRow r, {
  required Set<String> installed,
}) {
  if (installed.contains(r.id)) return true;
  if (r.id == kBundledOfflineGraphRegionId) return true;
  return r.isReady;
}

OfflinePackSections groupOfflinePacks({
  required List<OfflinePackRow> filtered,
  required Set<String> installed,
  double? userLng,
  double? userLat,
  required bool searching,
  String? focusPackId,
}) {
  final covering = (userLng != null && userLat != null)
      ? suggestedPackForPoint(packs: filtered, lng: userLng, lat: userLat)
      : null;
  final pinnedRaw = packById(filtered, focusPackId);
  final pinned =
      pinnedRaw != null && packIsPinTarget(pinnedRaw, installed: installed)
          ? pinnedRaw
          : null;
  final suggested = searching ? null : (pinned ?? covering);
  final focusCountry = suggested != null
      ? packCountryCode(suggested)
      : covering != null
          ? packCountryCode(covering)
          : null;

  final skip = <String>{
    ...installed,
    if (suggested != null) suggested.id,
  };

  final installedRows = [
    for (final r in filtered)
      if (installed.contains(r.id) && r.id != suggested?.id) r,
  ];

  final packsBy = <String, List<OfflinePackRow>>{};
  final envelopesBy = <String, List<OfflinePackRow>>{};
  final stubs = <OfflinePackRow>[];
  for (final r in filtered) {
    if (skip.contains(r.id)) continue;
    final demo = r.id == kBundledOfflineGraphRegionId;
    if (!r.isReady && !demo) {
      stubs.add(r);
      continue;
    }
    final code = packCountryCode(r);
    if (inferPackKind(r) == OfflinePackKind.envelope) {
      envelopesBy.putIfAbsent(code, () => []).add(r);
    } else {
      packsBy.putIfAbsent(code, () => []).add(r);
    }
  }

  final codes = sortOfflineCountryCodes(
    {...packsBy.keys, ...envelopesBy.keys},
    focus: focusCountry,
  );
  final countries = [
    for (final code in codes)
      OfflinePackCountryGroup(
        code: code,
        packs: packsBy[code] ?? const [],
        envelopes: envelopesBy[code] ?? const [],
      ),
  ];

  return OfflinePackSections(
    suggested: suggested,
    focusCountry: focusCountry,
    installed: installedRows,
    countries: countries,
    stubs: stubs,
  );
}

/// Normalize MapLibre offline progress (0–1 or 0–100) to 0–1.
double normalizeOfflineProgress(double p) {
  final n = p > 1 ? p / 100 : p;
  if (n.isNaN || n.isInfinite) return 0;
  return n.clamp(0.0, 1.0);
}

/// Vector-tile zoom cap. z14 on a city bbox is too many OpenFreeMap tiles
/// for a first download; z13 stays usable on the trail.
double maxBasemapZoomForBbox(List<double> bbox) {
  if (bbox.length < 4) return 12;
  final area = (bbox[2] - bbox[0]) * (bbox[3] - bbox[1]);
  if (area > 1.5) return 11;
  if (area > 0.4) return 12;
  return 13;
}

const kBasemapMinZoom = 8.0;

/// True when a graph on disk actually belongs to [regionId].
/// Rejects the bundled Schwarzwald extract copied into a stub folder.
bool packGraphBelongsToRegion({
  required String regionId,
  required int graphBytes,
  String? manifestId,
  String? graphSha256,
}) {
  if (graphBytes < 1000) return false;
  if (manifestId != null && manifestId.isNotEmpty && manifestId != regionId) {
    return false;
  }
  final sha = graphSha256?.toLowerCase();
  if (sha != null &&
      sha.isNotEmpty &&
      sha == kBundledOfflineGraphSha256 &&
      regionId != kBundledOfflineGraphRegionId) {
    return false;
  }
  if (manifestId == regionId) return true;
  // No manifest / no SHA: the bundled graph is ~5.44 MB.
  if (regionId != kBundledOfflineGraphRegionId &&
      graphBytes >= 5200000 &&
      graphBytes <= 5600000) {
    return false;
  }
  return true;
}

enum ExtractedGraphCheck { ok, missing, shaMismatch, bundledMislabel }

ExtractedGraphCheck checkExtractedGraph({
  required String regionId,
  required int graphBytes,
  String? actualSha256,
  String? expectedSha256,
  String? manifestId,
}) {
  if (graphBytes < 1000) return ExtractedGraphCheck.missing;
  if (!packGraphBelongsToRegion(
    regionId: regionId,
    graphBytes: graphBytes,
    manifestId: manifestId,
    graphSha256: actualSha256,
  )) {
    return ExtractedGraphCheck.bundledMislabel;
  }
  if (expectedSha256 != null &&
      expectedSha256.isNotEmpty &&
      actualSha256 != null &&
      actualSha256.toLowerCase() != expectedSha256.toLowerCase()) {
    return ExtractedGraphCheck.shaMismatch;
  }
  return ExtractedGraphCheck.ok;
}

String extractedGraphError(ExtractedGraphCheck check, String name) {
  return switch (check) {
    ExtractedGraphCheck.ok => '',
    ExtractedGraphCheck.missing => 'Kein Graph in $name',
    ExtractedGraphCheck.shaMismatch => 'Graph-SHA von $name stimmt nicht',
    ExtractedGraphCheck.bundledMislabel =>
      'Demo-Graph Schwarzwald passt nicht zu $name',
  };
}

String offlineEngineStatusLine({
  required String valhallaStatus,
  String? engineHint,
}) {
  final s = valhallaStatus.trim();
  final h = engineHint?.trim();
  if (h == null || h.isEmpty) return s;
  if (s.contains(h)) return s;
  return '$s · $h';
}

/// Release copy: graph routing until Valhalla region tiles exist.
String honestOfflineEngineCopy({
  required String valhallaStatus,
  String? engineHint,
}) {
  final tiles = engineHint == 'valhalla' ||
      valhallaStatus.toLowerCase().contains('valhalla-tiles');
  if (tiles) {
    return offlineEngineStatusLine(
      valhallaStatus: valhallaStatus,
      engineHint: engineHint,
    );
  }
  final linked = valhallaStatus.contains('Valhalla-Feature verfügbar') ||
      valhallaStatus.contains('libvalhalla gelinkt') ||
      valhallaStatus.contains('valhalla_linked');
  if (linked) {
    return 'Graph-Engine · Valhalla gelinkt, Region-Tiles fehlen noch';
  }
  return 'Graph-Engine · Valhalla-Tiles nicht gebaut';
}

List<OfflinePackRow> visibleReadyPacks({
  required List<OfflinePackRow> filtered,
  required Set<String> installed,
  required bool searching,
}) {
  if (searching) return filtered;
  return [
    for (final r in filtered)
      if (r.isReady || installed.contains(r.id)) r,
  ];
}

List<OfflinePackRow> visibleStubPacks({
  required List<OfflinePackRow> filtered,
  required Set<String> installed,
  required bool searching,
}) {
  if (searching) return const [];
  return [
    for (final r in filtered)
      if (!r.isReady && !installed.contains(r.id)) r,
  ];
}
