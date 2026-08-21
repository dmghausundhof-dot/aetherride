import 'package:maplibre_gl/maplibre_gl.dart';

import 'basemap_street_contrast.dart';
import 'map_style_url.dart';

/// Explore-Blatt: sage paper, not OSM-Bright parks/water.
///
/// [warmBasemapNatureFills] paints Bright greens onto z11 layers named
/// `landcover` / `water` — that is why the Übersicht still reads as
/// OpenFreeMap. Skip that boost and keep these paints instead.
const kOverviewBrowseBg = '#C9D2CB';
const kOverviewBrowseEarth = '#B8C6BB';
const kOverviewBrowseLand = '#8FA897';
const kOverviewBrowseLandOpacity = 0.40;
const kOverviewBrowseLanduseOpacity = 0.52;
const kOverviewBrowseWater = '#7A9AAB';
const kOverviewBrowseBuilding = '#A8B4AC';
const kOverviewBrowseBuildingOpacity = 0.12;
const kOverviewBrowseRoad = '#7A8B73';
const kOverviewBrowseRoadMajor = '#5E6F58';
const kOverviewBrowseHighway = '#3D4A3E';
const kOverviewBrowsePlace = '#2C3A32';
const kOverviewBrowseHalo = '#D5DDD6';
const kOverviewBrowsePlacesMinZoom = 7.0;
const kOverviewBrowseBuildingsMinZoom = 12.0;

const kOverviewBrowseMetaKey = 'aetherride:overview-browse';

/// Bright nature fills belong on street styles, not the z11 Blatt.
bool styleSkipsNatureFillBoost(String styleUrl) =>
    isOverviewOnlyBasemap(styleUrl) ||
    isLocalOverviewStyleUrl(styleUrl) ||
    styleHasCoarseWaterPolygons(styleUrl);

Map<String, dynamic>? _asMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return null;
}

/// Mutate a Protomaps z11 style so Explore is quieter than Ride/Bright.
Map<String, dynamic> restyleOverviewBrowse(Map<String, dynamic> style) {
  final meta = _asMap(style['metadata']) ?? <String, dynamic>{};
  meta['aetherride:overview'] = true;
  meta[kOverviewBrowseMetaKey] = true;
  style['metadata'] = meta;

  final layers = style['layers'];
  if (layers is! List) return style;
  for (var i = 0; i < layers.length; i++) {
    final layer = _asMap(layers[i]);
    if (layer == null) continue;
    final id = layer['id']?.toString() ?? '';
    final paint = _asMap(layer['paint']) ?? <String, dynamic>{};
    final layout = _asMap(layer['layout']) ?? <String, dynamic>{};
    switch (id) {
      case 'background':
        paint['background-color'] = kOverviewBrowseBg;
      case 'earth':
        paint['fill-color'] = kOverviewBrowseEarth;
      case 'landcover':
        paint['fill-color'] = kOverviewBrowseLand;
        paint['fill-opacity'] = kOverviewBrowseLandOpacity;
      case 'landuse':
        paint['fill-color'] = kOverviewBrowseLand;
        paint['fill-opacity'] = kOverviewBrowseLanduseOpacity;
      case 'water':
        paint['fill-color'] = kOverviewBrowseWater;
      case 'waterway':
        paint['line-color'] = kOverviewBrowseWater;
      case 'buildings':
        layer['minzoom'] = kOverviewBrowseBuildingsMinZoom;
        paint['fill-color'] = kOverviewBrowseBuilding;
        paint['fill-opacity'] = kOverviewBrowseBuildingOpacity;
      case 'roads':
        paint['line-color'] = kOverviewBrowseRoad;
      case 'roads-major':
        paint['line-color'] = kOverviewBrowseRoadMajor;
      case 'roads-highway':
        paint['line-color'] = kOverviewBrowseHighway;
      case 'boundaries':
        paint['line-color'] = kOverviewBrowseRoad;
      case 'pois':
        layer['minzoom'] = 9;
        paint['text-color'] = kOverviewBrowsePlace;
        paint['text-halo-color'] = kOverviewBrowseHalo;
      case 'places':
        layer['minzoom'] = kOverviewBrowsePlacesMinZoom;
        layout['text-size'] = [
          'interpolate',
          ['linear'],
          ['zoom'],
          7,
          9,
          11,
          12,
        ];
        paint['text-color'] = kOverviewBrowsePlace;
        paint['text-halo-color'] = kOverviewBrowseHalo;
        layer['layout'] = layout;
      default:
        break;
    }
    if (paint.isNotEmpty) layer['paint'] = paint;
    layers[i] = layer;
  }
  return style;
}

bool overviewBrowseStylePainted(Map<String, dynamic> style) {
  final meta = _asMap(style['metadata']);
  return meta?[kOverviewBrowseMetaKey] == true;
}

/// Restyle an on-disk Blatt that was saved before sage paper.
bool ensureOverviewBrowseStyle(Map<String, dynamic> style) {
  if (overviewBrowseStylePainted(style)) return false;
  restyleOverviewBrowse(style);
  return true;
}

/// Runtime pass for a Blatt already on the map (CDN or an older local JSON).
Future<void> applyOverviewBrowsePaint(MapLibreMapController c) async {
  Future<void> fill(
    String id, {
    String? color,
    double? opacity,
    String? visibility,
  }) async {
    try {
      await c.setLayerProperties(
        id,
        FillLayerProperties(
          fillColor: color,
          fillOpacity: opacity,
          visibility: visibility,
        ),
      );
    } catch (_) {}
  }

  Future<void> line(String id, String color) async {
    try {
      await c.setLayerProperties(id, LineLayerProperties(lineColor: color));
    } catch (_) {}
  }

  Future<void> symbol(String id) async {
    try {
      await c.setLayerProperties(
        id,
        SymbolLayerProperties(
          textColor: kOverviewBrowsePlace,
          textHaloColor: kOverviewBrowseHalo,
          textSize: 11,
        ),
      );
    } catch (_) {}
  }

  await fill('earth', color: kOverviewBrowseEarth);
  await fill(
    'landcover',
    color: kOverviewBrowseLand,
    opacity: kOverviewBrowseLandOpacity,
  );
  await fill(
    'landuse',
    color: kOverviewBrowseLand,
    opacity: kOverviewBrowseLanduseOpacity,
  );
  await fill('water', color: kOverviewBrowseWater);
  await fill(
    'buildings',
    color: kOverviewBrowseBuilding,
    opacity: kOverviewBrowseBuildingOpacity,
    visibility: 'none',
  );
  await line('waterway', kOverviewBrowseWater);
  await line('roads', kOverviewBrowseRoad);
  await line('roads-major', kOverviewBrowseRoadMajor);
  await line('roads-highway', kOverviewBrowseHighway);
  await line('boundaries', kOverviewBrowseRoad);
  await symbol('places');
  await symbol('pois');
}
