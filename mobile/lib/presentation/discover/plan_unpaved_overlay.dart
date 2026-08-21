import 'package:maplibre_gl/maplibre_gl.dart';

import 'discover_map_line_style.dart';

const kPlanRibbonSourceId = 'flowline-plan-ribbon';
const kPlanPavedLayerId = 'flowline-plan-paved-line';
const kPlanGravelLayerId = 'flowline-plan-gravel-line';
const kPlanTrailLayerId = 'flowline-plan-trail-line';
const kPlanSteepLayerId = 'flowline-plan-steep-line';
const kPlanPackOutLayerId = 'flowline-plan-pack-out-line';
const kPlanPackOutKind = 'pack-out';

/// Legacy id from the single unpaved hatch — remove if still attached.
const kPlanUnpavedSourceId = 'flowline-plan-unpaved';
const kPlanUnpavedLayerId = 'flowline-plan-unpaved-line';

const _pavedPaint = LineLayerProperties(
  lineColor: DiscoverMapLineStyle.planPaved,
  lineWidth: DiscoverMapLineStyle.planSurfaceWidth,
  lineOpacity: 0.94,
  lineCap: 'round',
  lineJoin: 'round',
);

const _gravelPaint = LineLayerProperties(
  lineColor: DiscoverMapLineStyle.planGravel,
  lineWidth: DiscoverMapLineStyle.planSurfaceWidth,
  lineOpacity: 0.94,
  lineCap: 'round',
  lineJoin: 'round',
);

const _trailPaint = LineLayerProperties(
  lineColor: DiscoverMapLineStyle.planTrail,
  lineWidth: DiscoverMapLineStyle.planSurfaceWidth,
  lineOpacity: 0.94,
  lineCap: 'round',
  lineJoin: 'round',
);

const _steepPaint = LineLayerProperties(
  lineColor: DiscoverMapLineStyle.planSteep,
  lineWidth: DiscoverMapLineStyle.planSteepWidth,
  lineOpacity: 0.94,
  lineCap: 'round',
  lineJoin: 'round',
);

const _packOutPaint = LineLayerProperties(
  lineColor: DiscoverMapLineStyle.packOutside,
  lineWidth: DiscoverMapLineStyle.packOutsideWidth,
  lineOpacity: 0.92,
  lineCap: 'butt',
  lineJoin: 'round',
  lineDasharray: DiscoverMapLineStyle.packOutsideDash,
);

/// Surface + steep tint on the live plan ribbon.
///
/// Annotation [LineOptions] in maplibre_gl 0.21 has no dash and a drag
/// translates the whole polyline. GeoJSON layers stay visual-only
/// (`enableInteraction: false`) so the orange core still receives grab / tap.
Future<void> syncPlanRibbonOverlay(
  MapLibreMapController c, {
  required List<({String kind, List<List<double>> coords})> slices,
}) async {
  try {
    final sources = [for (final id in await c.getSourceIds()) id.toString()];
    if (sources.contains(kPlanUnpavedSourceId)) {
      try {
        await c.removeLayer(kPlanUnpavedLayerId);
      } catch (_) {}
      try {
        await c.removeSource(kPlanUnpavedSourceId);
      } catch (_) {}
    }
    if (!sources.contains(kPlanRibbonSourceId)) {
      await c.addGeoJsonSource(kPlanRibbonSourceId, const {
        'type': 'FeatureCollection',
        'features': <dynamic>[],
      });
    }
  } catch (_) {}
  final features = <Map<String, dynamic>>[
    for (final slice in slices)
      if (slice.coords.length >= 2)
        {
          'type': 'Feature',
          'geometry': {'type': 'LineString', 'coordinates': slice.coords},
          'properties': {'kind': slice.kind},
        },
  ];
  try {
    await c.setGeoJsonSource(kPlanRibbonSourceId, {
      'type': 'FeatureCollection',
      'features': features,
    });
  } catch (_) {}
  await raisePlanRibbonLayers(c);
}

/// Back-compat: gravel/trail hatch only.
Future<void> syncPlanUnpavedOverlay(
  MapLibreMapController c, {
  required List<List<List<double>>> slicesLngLat,
}) {
  return syncPlanRibbonOverlay(
    c,
    slices: [
      for (final coords in slicesLngLat) (kind: 'trail', coords: coords),
    ],
  );
}

Future<void> raisePlanRibbonLayers(MapLibreMapController c) async {
  Future<void> upsert(String layerId, LineLayerProperties paint, String kind) async {
    try {
      final layers = [for (final id in await c.getLayerIds()) id.toString()];
      if (layers.contains(layerId)) {
        await c.removeLayer(layerId);
      }
    } catch (_) {}
    try {
      await c.addLineLayer(
        kPlanRibbonSourceId,
        layerId,
        paint,
        filter: ['==', 'kind', kind],
        enableInteraction: false,
      );
    } catch (_) {}
  }

  await upsert(kPlanPavedLayerId, _pavedPaint, 'asphalt');
  await upsert(kPlanGravelLayerId, _gravelPaint, 'gravel');
  await upsert(kPlanTrailLayerId, _trailPaint, 'trail');
  await upsert(kPlanSteepLayerId, _steepPaint, 'steep');
  await upsert(kPlanPackOutLayerId, _packOutPaint, kPlanPackOutKind);
}

Future<void> raisePlanUnpavedLayer(MapLibreMapController c) =>
    raisePlanRibbonLayers(c);

Future<void> dimPlanRibbonOverlay(
  MapLibreMapController c, {
  required double opacity,
}) async {
  for (final id in [
    kPlanPavedLayerId,
    kPlanGravelLayerId,
    kPlanTrailLayerId,
    kPlanSteepLayerId,
    kPlanPackOutLayerId,
  ]) {
    try {
      await c.setLayerProperties(
        id,
        LineLayerProperties(lineOpacity: opacity),
      );
    } catch (_) {}
  }
}
