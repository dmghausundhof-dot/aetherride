import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/config.dart';
import '../../domain/bike.dart';
import '../../domain/routing/bike_overlay_class.dart';
import '../../domain/routing/browse_map_paint.dart';
import 'map_style_url.dart';
import 'offline_tiles.dart';
import 'overlay_regions.dart';
import 'sgrade_live.dart';

const kBikeOverlaySourceId = 'bike-overlay';
const kBikeOverlayGeojsonName = 'bike-overlay.geojson';
const kBikeOverlayPmtilesName = 'bike-overlay.pmtiles';
const kBikeOverlaySampleAsset = 'assets/routing/bike-overlay-sample.geojson';

/// Past atlas zoom: pack / DACH ways replace the signed mesh.
const kBikeWaysMinZoom = BrowseMapPaint.packMinZoom;

/// Region packs that already publish a way-level bike-overlay on the CDN.
const kDetailBikeOverlayPacks = <String>{
  'rhein-neckar',
  'schwarzwald-nord',
  'vosges',
  'innsbruck',
  'kitzbuehel',
  'zermatt',
  'davos',
  'st-moritz',
  'interlaken',
  'morzine',
  'annecy',
  'lyon',
  'paris',
  'strasbourg',
  'bordeaux',
  'nantes',
  'toulouse',
  'nice',
  'marseille',
  'amsterdam',
  'utrecht',
  'rotterdam',
  'den-haag',
  'eindhoven',
  'groningen',
  'lille',
  'montpellier',
  'grenoble',
  'dijon',
  'chambery',
  'clermont-ferrand',
  'reims',
  'rennes',
  'rouen',
  'alsace-vins',
  'nancy-moselle',
  'jura-fr',
  'milano',
  'torino',
  'firenze',
  'roma',
  'napoli',
  'bari',
};

enum OnlineBikeOverlayKind { ways, mesh, none }

class OnlineBikeOverlayChoice {
  const OnlineBikeOverlayChoice({required this.kind, this.url});
  final OnlineBikeOverlayKind kind;
  final String? url;
}

const kBikeOverlayLayerIds = <BikeOverlayClass, String>{
  BikeOverlayClass.mtb: 'bike-overlay-mtb',
  BikeOverlayClass.mtbUnrated: 'bike-overlay-mtb-unrated',
  BikeOverlayClass.gravel: 'bike-overlay-gravel',
  BikeOverlayClass.road: 'bike-overlay-road',
  BikeOverlayClass.urban: 'bike-overlay-urban',
};

const kBikeOverlayQueryLayerIds = <String>[
  kOsmSGradeLayerId,
  kOsmLivePathLayerId,
  kOsmLiveTrackLayerId,
  kOsmLiveCyclewayLayerId,
  'bike-overlay-mtb',
  'bike-overlay-mtb-unrated',
  'bike-overlay-gravel',
  'bike-overlay-road',
  'bike-overlay-urban',
];

/// Region-Packs enden typisch bei z14; darüber named Overpass oder Overzoom-Hit.
const kBikeOverlayVectorMaxZoom = 14.0;

/// RN bbox from `data/routing/regions/rhein-neckar.json`.
const rheinNeckarBbox = [8.2, 49.2, 9.0, 49.6];

bool pointInRheinNeckar(double lng, double lat) =>
    lng >= rheinNeckarBbox[0] &&
    lat >= rheinNeckarBbox[1] &&
    lng <= rheinNeckarBbox[2] &&
    lat <= rheinNeckarBbox[3];

/// True when a signed cycle-route mesh exists for the Blatt under the camera.
bool pointInOnlineCycleMesh(double lng, double lat) =>
    onlineCycleMeshPmtilesUrlForPoint(lng, lat) != null;

/// DACH online Blatt — same bbox as dach-z11. Ways overlay, not per-sheet mesh.
bool pointInDachWays(double lng, double lat) =>
    lng >= 5.8 && lng <= 17.25 && lat >= 45.75 && lat <= 55.15;

class _CountryWaysSheet {
  const _CountryWaysSheet(this.url, this.bbox);
  final String url;
  final List<double> bbox;
  bool contains(double lng, double lat) =>
      lng >= bbox[0] &&
      lat >= bbox[1] &&
      lng <= bbox[2] &&
      lat <= bbox[3];
}

/// CDN ways that exist today. France/UK/Catalonia use live OSM until tiled.
const kCountryWaysSheets = <_CountryWaysSheet>[
  _CountryWaysSheet(kNlWaysPmtilesUrl, [3.2, 50.75, 7.25, 53.7]),
  _CountryWaysSheet(kBeWaysPmtilesUrl, [2.4, 49.4, 6.45, 51.55]),
  _CountryWaysSheet(kItalyWaysPmtilesUrl, [6.6, 36.6, 18.55, 47.1]),
  _CountryWaysSheet(kDachWaysPmtilesUrl, [5.8, 45.75, 17.25, 55.15]),
];

bool pointInNlWays(double lng, double lat) {
  if (lng < 3.2 || lng > 7.25 || lat > 53.7) return false;
  if (lng >= 5.5) return lat >= 50.75;
  return lat >= 51.15;
}

String? countryWaysPmtilesUrl(double lng, double lat) {
  if (pointInNlWays(lng, lat)) return kNlWaysPmtilesUrl;
  for (final s in kCountryWaysSheets) {
    if (s.url == kNlWaysPmtilesUrl) continue;
    if (s.contains(lng, lat)) return s.url;
  }
  return null;
}

/// Live OSM fills mesh-only / empty Blätter. Pack and country ways stay first.
bool browseUsesLiveNetworkFallback(OnlineBikeOverlayChoice choice) =>
    choice.kind != OnlineBikeOverlayKind.ways;

String? detailOverlayPackIdForPoint(double lng, double lat) {
  final hits = [
    for (final r in kOverlayRegions)
      if (r.contains(lng, lat) && kDetailBikeOverlayPacks.contains(r.id)) r,
  ];
  if (hits.isEmpty) return null;
  hits.sort((a, b) {
    final aa = (a.bbox[2] - a.bbox[0]) * (a.bbox[3] - a.bbox[1]);
    final bb = (b.bbox[2] - b.bbox[0]) * (b.bbox[3] - b.bbox[1]);
    return aa.compareTo(bb);
  });
  return hits.first.id;
}

OnlineBikeOverlayChoice chooseOnlineBikeOverlay({
  required double lng,
  required double lat,
  required double zoom,
}) {
  final packId = detailOverlayPackIdForPoint(lng, lat);
  if (packId != null && zoom >= kBikeWaysMinZoom) {
    return OnlineBikeOverlayChoice(
      kind: OnlineBikeOverlayKind.ways,
      url: AppConfig.offlinePackObjectUrl(packId, kBikeOverlayPmtilesName),
    );
  }
  if (zoom >= kBikeWaysMinZoom) {
    final country = countryWaysPmtilesUrl(lng, lat);
    if (country != null) {
      return OnlineBikeOverlayChoice(
        kind: OnlineBikeOverlayKind.ways,
        url: country,
      );
    }
  }
  final meshUrl = onlineCycleMeshPmtilesUrlForPoint(lng, lat);
  if (meshUrl != null) {
    return OnlineBikeOverlayChoice(
      kind: OnlineBikeOverlayKind.mesh,
      url: meshUrl,
    );
  }
  return const OnlineBikeOverlayChoice(kind: OnlineBikeOverlayKind.none);
}

/// True when a cycle-mesh or city-pack overlay exists for this view.
bool overlayDataExpectedAt(double lng, double lat, {double zoom = 12}) {
  return chooseOnlineBikeOverlay(lng: lng, lat: lat, zoom: zoom).kind !=
      OnlineBikeOverlayKind.none;
}

bool _isPmtilesOverlay(Object data) {
  if (data is! String) return false;
  final u = data.toLowerCase();
  return u.contains('.pmtiles') || u.startsWith('pmtiles://');
}

class _OverlayResolveMemo {
  static Future<Object?>? inflight;
  static Object? last;
  static double? lng;
  static double? lat;
  static double? zoom;
}

bool _sameOverlayQuery(double lng, double lat, double zoom) {
  final a = _OverlayResolveMemo.lng;
  final b = _OverlayResolveMemo.lat;
  final z = _OverlayResolveMemo.zoom;
  if (a == null || b == null || z == null) return false;
  final sameBand = (z >= kBikeWaysMinZoom) == (zoom >= kBikeWaysMinZoom);
  return sameBand && (a - lng).abs() < 0.08 && (b - lat).abs() < 0.08;
}

/// Warm CDN/pack lookup before the map style finishes attaching layers.
Future<Object?> prefetchBikeOverlay({
  required double lng,
  required double lat,
  double zoom = 12,
}) =>
    resolveBikeOverlayData(lng: lng, lat: lat, zoom: zoom);

Future<Object?> resolveBikeOverlayData({
  required double lng,
  required double lat,
  double zoom = 12,
}) {
  if (_sameOverlayQuery(lng, lat, zoom) && _OverlayResolveMemo.last != null) {
    return Future<Object?>.value(_OverlayResolveMemo.last);
  }
  final inflight = _OverlayResolveMemo.inflight;
  if (_sameOverlayQuery(lng, lat, zoom) && inflight != null) {
    return inflight;
  }
  final future = _resolveBikeOverlayDataUncached(
    lng: lng,
    lat: lat,
    zoom: zoom,
  );
  _OverlayResolveMemo.inflight = future;
  _OverlayResolveMemo.lng = lng;
  _OverlayResolveMemo.lat = lat;
  _OverlayResolveMemo.zoom = zoom;
  return future.then((value) {
    if (identical(_OverlayResolveMemo.inflight, future)) {
      _OverlayResolveMemo.inflight = null;
      if (value != null) _OverlayResolveMemo.last = value;
    }
    return value;
  });
}

Future<Object?> _resolveBikeOverlayDataUncached({
  required double lng,
  required double lat,
  double zoom = 12,
}) async {
  final region = overlayRegionForPoint(lng, lat);
  if (region != null) {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final gpsLocal = File(
        p.join(docs.path, 'regions', region.id, kBikeOverlayGeojsonName),
      );
      if (await gpsLocal.exists() && await gpsLocal.length() > 20) {
        return Uri.file(gpsLocal.absolute.path).toString();
      }
    } catch (_) {}
  }

  final choice = chooseOnlineBikeOverlay(lng: lng, lat: lat, zoom: zoom);
  final packDir = await OfflineTilesStore.instance.ensureTilesPath(
    bundledFallback: false,
  );
  if (packDir != null) {
    final local = File(p.join(packDir, kBikeOverlayGeojsonName));
    if (await local.exists() && await local.length() > 20) {
      return Uri.file(local.absolute.path).toString();
    }
  }
  if (choice.kind == OnlineBikeOverlayKind.ways) {
    return choice.url;
  }

  if (region != null) {
    final urls = [
      Uri.parse(
        '${AppConfig.apiBaseUrl}/api/offline/packs/${region.id}/$kBikeOverlayGeojsonName',
      ),
      Uri.parse(
        '${AppConfig.apiBaseUrl}/offline/${region.id}/$kBikeOverlayGeojsonName',
      ),
    ];
    for (final url in urls) {
      try {
        final res = await http.get(url).timeout(const Duration(seconds: 45));
        if (res.statusCode == 200 && res.bodyBytes.length > 20) {
          Directory? destDir;
          if (packDir != null && p.basename(packDir) == region.id) {
            destDir = Directory(packDir);
          } else {
            try {
              final docs = await getApplicationDocumentsDirectory();
              final gpsDir = Directory(
                p.join(docs.path, 'regions', region.id),
              );
              if (await gpsDir.exists()) destDir = gpsDir;
            } catch (_) {}
          }
          if (destDir != null) {
            final dest = File(p.join(destDir.path, kBikeOverlayGeojsonName));
            await dest.writeAsBytes(res.bodyBytes);
            return Uri.file(dest.absolute.path).toString();
          }
          return jsonDecode(utf8.decode(res.bodyBytes));
        }
      } catch (_) {}
    }
  }
  if (choice.kind == OnlineBikeOverlayKind.mesh) {
    return choice.url;
  }

  // Sample overlay is Rhein-Neckar geometry — never show it in Wien/Hamburg.
  if (pointInRheinNeckar(lng, lat) && zoom >= kBikeWaysMinZoom) {
    try {
      final raw = await rootBundle.loadString(kBikeOverlaySampleAsset);
      if (raw.trim().isEmpty || raw.contains('"features":[]')) {
        return jsonDecode(raw);
      }
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }
  return null;
}

/// OpenFreeMap / OSM planet — has `transportation` with path/track/cycleway.
/// Catalog `protomaps` (dach-z11) must NOT be listed: it only has `roads`,
/// paths are absent at z11, and a false "live" success sets `sGradeOnly` so
/// the CDN bike-overlay (road/urban/gravel/paths) never attaches — riders
/// then see only Autobahn from the basemap.
const kOsmLiveSourceCandidates = <String>['openmaptiles'];
const kOsmLiveCyclewayLayerId = 'osm-live-cycleway';
const kOsmLivePathLayerId = 'osm-live-path';
const kOsmLiveTrackLayerId = 'osm-live-track';

const kOsmLiveLayerClass = <String, BikeOverlayClass>{
  kOsmLiveCyclewayLayerId: BikeOverlayClass.road,
  kOsmLivePathLayerId: BikeOverlayClass.mtbUnrated,
  kOsmLiveTrackLayerId: BikeOverlayClass.gravel,
  kOsmSGradeLayerId: BikeOverlayClass.mtb,
};

/// Which basemap source can feed live path/cycleway layers (not catalog PMTiles).
String? liveOsmNetworkSourceId(Iterable<String> sourceIds) {
  final ids = sourceIds.toSet();
  for (final candidate in kOsmLiveSourceCandidates) {
    if (ids.contains(candidate)) return candidate;
  }
  return null;
}

/// Catalog z11 styles only have `protomaps`. Add OpenFreeMap so live ways exist
/// outside DACH/NL/BE/IT country tiles.
Future<bool> ensureLiveOsmNetworkSource(MapLibreMapController c) async {
  try {
    final ids = [for (final raw in await c.getSourceIds()) raw.toString()];
    if (liveOsmNetworkSourceId(ids) != null) return true;
  } catch (_) {}
  try {
    await c.addSource(
      kOsmLiveSourceCandidates.first,
      const VectorSourceProperties(
        url: kOpenFreeMapPlanetSourceUrl,
        attribution: '© OpenStreetMap, OpenFreeMap',
      ),
    );
    return true;
  } catch (_) {
    return false;
  }
}

/// OpenFreeMap planet tiles — OSM path/track/cycleway for DACH + FR (and world).
/// S-grade is live Overpass (`mtb:scale`) — OpenMapTiles has no scale tag.
Future<bool> attachLiveOsmNetworkLayers(MapLibreMapController c) async {
  String? sourceId;
  try {
    final ids = [for (final raw in await c.getSourceIds()) raw.toString()];
    sourceId = liveOsmNetworkSourceId(ids);
  } catch (_) {}
  if (sourceId == null) return false;

  Future<void> addLive({
    required String layerId,
    required String color,
    required double width,
    required List<dynamic> filter,
    required double minzoom,
  }) async {
    try {
      final ids = [for (final raw in await c.getLayerIds()) raw.toString()];
      if (ids.contains(layerId)) return;
    } catch (_) {}
    try {
      await c.addLineLayer(
        sourceId!,
        layerId,
        LineLayerProperties(
          lineColor: color,
          lineWidth: BrowseMapPaint.liveZoomWidth(width),
          lineOpacity: BrowseMapPaint.lineOpacity,
          lineCap: 'round',
          lineJoin: 'round',
          visibility: 'visible',
        ),
        sourceLayer: 'transportation',
        minzoom: minzoom,
        filter: filter,
        enableInteraction: false,
      );
    } catch (_) {}
  }

  await addLive(
    layerId: kOsmLiveCyclewayLayerId,
    color: BikeOverlayColors.road,
    width: BrowseMapPaint.liveCyclewayWidth,
    minzoom: BrowseMapPaint.liveCyclewayMinZoom,
    filter: [
      'all',
      [
        'match',
        ['geometry-type'],
        ['LineString', 'MultiLineString'],
        true,
        false,
      ],
      [
        'any',
        [
          '==',
          ['get', 'subclass'],
          'cycleway',
        ],
        [
          '==',
          ['get', 'class'],
          'cycleway',
        ],
      ],
    ],
  );
  await addLive(
    layerId: kOsmLivePathLayerId,
    color: BikeOverlayColors.unrated,
    width: BrowseMapPaint.livePathWidth,
    minzoom: BrowseMapPaint.livePathMinZoom,
    filter: [
      'all',
      [
        'match',
        ['geometry-type'],
        ['LineString', 'MultiLineString'],
        true,
        false,
      ],
      [
        '==',
        ['get', 'class'],
        'path',
      ],
      [
        '!=',
        ['get', 'subclass'],
        'cycleway',
      ],
    ],
  );
  await addLive(
    layerId: kOsmLiveTrackLayerId,
    color: BikeOverlayColors.gravel,
    width: BrowseMapPaint.liveTrackWidth,
    minzoom: BrowseMapPaint.liveTrackMinZoom,
    filter: [
      'all',
      [
        'match',
        ['geometry-type'],
        ['LineString', 'MultiLineString'],
        true,
        false,
      ],
      [
        '==',
        ['get', 'class'],
        'track',
      ],
    ],
  );
  return true;
}

Future<void> attachSGradeLiveLayer(MapLibreMapController c) async {
  var hasSource = false;
  try {
    hasSource = (await c.getSourceIds()).contains(kOsmSGradeSourceId);
  } catch (_) {}
  if (!hasSource) {
    try {
      await c.addGeoJsonSource(
        kOsmSGradeSourceId,
        const {'type': 'FeatureCollection', 'features': <dynamic>[]},
      );
    } catch (_) {}
  }
  var hasLayer = false;
  try {
    hasLayer = (await c.getLayerIds()).contains(kOsmSGradeLayerId);
  } catch (_) {}
  if (hasLayer) return;
  try {
    await c.addLineLayer(
      kOsmSGradeSourceId,
      kOsmSGradeLayerId,
      LineLayerProperties(
        lineColor: [
          'match',
          ['get', 'mtb_scale'],
          'S0',
          BikeOverlayColors.s0,
          'S1',
          BikeOverlayColors.s1,
          'S2',
          BikeOverlayColors.s2,
          'S3',
          '#FB8C00',
          'S3+',
          BikeOverlayColors.s3,
          BikeOverlayColors.unrated,
        ],
        lineWidth: 2.6,
        lineOpacity: 0.92,
        lineCap: 'round',
        lineJoin: 'round',
        visibility: 'visible',
      ),
      minzoom: kOsmSGradeMinZoom,
    );
  } catch (_) {}
}

Future<void> setSGradeLiveData(
  MapLibreMapController c,
  Map<String, dynamic> geojson,
) async {
  try {
    await c.setGeoJsonSource(kOsmSGradeSourceId, geojson);
  } catch (_) {
    try {
      await attachSGradeLiveLayer(c);
      await c.setGeoJsonSource(kOsmSGradeSourceId, geojson);
    } catch (_) {}
  }
}

Future<void> detachBikeOverlayLayers(MapLibreMapController c) async {
  for (final id in kBikeOverlayLayerIds.values) {
    try {
      await c.removeLayer(id);
    } catch (_) {}
  }
  try {
    await c.removeSource(kBikeOverlaySourceId);
  } catch (_) {}
}

Future<void> attachBikeOverlayLayers(
  MapLibreMapController c, {
  required Object data,
  required BikeOverlayFamily family,
  required bool visible,
  required Set<BikeOverlayClass> extraOn,
  bool sGradeOnly = false,
}) async {
  final pmtiles = _isPmtilesOverlay(data);
  try {
    if (pmtiles) {
      final raw = data.toString();
      await c.addSource(
        kBikeOverlaySourceId,
        VectorSourceProperties(
          url: raw.startsWith('pmtiles://') ? raw : 'pmtiles://$raw',
          attribution: '© OpenStreetMap',
        ),
      );
    } else {
      await c.addSource(
        kBikeOverlaySourceId,
        GeojsonSourceProperties(
          data: data,
          attribution: '© OpenStreetMap',
        ),
      );
    }
  } catch (_) {
    // Source already present after a partial attach.
  }

  Future<void> addClassLayer({
    required String layerId,
    required String classId,
    required dynamic lineColor,
    required double lineWidth,
    List<double>? dash,
    double minzoom = 11,
  }) async {
    try {
      await c.addLineLayer(
        kBikeOverlaySourceId,
        layerId,
        LineLayerProperties(
          lineColor: lineColor,
          lineWidth: BrowseMapPaint.zoomWidth(lineWidth),
          lineOpacity: BrowseMapPaint.lineOpacity,
          lineCap: 'round',
          lineJoin: 'round',
          lineDasharray: dash,
          visibility: 'visible',
        ),
        filter: [
          '==',
          ['get', 'bike_class'],
          classId,
        ],
        sourceLayer: pmtiles ? 'bike' : null,
        minzoom: classId == 'road' || classId == 'mtb' ? 5 : minzoom,
      );
    } catch (_) {}
  }

  await addClassLayer(
    layerId: kBikeOverlayLayerIds[BikeOverlayClass.mtb]!,
    classId: 'mtb',
    lineColor: [
      'match',
      ['get', 'mtb_scale'],
      'S0',
      BikeOverlayColors.s0,
      'S1',
      BikeOverlayColors.s1,
      'S2',
      BikeOverlayColors.s2,
      'S3',
      BikeOverlayColors.s3,
      'S3+',
      BikeOverlayColors.s3,
      BikeOverlayColors.unrated,
    ],
    lineWidth: BrowseMapPaint.mtbWidth,
    minzoom: BrowseMapPaint.mtbMinZoom,
  );
  if (!sGradeOnly) {
    await addClassLayer(
      layerId: kBikeOverlayLayerIds[BikeOverlayClass.mtbUnrated]!,
      classId: 'mtb_unrated',
      lineColor: bikeOverlaySurfaceLineColor(BikeOverlayColors.unrated),
      lineWidth: BrowseMapPaint.trailWidth,
      dash: const [2, 1.4],
      minzoom: BrowseMapPaint.unratedMinZoom,
    );
    await addClassLayer(
      layerId: kBikeOverlayLayerIds[BikeOverlayClass.gravel]!,
      classId: 'gravel',
      lineColor: bikeOverlaySurfaceLineColor(BikeOverlayColors.gravel),
      lineWidth: BrowseMapPaint.gravelWidth,
      minzoom: BrowseMapPaint.gravelMinZoom,
    );
    await addClassLayer(
      layerId: kBikeOverlayLayerIds[BikeOverlayClass.road]!,
      classId: 'road',
      lineColor: bikeOverlaySurfaceLineColor(BikeOverlayColors.road),
      lineWidth: BrowseMapPaint.wayWidth,
      minzoom: BrowseMapPaint.roadMinZoom,
    );
    await addClassLayer(
      layerId: kBikeOverlayLayerIds[BikeOverlayClass.urban]!,
      classId: 'urban',
      lineColor: bikeOverlaySurfaceLineColor(BikeOverlayColors.urban),
      lineWidth: BrowseMapPaint.urbanWidth,
      minzoom: BrowseMapPaint.urbanMinZoom,
    );
  }

  await applyBikeOverlayVisibility(
    c,
    family: family,
    visible: visible,
    extraOn: extraOn,
  );
}

Future<void> applyBikeOverlayVisibility(
  MapLibreMapController c, {
  required BikeOverlayFamily family,
  required bool visible,
  required Set<BikeOverlayClass> extraOn,
}) async {
  final on = overlayClassesShown(overlayOn: visible, extraOn: extraOn);
  for (final entry in kBikeOverlayLayerIds.entries) {
    final layerId = entry.value;
    try {
      await c.setLayerVisibility(layerId, on.contains(entry.key));
      if (on.contains(entry.key)) {
        await c.setLayerProperties(
          layerId,
          const LineLayerProperties(
            lineOpacity: BrowseMapPaint.visibilityOpacity,
          ),
        );
      }
    } catch (_) {}
  }
  for (final entry in kOsmLiveLayerClass.entries) {
    try {
      await c.setLayerVisibility(entry.key, on.contains(entry.value));
    } catch (_) {}
  }
}

BikeOverlayFamily overlayFamilyFromActiveBike(List<Bike> bikes) {
  final active = bikes.cast<Bike?>().firstWhere(
    (b) => b?.isActive == true,
    orElse: () => bikes.isEmpty ? null : bikes.first,
  );
  return overlayFamilyForBike(active?.category ?? BikeCategory.road);
}

Future<void> downloadBikeOverlayIntoPack(Directory regionDir, String regionId) async {
  final dest = File(p.join(regionDir.path, kBikeOverlayGeojsonName));
  if (await dest.exists() && await dest.length() > 20) return;
  final urls = [
    Uri.parse(AppConfig.offlinePackObjectUrl(regionId, kBikeOverlayGeojsonName)),
    Uri.parse(
      '${AppConfig.apiBaseUrl}/api/offline/packs/$regionId/$kBikeOverlayGeojsonName',
    ),
    Uri.parse(
      '${AppConfig.apiBaseUrl}/offline/$regionId/$kBikeOverlayGeojsonName',
    ),
  ];
  for (final url in urls) {
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 120));
      if (res.statusCode == 200 && res.bodyBytes.length > 20) {
        await dest.writeAsBytes(res.bodyBytes);
        return;
      }
    } catch (_) {}
  }
}
