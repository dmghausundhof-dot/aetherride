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
import 'offline_tiles.dart';
import 'overlay_regions.dart';
import 'sgrade_live.dart';

const kBikeOverlaySourceId = 'bike-overlay';
const kBikeOverlayGeojsonName = 'bike-overlay.geojson';
const kBikeOverlaySampleAsset = 'assets/routing/bike-overlay-sample.geojson';

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

Future<Object?> resolveBikeOverlayData({
  required double lng,
  required double lat,
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

  final packDir = await OfflineTilesStore.instance.ensureTilesPath(
    bundledFallback: false,
  );
  if (packDir != null) {
    final local = File(p.join(packDir, kBikeOverlayGeojsonName));
    if (await local.exists() && await local.length() > 20) {
      return Uri.file(local.absolute.path).toString();
    }
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

  // Sample overlay is Rhein-Neckar geometry — never show it in Wien/Hamburg.
  if (pointInRheinNeckar(lng, lat)) {
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

const kOsmLiveSourceCandidates = <String>['openmaptiles', 'protomaps'];
const kOsmLiveCyclewayLayerId = 'osm-live-cycleway';
const kOsmLivePathLayerId = 'osm-live-path';
const kOsmLiveTrackLayerId = 'osm-live-track';

const kOsmLiveLayerClass = <String, BikeOverlayClass>{
  kOsmLiveCyclewayLayerId: BikeOverlayClass.road,
  kOsmLivePathLayerId: BikeOverlayClass.mtbUnrated,
  kOsmLiveTrackLayerId: BikeOverlayClass.gravel,
  kOsmSGradeLayerId: BikeOverlayClass.mtb,
};

/// OpenFreeMap planet tiles — OSM path/track/cycleway for DACH + FR (and world).
/// S-grade is live Overpass (`mtb:scale`) — OpenMapTiles has no scale tag.
Future<bool> attachLiveOsmNetworkLayers(MapLibreMapController c) async {
  String? sourceId;
  try {
    final ids = await c.getSourceIds();
    for (final candidate in kOsmLiveSourceCandidates) {
      if (ids.contains(candidate)) {
        sourceId = candidate;
        break;
      }
    }
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
      await c.addLineLayer(
        sourceId!,
        layerId,
        LineLayerProperties(
          lineColor: color,
          lineWidth: width,
          lineOpacity: 0.88,
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
    width: 2.2,
    minzoom: 11,
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
    width: 1.6,
    minzoom: 12,
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
    width: 2.0,
    minzoom: 12,
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

Future<void> attachBikeOverlayLayers(
  MapLibreMapController c, {
  required Object data,
  required BikeOverlayFamily family,
  required bool visible,
  required Set<BikeOverlayClass> extraOn,
  bool sGradeOnly = false,
}) async {
  try {
    await c.addSource(
      kBikeOverlaySourceId,
      GeojsonSourceProperties(
        data: data,
        attribution: '© OpenStreetMap',
      ),
    );
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
          lineWidth: lineWidth,
          lineOpacity: 0.88,
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
        minzoom: minzoom,
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
    lineWidth: 2.4,
    minzoom: 11,
  );
  if (!sGradeOnly) {
    await addClassLayer(
      layerId: kBikeOverlayLayerIds[BikeOverlayClass.mtbUnrated]!,
      classId: 'mtb_unrated',
      lineColor: BikeOverlayColors.unrated,
      lineWidth: 1.6,
      dash: const [2, 1.4],
      minzoom: 12,
    );
    await addClassLayer(
      layerId: kBikeOverlayLayerIds[BikeOverlayClass.gravel]!,
      classId: 'gravel',
      lineColor: BikeOverlayColors.gravel,
      lineWidth: 2.0,
      minzoom: 12,
    );
    await addClassLayer(
      layerId: kBikeOverlayLayerIds[BikeOverlayClass.road]!,
      classId: 'road',
      lineColor: BikeOverlayColors.road,
      lineWidth: 2.2,
      minzoom: 11,
    );
    await addClassLayer(
      layerId: kBikeOverlayLayerIds[BikeOverlayClass.urban]!,
      classId: 'urban',
      lineColor: BikeOverlayColors.urban,
      lineWidth: 1.8,
      minzoom: 12,
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
          const LineLayerProperties(lineOpacity: 0.88),
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
