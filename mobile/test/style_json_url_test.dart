import 'package:flutter_test/flutter_test.dart';
import 'package:aetherride_mobile/data/routing/basemap_street_contrast.dart';
import 'package:aetherride_mobile/data/routing/hillshade.dart';
import 'package:aetherride_mobile/data/routing/map_style_url.dart';
import 'package:aetherride_mobile/data/routing/overlay_regions.dart';
import 'package:aetherride_mobile/data/routing/overview_browse_paint.dart';

void main() {
  test('isMapLibreStyleJsonUrl rejects raw pmtiles', () {
    expect(
      isMapLibreStyleJsonUrl('https://cdn.example/region.pmtiles'),
      isFalse,
    );
    expect(isRawPmtilesUrl('https://cdn.example/region.pmtiles'), isTrue);
  });

  test('isMapLibreStyleJsonUrl accepts style json paths', () {
    expect(
      isMapLibreStyleJsonUrl(
        'https://tiles.openfreemap.org/styles/liberty',
      ),
      isTrue,
    );
    expect(
      isMapLibreStyleJsonUrl('https://example.com/basemap/style.json'),
      isTrue,
    );
    expect(
      isMapLibreStyleJsonUrl(kDachBasemapStyleUrl),
      isTrue,
    );
    expect(kDachBasemapStyleUrl, contains('?v=$kBasemapStylePaintRev'));
    expect(
      isMapLibreStyleJsonUrl('https://example.com/lifestyle'),
      isFalse,
    );
  });

  test('skipMapLibreOfflineRegion for DACH pmtiles style', () {
    expect(skipMapLibreOfflineRegion(kDachBasemapStyleUrl), isTrue);
    expect(skipMapLibreOfflineRegion(kFranceWestBasemapStyleUrl), isTrue);
    expect(skipMapLibreOfflineRegion(kAlpsSouthBasemapStyleUrl), isTrue);
    expect(skipMapLibreOfflineRegion(kBeneluxBasemapStyleUrl), isTrue);
    expect(skipMapLibreOfflineRegion(kItalyNorthBasemapStyleUrl), isTrue);
    expect(skipMapLibreOfflineRegion(kItalyCenterBasemapStyleUrl), isTrue);
    expect(skipMapLibreOfflineRegion(kItalySouthBasemapStyleUrl), isTrue);
    expect(
        skipMapLibreOfflineRegion(kCataloniaPyreneesBasemapStyleUrl), isTrue);
    expect(skipMapLibreOfflineRegion(kUkSouthBasemapStyleUrl), isTrue);
    expect(
      skipMapLibreOfflineRegion('https://tiles.openfreemap.org/styles/liberty'),
      isFalse,
    );
  });

  test('basemap archive id follows pack bbox', () {
    expect(basemapArchiveIdForBbox([8.4, 47.3, 8.7, 47.5]), 'dach-z11');
    expect(
        basemapArchiveIdForBbox([4.7, 45.65, 5.05, 45.9]), 'france-west-z11');
    expect(
      basemapArchiveIdForBbox([3.0, 45.72, 3.2, 45.85]),
      'france-west-z11',
    );
    expect(
      basemapArchiveIdForBbox(overlayRegionById('innsbruck')!.bbox),
      'dach-z11',
    );
    expect(
        basemapArchiveIdForBbox([7.20, 43.65, 7.32, 43.75]), 'alps-south-z11');
    expect(
        basemapArchiveIdForBbox([5.88, 45.52, 5.98, 45.62]), 'alps-south-z11');
    expect(kDachBasemapBbox[0], 5.8);
    expect(kFranceWestBasemapBbox[2], 5.85);
  });

  test('online style switches by viewport, empty fallback is not DACH-only',
      () {
    expect(basemapArchiveIdForLngLat(8.54, 47.37), 'dach-z11');
    expect(basemapArchiveIdForLngLat(2.35, 48.86), 'france-west-z11');
    expect(basemapArchiveIdForLngLat(7.27, 43.70), 'alps-south-z11');
    expect(basemapArchiveIdForLngLat(10.75, 45.58), 'alps-south-z11');
    expect(basemapArchiveIdForLngLat(4.90, 52.37), 'benelux-z11');
    expect(basemapArchiveIdForLngLat(12.33, 45.44), 'italy-north-z11');
    expect(basemapArchiveIdForLngLat(12.50, 41.90), 'italy-center-z11');
    expect(basemapArchiveIdForLngLat(14.27, 40.85), 'italy-center-z11');
    expect(basemapArchiveIdForLngLat(16.87, 41.12), 'italy-south-z11');
    expect(basemapArchiveIdForLngLat(2.17, 41.39), 'catalonia-pyrenees-z11');
    expect(basemapArchiveIdForLngLat(-0.13, 51.51), 'uk-south-z11');
    expect(
      nextOnlineBasemapStyleUrl(
        currentStyle: kDachBasemapStyleUrl,
        lng: 4.90,
        lat: 52.37,
      ),
      kBeneluxBasemapStyleUrl,
    );
    expect(
      nextOnlineBasemapStyleUrl(
        currentStyle: kDachBasemapStyleUrl,
        lng: 7.27,
        lat: 43.70,
      ),
      kAlpsSouthBasemapStyleUrl,
    );
    expect(
      nextOnlineBasemapStyleUrl(
        currentStyle: kDachBasemapStyleUrl,
        lng: 2.35,
        lat: 48.86,
      ),
      kFranceWestBasemapStyleUrl,
    );
    expect(
      nextOnlineBasemapStyleUrl(
        currentStyle: kAlpsSouthBasemapStyleUrl,
        lng: 7.27,
        lat: 43.70,
      ),
      isNull,
    );
    expect(
      nextOnlineBasemapStyleUrl(
        currentStyle: 'https://tiles.openfreemap.org/styles/liberty',
        lng: 7.27,
        lat: 43.70,
      ),
      isNull,
    );
    expect(
      nextOnlineBasemapStyleUrl(
        currentStyle:
            'file:///data/user/0/app/app_flutter/basemap/dach-z11-style.json',
        lng: 4.90,
        lat: 52.37,
      ),
      isNull,
      reason: 'local overview must not switch to a live CDN Blatt',
    );
    expect(
      nextOnlineBasemapStyleUrl(
        currentStyle: kUkSouthBasemapStyleUrl,
        lng: -0.13,
        lat: 51.51,
      ),
      isNull,
    );
    for (final url in [
      kDachBasemapStyleUrl,
      kFranceWestBasemapStyleUrl,
      kAlpsSouthBasemapStyleUrl,
      kBeneluxBasemapStyleUrl,
      kItalyNorthBasemapStyleUrl,
      kItalyCenterBasemapStyleUrl,
      kItalySouthBasemapStyleUrl,
      kCataloniaPyreneesBasemapStyleUrl,
      kUkSouthBasemapStyleUrl,
    ]) {
      expect(isOverviewOnlyBasemap(url), isTrue, reason: url);
      expect(isStreetLevelBasemap(url), isFalse, reason: url);
    }
    expect(
      isStreetLevelBasemap('https://tiles.openfreemap.org/styles/liberty'),
      isTrue,
    );
    expect(
      rideHudStyleUrl(
        liveStyle: kOpenFreeMapBrightStyleUrl,
        resolvedStyle: kDachBasemapStyleUrl,
      ),
      kOpenFreeMapBrightStyleUrl,
    );
    expect(
      rideHudStyleUrl(
        liveStyle: kOpenFreeMapBrightStyleUrl,
        resolvedStyle:
            'file:///data/user/0/app/app_flutter/basemap/dach-z11-style.json',
      ),
      kOpenFreeMapBrightStyleUrl,
    );
    expect(
      rideHudStyleUrl(
        liveStyle: kOpenFreeMapBrightStyleUrl,
        resolvedStyle: kOpenFreeMapLibertyStyleUrl,
      ),
      kOpenFreeMapLibertyStyleUrl,
    );
    expect(
      rideHudUsesOfflineStreetTiles(
        liveStyle: kOpenFreeMapBrightStyleUrl,
        resolvedStyle: kDachBasemapStyleUrl,
      ),
      isFalse,
    );
    expect(
      rideHudUsesOfflineStreetTiles(
        liveStyle: kOpenFreeMapBrightStyleUrl,
        resolvedStyle:
            'file:///data/user/0/app/app_flutter/basemap/dach-z11-style.json',
      ),
      isFalse,
    );
    expect(
      rideHudUsesOfflineStreetTiles(
        liveStyle: kOpenFreeMapBrightStyleUrl,
        resolvedStyle: kOpenFreeMapLibertyStyleUrl,
      ),
      isFalse,
      reason: 'live HTTP liberty is not an offline HUD',
    );
    expect(
      rideHudStreetMapNeedsNet(online: true, offlineStreetTiles: false),
      isFalse,
    );
    expect(
      rideHudStreetMapNeedsNet(online: false, offlineStreetTiles: true),
      isFalse,
    );
    expect(
      rideHudStreetMapNeedsNet(online: false, offlineStreetTiles: false),
      isTrue,
    );
    expect(
      isRideHudEmptyStyle(
        'file:///docs/basemap/hud-empty-style.json',
      ),
      isTrue,
    );
    expect(isRideHudEmptyStyle(kRideHudEmptyStyleJson), isTrue);
    expect(isRideHudEmptyStyle(kOpenFreeMapBrightStyleUrl), isFalse);
    expect(
      rideHudMapStyle(
        liveStyle: kOpenFreeMapBrightStyleUrl,
        resolvedStyle: kDachBasemapStyleUrl,
        online: false,
        offlineStreetTiles: false,
        emptyStyleUri: 'file:///docs/basemap/hud-empty-style.json',
      ),
      'file:///docs/basemap/hud-empty-style.json',
    );
    expect(
      rideHudMapStyle(
        liveStyle: kOpenFreeMapBrightStyleUrl,
        resolvedStyle: kDachBasemapStyleUrl,
        online: true,
        offlineStreetTiles: false,
        emptyStyleUri: 'file:///docs/basemap/hud-empty-style.json',
      ),
      kOpenFreeMapBrightStyleUrl,
    );
    expect(
      rideHudUsesOfflineStreetTiles(
        liveStyle: kOpenFreeMapBrightStyleUrl,
        resolvedStyle: 'file:///data/user/0/app/styles/liberty-style.json',
      ),
      isTrue,
    );
    expect(
      isOverviewOnlyBasemap('https://tiles.openfreemap.org/styles/liberty'),
      isFalse,
    );
    // Hysteresis: stay on France-west while still inside it.
    expect(
      basemapArchiveIdForLngLat(4.83, 45.76, currentId: 'france-west-z11'),
      'france-west-z11',
    );
  });

  test('union of catalog Blätter includes Puglia and South-East England', () {
    final world = unionOnlineBasemapBbox();
    expect(world.length, 4);
    expect(world[0], lessThan(kFranceWestBasemapBbox[0]));
    expect(world[1], lessThan(kItalySouthBasemapBbox[1]));
    expect(world[2], greaterThan(kItalySouthBasemapBbox[2]));
    expect(world[3], greaterThan(kDachBasemapBbox[3]));
    expect(pointInBasemapBbox(16.87, 41.12, world), isTrue);
    expect(pointInBasemapBbox(0.13, 51.5, world), isTrue);
  });

  test('coverage sketch world is DACH for a DACH pack', () {
    const karlsruhe = [8.2, 48.9, 8.6, 49.2];
    final dach = coverageSketchWorld(karlsruhe);
    expect(coverageSketchWorldIsDach(dach), isTrue);
    expect(dach, kDachBasemapBbox);
    const puglia = [16.5, 40.2, 18.5, 41.6];
    expect(coverageSketchWorldIsDach(coverageSketchWorld(puglia)), isFalse);
    expect(coverageSketchWorld(puglia), kItalySouthBasemapBbox);
    expect(
      pointInBasemapBbox(16.87, 41.12, coverageSketchWorld(puglia)),
      isTrue,
    );
  });

  test('rewriteStyleProtomapsUrl points at local archive', () {
    final style = {
      'sources': {
        'protomaps': {
          'type': 'vector',
          'url': 'pmtiles://https://cdn/x.pmtiles'
        },
      },
    };
    rewriteStyleProtomapsUrl(style, '/data/basemap/dach-z11.pmtiles');
    expect(
      (style['sources'] as Map)['protomaps']['url'],
      'pmtiles://file:///data/basemap/dach-z11.pmtiles',
    );
  });

  test('rewriteStyleLocalAssets points glyphs and sprites at files', () {
    final style = <String, dynamic>{
      'glyphs': 'https://cdn/fonts/{fontstack}/{range}.pbf',
      'sprite': 'https://cdn/sprites/v4/light',
    };
    rewriteStyleLocalAssets(style, '/data/basemap');
    expect(
      style['glyphs'],
      'file:///data/basemap/assets/fonts/{fontstack}/{range}.pbf',
    );
    expect(
      style['sprite'],
      'file:///data/basemap/assets/sprites/v4/light',
    );
  });

  test('street contrast targets residential layers, not motorways or overlays',
      () {
    expect(isBasemapStreetContrastLayer('highway_minor'), isTrue);
    expect(isBasemapStreetContrastLayer('highway-minor-casing'), isTrue);
    expect(isBasemapStreetContrastLayer('road_minor'), isTrue);
    expect(isBasemapStreetContrastLayer('highway_path'), isFalse);
    expect(isBasemapStreetContrastLayer('highway_motorway_inner'), isFalse);
    expect(isBasemapStreetContrastLayer('bike-overlay-mtb'), isFalse);
    expect(isBasemapStreetContrastLayer('highway-primary'), isFalse);
    for (final id in kKnownStreetContrastLayerIds) {
      expect(isBasemapStreetContrastLayer(id), isTrue, reason: id);
    }
  });

  test('liveMapStyleUrl ignores overview packs and prefers Bright, not Alidade',
      () {
    const dach =
        'https://krmgatsugplouzrhhozn.supabase.co/storage/v1/object/public/offline-packs/basemap/dach-z11-style.json';
    expect(
      liveMapStyleUrl(pmtilesOrStyleUrl: dach, stadiaApiKey: 'stadia-test'),
      'https://tiles.stadiamaps.com/styles/osm_bright.json?api_key=stadia-test',
    );
    expect(
      catalogBrowseMapStyleUrl(
        pmtilesOrStyleUrl: dach,
        lng: 9.2,
        lat: 49.0,
      ),
      kDachBasemapStyleUrl,
    );
    expect(
      catalogBrowseMapStyleUrl(
        pmtilesOrStyleUrl: '',
        lng: 2.35,
        lat: 48.86,
      ),
      kFranceWestBasemapStyleUrl,
    );
    expect(
      onlineCycleMeshPmtilesUrlForPoint(12.5, 41.9),
      contains('cycle-routes-italy-center.pmtiles'),
    );
    expect(
      onlineCycleMeshPmtilesUrlForPoint(16.7, 40.2),
      contains('cycle-routes-italy-south.pmtiles'),
    );
    expect(styleUsesCatalogHillshade(dach), isTrue);
    expect(
      styleUsesCatalogHillshade(
        'https://tiles.stadiamaps.com/styles/osm_bright.json?api_key=x',
      ),
      isFalse,
    );
    expect(
      liveMapStyleUrl(pmtilesOrStyleUrl: dach, stadiaApiKey: ''),
      kOpenFreeMapBrightStyleUrl,
    );
    expect(
      liveMapStyleUrl(pmtilesOrStyleUrl: '', stadiaApiKey: ''),
      kOpenFreeMapBrightStyleUrl,
    );
    expect(
      liveMapStyleUrl(
        pmtilesOrStyleUrl: 'https://tiles.openfreemap.org/styles/bright',
        stadiaApiKey: 'stadia-test',
      ),
      'https://tiles.openfreemap.org/styles/bright',
    );
  });

  test('street contrast boost only on gray Alidade/Positron', () {
    expect(styleNeedsGrayStreetBoost(kOpenFreeMapPositronStyleUrl), isTrue);
    expect(
      styleNeedsGrayStreetBoost(
        'https://tiles.stadiamaps.com/styles/alidade_smooth.json?api_key=x',
      ),
      isTrue,
    );
    expect(isNatureParkFillLayer('landcover_park'), isTrue);
    expect(isNatureParkFillLayer('landuse_garden'), isTrue);
    expect(isNatureWoodFillLayer('landcover-wood'), isTrue);
    expect(isNatureWaterFillLayer('water'), isTrue);
    expect(isNatureParkFillLayer('landuse-residential'), isFalse);
    expect(kKnownNatureFillLayerIds, contains('landcover_park'));
    expect(isNatureWaterFillLayer('waterway'), isFalse);
    expect(isWaterwayLineLayer('waterway'), isTrue);
    expect(isWaterwayLineLayer('water'), isFalse);
    expect(styleHasCoarseWaterPolygons(kDachBasemapStyleUrl), isTrue);
    expect(styleHasCoarseWaterPolygons(kOpenFreeMapBrightStyleUrl), isFalse);
    final geom = kWaterFillPolygonFilter.toString();
    expect(kWaterFillPolygonOnlyFilter.toString(), contains('Polygon'));
    expect(geom, contains('Polygon'));
    expect(geom, contains('river'));
    expect(isNatureParkFillLayer('highway_path'), isFalse);
    expect(styleNeedsGrayStreetBoost(kOpenFreeMapBrightStyleUrl), isFalse);
    expect(
      styleNeedsGrayStreetBoost(
        'https://tiles.stadiamaps.com/styles/osm_bright.json?api_key=x',
      ),
      isFalse,
    );
  });

  test('DACH land ring is a closed path for the sheet sketch', () {
    expect(kDachLandRingLngLat.length, greaterThanOrEqualTo(3));
    expect(kDachLandRingLngLat.first, kDachLandRingLngLat.last);
    final world = coverageSketchWorld([8.2, 48.9, 8.6, 49.2]);
    expect(coverageSketchWorldIsDach(world), isTrue);
    expect(coverageSketchLandRing(world), kDachLandRingLngLat);
    final other = coverageSketchLandRing([1.0, 41.0, 3.0, 43.0]);
    expect(other.length, greaterThanOrEqualTo(3));
    expect(other.first, other.last);
  });

  test('offline browse style uses the Blatt, never a CDN PMTiles URL', () {
    expect(
      isLocalOverviewStyleUrl('file:///docs/basemap/dach-z11-style.json'),
      isTrue,
    );
    expect(
      isLocalOverviewStyleUrl(
        'https://cdn.example/basemap/dach-z11-style.json',
      ),
      isFalse,
    );
    expect(
      browseStyleWhenOffline(
        localStyleUri: 'file:///docs/basemap/dach-z11-style.json',
        currentStyle: 'https://tiles.openfreemap.org/styles/bright',
        streetsFallback: 'https://tiles.openfreemap.org/styles/bright',
      ),
      'file:///docs/basemap/dach-z11-style.json',
    );
    expect(
      browseStyleWhenOffline(
        localStyleUri: null,
        currentStyle: 'https://tiles.openfreemap.org/styles/bright',
        streetsFallback: 'https://fallback',
      ),
      'https://tiles.openfreemap.org/styles/bright',
    );
    expect(
      browseStyleWhenOffline(
        localStyleUri: null,
        currentStyle: kDachBasemapStyleUrl,
        streetsFallback: 'https://fallback',
      ),
      'https://fallback',
    );
    expect(
      browseStyleWhenOffline(
        localStyleUri: null,
        currentStyle: 'file:///gone.json',
        streetsFallback: 'https://fallback',
      ),
      'https://fallback',
    );
  });

  test('overview Blatt skips Bright nature fills', () {
    expect(styleSkipsNatureFillBoost(kDachBasemapStyleUrl), isTrue);
    expect(
      styleSkipsNatureFillBoost(
        'file:///docs/basemap/dach-z11-style.json',
      ),
      isTrue,
    );
    expect(styleSkipsNatureFillBoost(kOpenFreeMapBrightStyleUrl), isFalse);
    expect(styleSkipsNatureFillBoost(kOpenFreeMapPositronStyleUrl), isFalse);
  });

  test('overview browse restyle is sage paper, not Bright parks', () {
    final style = <String, dynamic>{
      'metadata': {'aetherride:overview': true},
      'layers': [
        {
          'id': 'background',
          'type': 'background',
          'paint': {'background-color': '#e8eee9'},
        },
        {
          'id': 'earth',
          'type': 'fill',
          'paint': {'fill-color': '#dfe8e2'},
        },
        {
          'id': 'landcover',
          'type': 'fill',
          'paint': {'fill-color': '#c5d9c8', 'fill-opacity': 0.45},
        },
        {
          'id': 'water',
          'type': 'fill',
          'paint': {'fill-color': '#a8c8d8'},
        },
        {
          'id': 'buildings',
          'type': 'fill',
          'minzoom': 10,
          'paint': {'fill-color': '#cfd6d0', 'fill-opacity': 0.6},
        },
        {
          'id': 'roads',
          'type': 'line',
          'paint': {'line-color': '#8a9a92'},
        },
        {
          'id': 'places',
          'type': 'symbol',
          'minzoom': 5,
          'layout': {
            'text-size': [
              'interpolate',
              ['linear'],
              ['zoom'],
              5,
              10,
              11,
              14,
            ],
          },
          'paint': {
            'text-color': '#2c3a32',
            'text-halo-color': '#f4f7f4',
          },
        },
      ],
    };
    restyleOverviewBrowse(style);
    expect(overviewBrowseStylePainted(style), isTrue);
    Map<String, dynamic> layer(String id) =>
        (style['layers'] as List).cast<Map<String, dynamic>>().firstWhere(
              (l) => l['id'] == id,
            );
    expect(layer('background')['paint']['background-color'], kOverviewBrowseBg);
    expect(layer('earth')['paint']['fill-color'], kOverviewBrowseEarth);
    expect(layer('landcover')['paint']['fill-color'], kOverviewBrowseLand);
    expect(layer('water')['paint']['fill-color'], isNot(kNatureWaterFill));
    expect(layer('buildings')['minzoom'], kOverviewBrowseBuildingsMinZoom);
    expect(layer('roads')['paint']['line-color'], kOverviewBrowseRoad);
    expect(layer('places')['minzoom'], kOverviewBrowsePlacesMinZoom);
    expect(ensureOverviewBrowseStyle(Map<String, dynamic>.from({
      'version': 8,
      'layers': [
        {
          'id': 'background',
          'type': 'background',
          'paint': {'background-color': '#e8eee9'},
        },
      ],
    })), isTrue);
    restyleOverviewBrowse(style);
    expect(layer('background')['paint']['background-color'], kOverviewBrowseBg);
    expect(ensureOverviewBrowseStyle(style), isFalse);
  });
}
