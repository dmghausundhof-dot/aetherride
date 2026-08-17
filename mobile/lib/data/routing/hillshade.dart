import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../domain/routing/browse_map_paint.dart';

const kHillshadeSourceId = 'terrain-dem';
const kHillshadeLayerId = 'hillshade';

const kHillshadeTiles = <String>[
  'https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png',
];

const kHillshadeAttribution = '© Mapzen / AWS Terrain';

const _belowCandidates = <String>[
  'roads',
  'road_minor',
  'highway_minor',
  'places',
];

/// 2D relief on the live catalog. HUD/Stadia already has its own hillshade.
Future<void> applyHillshade(MapLibreMapController c) async {
  try {
    await c.addSource(
      kHillshadeSourceId,
      const RasterDemSourceProperties(
        tiles: kHillshadeTiles,
        tileSize: 256,
        maxzoom: 15,
        encoding: 'terrarium',
        attribution: kHillshadeAttribution,
      ),
    );
  } catch (_) {
    // Source already present after a partial attach.
  }

  String? below;
  try {
    final ids = [for (final raw in await c.getLayerIds()) raw.toString()];
    for (final id in _belowCandidates) {
      if (ids.contains(id)) {
        below = id;
        break;
      }
    }
  } catch (_) {}

  try {
    await c.addHillshadeLayer(
      kHillshadeSourceId,
      kHillshadeLayerId,
      const HillshadeLayerProperties(
        hillshadeExaggeration: BrowseMapPaint.hillshadeExaggeration,
        hillshadeShadowColor: BrowseMapPaint.hillshadeShadowHex,
        hillshadeHighlightColor: BrowseMapPaint.hillshadeHighlightHex,
        hillshadeAccentColor: BrowseMapPaint.hillshadeAccentHex,
        hillshadeIlluminationDirection: 315,
      ),
      belowLayerId: below,
    );
  } catch (err) {
    debugPrint('hillshade: $err');
  }
}

Future<void> setHillshadeVisible(MapLibreMapController c, bool on) async {
  if (on) {
    await applyHillshade(c);
    return;
  }
  try {
    await c.removeLayer(kHillshadeLayerId);
  } catch (_) {}
}

bool styleUsesCatalogHillshade(String styleUrl) {
  final u = styleUrl.toLowerCase();
  return u.contains('/basemap/') && u.contains('-z11-style.json');
}
