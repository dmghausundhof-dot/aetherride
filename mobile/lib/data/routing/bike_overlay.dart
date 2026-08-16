import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:path/path.dart' as p;

import '../../core/config.dart';
import '../../domain/bike.dart';
import '../../domain/routing/bike_overlay_class.dart';
import 'map_style_url.dart';
import 'offline_tiles.dart';
import 'overlay_regions.dart';

const kBikeOverlaySourceId = 'bike-overlay';
const kBikeOverlayGeojsonName = 'bike-overlay.geojson';
const kBikeOverlaySampleAsset = 'assets/routing/bike-overlay-sample.geojson';

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
};

const kBikeOverlayLayerIds = <BikeOverlayClass, String>{
  BikeOverlayClass.mtb: 'bike-overlay-mtb',
  BikeOverlayClass.mtbUnrated: 'bike-overlay-mtb-unrated',
  BikeOverlayClass.gravel: 'bike-overlay-gravel',
  BikeOverlayClass.road: 'bike-overlay-road',
  BikeOverlayClass.urban: 'bike-overlay-urban',
};

/// RN bbox from `data/routing/regions/rhein-neckar.json`.
const rheinNeckarBbox = [8.2, 49.2, 9.0, 49.6];

bool pointInRheinNeckar(double lng, double lat) =>
    lng >= rheinNeckarBbox[0] &&
    lat >= rheinNeckarBbox[1] &&
    lng <= rheinNeckarBbox[2] &&
    lat <= rheinNeckarBbox[3];

/// DACH online Blatt — same bbox as dach-z11.
bool pointInOnlineCycleMesh(double lng, double lat) =>
    lng >= 5.8 && lng <= 17.25 && lat >= 45.75 && lat <= 55.15;

bool _isPmtilesOverlay(Object data) {
  if (data is! String) return false;
  final u = data.toLowerCase();
  return u.contains('.pmtiles') || u.startsWith('pmtiles://');
}

Future<Object?> resolveBikeOverlayData({
  required double lng,
  required double lat,
}) async {
  final packDir = await OfflineTilesStore.instance.ensureTilesPath();
  if (packDir != null) {
    final local = File(p.join(packDir, kBikeOverlayGeojsonName));
    if (await local.exists() && await local.length() > 20) {
      return Uri.file(local.absolute.path).toString();
    }
  }

  final region = overlayRegionForPoint(lng, lat);
  if (region != null && kDetailBikeOverlayPacks.contains(region.id)) {
    final urls = [
      Uri.parse(AppConfig.offlinePackObjectUrl(region.id, kBikeOverlayGeojsonName)),
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
          if (packDir != null) {
            final dest = File(p.join(packDir, kBikeOverlayGeojsonName));
            await dest.writeAsBytes(res.bodyBytes);
            return Uri.file(dest.absolute.path).toString();
          }
          return jsonDecode(utf8.decode(res.bodyBytes));
        }
      } catch (_) {}
    }
  }

  if (pointInOnlineCycleMesh(lng, lat)) {
    return kOnlineCycleMeshPmtilesUrl;
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

Future<void> attachBikeOverlayLayers(
  MapLibreMapController c, {
  required Object data,
  required BikeOverlayFamily family,
  required bool visible,
  required Set<BikeOverlayClass> extraOn,
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
  }) async {
    try {
      await c.addLineLayer(
        kBikeOverlaySourceId,
        layerId,
        LineLayerProperties(
          lineColor: lineColor,
          lineWidth: lineWidth,
          lineOpacity: 0.85,
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
        minzoom: classId == 'road' || classId == 'mtb' ? 5 : 9,
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
      BikeOverlayColors.unrated,
    ],
    lineWidth: 2.4,
  );
  await addClassLayer(
    layerId: kBikeOverlayLayerIds[BikeOverlayClass.mtbUnrated]!,
    classId: 'mtb_unrated',
    lineColor: BikeOverlayColors.unrated,
    lineWidth: 1.6,
    dash: const [2, 1.4],
  );
  await addClassLayer(
    layerId: kBikeOverlayLayerIds[BikeOverlayClass.gravel]!,
    classId: 'gravel',
    lineColor: BikeOverlayColors.gravel,
    lineWidth: 2.0,
  );
  await addClassLayer(
    layerId: kBikeOverlayLayerIds[BikeOverlayClass.road]!,
    classId: 'road',
    lineColor: BikeOverlayColors.road,
    lineWidth: 2.2,
  );
  await addClassLayer(
    layerId: kBikeOverlayLayerIds[BikeOverlayClass.urban]!,
    classId: 'urban',
    lineColor: BikeOverlayColors.urban,
    lineWidth: 1.8,
  );

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
  final on = {
    ...overlayClassesForFamily(family),
    ...extraOn,
  };
  for (final entry in kBikeOverlayLayerIds.entries) {
    final layerId = entry.value;
    try {
      if (!visible) {
        await c.setLayerVisibility(layerId, false);
        continue;
      }
      await c.setLayerVisibility(layerId, true);
      final active = on.contains(entry.key);
      await c.setLayerProperties(
        layerId,
        LineLayerProperties(lineOpacity: active ? 0.88 : 0.16),
      );
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
