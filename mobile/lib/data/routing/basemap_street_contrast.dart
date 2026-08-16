import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Stadia Outdoors / Liberty paint residential white-on-beige; Alidade uses
/// ~86% gray on 95% land. Both look like “only Autobahn” on the HUD.
const kNavStreetLineColor = '#6E6A66';
const kNavStreetCasingColor = '#4A4744';

/// Positron paints tracks/paths ~88% gray; keep that, only darken streets.
const kBasemapTrackKeepColor = '#E0E0E0';

const _streetNeedles = <String>[
  'highway_minor',
  'highway-minor',
  'road_minor',
  'road-minor',
  'highway_service',
  'road_service',
  'tunnel_minor',
  'tunnel-minor',
  'bridge_street',
  'tunnel_street',
  'road_street',
];

/// Always try these even if [MapLibreMapController.getLayerIds] is empty.
/// Paths/tracks stay pale — boosting them paints a gray cadastral grid.
const kKnownStreetContrastLayerIds = <String>[
  'highway_minor',
  'highway-minor',
  'highway-minor-casing',
  'road_minor',
  'road_minor_casing',
  'tunnel_minor',
  'tunnel-minor',
  'bridge_street',
];

bool isBasemapStreetContrastLayer(String id) {
  final u = id.toLowerCase();
  if (u.contains('motorway') ||
      u.contains('trunk') ||
      u.contains('overlay') ||
      u.contains('bike-') ||
      u.contains('route') ||
      u.contains('gps') ||
      u.contains('path')) {
    return false;
  }
  return _streetNeedles.any(u.contains);
}

dynamic _streetContrastColor({required bool casing}) => [
      'match',
      ['get', 'class'],
      'track',
      kBasemapTrackKeepColor,
      'path',
      kBasemapTrackKeepColor,
      casing ? kNavStreetCasingColor : kNavStreetLineColor,
    ];

Future<void> _paintStreetLayer(MapLibreMapController c, String id) async {
  final casing = id.toLowerCase().contains('casing');
  await c.setLayerProperties(
    id,
    LineLayerProperties(
      lineColor: _streetContrastColor(casing: casing),
    ),
  );
}

/// Gray styles only. Bright already has parks/water — boosting it paints
/// the city gray again. Never include highway_path / track (grid artefact).
bool styleNeedsGrayStreetBoost(String styleUrl) {
  final u = styleUrl.toLowerCase();
  return u.contains('positron') ||
      u.contains('alidade_smooth') ||
      u.contains('alidade-smooth');
}

const kNatureParkFill = '#6FAF4A';
const kNatureWoodFill = '#4E8A38';
const kNatureWaterFill = '#3D9EC4';
const kNatureParkOpacity = 0.72;
const kNatureWoodOpacity = 0.78;
const kNatureWaterOpacity = 0.82;

/// OSM Bright / Stadia — try even if getLayerIds is empty.
const kKnownNatureFillLayerIds = <String>[
  'landcover_park',
  'landcover-park',
  'landuse_park',
  'landuse-park',
  'park',
  'landcover_grass',
  'landcover-grass',
  'landcover_wood',
  'landcover-wood',
  'landuse_wood',
  'landuse-wood',
  'landcover_forest',
  'water',
  'water-fill',
  'water_fill',
];

bool isNatureParkFillLayer(String id) {
  final u = id.toLowerCase();
  if (u.contains('label') ||
      u.contains('name') ||
      u.contains('highway') ||
      u.contains('road') ||
      u.contains('path') ||
      u.contains('overlay') ||
      u.contains('residential')) {
    return false;
  }
  return u.contains('park') ||
      u.contains('grass') ||
      u.contains('garden') ||
      u.contains('pitch') ||
      u.contains('cemetery') ||
      u.contains('recreation');
}

bool isNatureWoodFillLayer(String id) {
  final u = id.toLowerCase();
  if (u.contains('label') || u.contains('name') || u.contains('overlay')) {
    return false;
  }
  return u.contains('wood') || u.contains('forest');
}

bool isNatureWaterFillLayer(String id) {
  final u = id.toLowerCase();
  if (u.contains('label') ||
      u.contains('name') ||
      u.contains('way') ||
      u.contains('overlay')) {
    return false;
  }
  return u.contains('water');
}

/// Parks/Wald/Wasser kräftiger — nicht Straßen, nicht path/track.
Future<void> warmBasemapNatureFills(MapLibreMapController c) async {
  final ids = <String>{...kKnownNatureFillLayerIds};
  try {
    for (final raw in await c.getLayerIds()) {
      ids.add(raw.toString());
    }
  } catch (_) {}
  var n = 0;
  for (final id in ids) {
    String? color;
    double? opacity;
    if (isNatureParkFillLayer(id)) {
      color = kNatureParkFill;
      opacity = kNatureParkOpacity;
    } else if (isNatureWoodFillLayer(id)) {
      color = kNatureWoodFill;
      opacity = kNatureWoodOpacity;
    } else if (isNatureWaterFillLayer(id)) {
      color = kNatureWaterFill;
      opacity = kNatureWaterOpacity;
    }
    if (color == null) continue;
    try {
      await c.setLayerProperties(
        id,
        FillLayerProperties(fillColor: color, fillOpacity: opacity),
      );
      n++;
    } catch (_) {}
  }
  debugPrint('nature fills: painted $n layers');
}

/// Darken residential streets after the remote style loads — not OSM tracks.
Future<void> boostBasemapStreetContrast(MapLibreMapController c) async {
  final ids = <String>{...kKnownStreetContrastLayerIds};
  try {
    for (final raw in await c.getLayerIds()) {
      ids.add(raw.toString());
    }
  } catch (_) {}
  var n = 0;
  for (final id in ids) {
    if (!isBasemapStreetContrastLayer(id)) continue;
    try {
      await _paintStreetLayer(c, id);
      n++;
    } catch (_) {}
  }
  debugPrint('street contrast: painted $n layers');
}
