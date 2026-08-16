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
const kBikeOverlayPmtilesName = 'bike-overlay.pmtiles';
const kBikeOverlaySampleAsset = 'assets/routing/bike-overlay-sample.geojson';

/// Past the z11 atlas: pack ways replace the signed cycle mesh.
const kBikeWaysMinZoom = 12.0;

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

Future<Object?> resolveBikeOverlayData({
  required double lng,
  required double lat,
  double zoom = 12,
}) async {
  final choice = chooseOnlineBikeOverlay(lng: lng, lat: lat, zoom: zoom);
  if (choice.kind == OnlineBikeOverlayKind.ways) {
    final packDir = await OfflineTilesStore.instance.ensureTilesPath();
    if (packDir != null) {
      final local = File(p.join(packDir, kBikeOverlayGeojsonName));
      if (await local.exists() && await local.length() > 20) {
        return Uri.file(local.absolute.path).toString();
      }
    }
    return choice.url;
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
