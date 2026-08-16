import 'package:flutter_test/flutter_test.dart';
import 'package:aetherride_mobile/data/routing/map_style_url.dart';
import 'package:aetherride_mobile/data/routing/overlay_regions.dart';

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
    expect(
      isMapLibreStyleJsonUrl('https://example.com/lifestyle'),
      isFalse,
    );
  });

  test('skipMapLibreOfflineRegion for DACH pmtiles style', () {
    expect(skipMapLibreOfflineRegion(kDachBasemapStyleUrl), isTrue);
    expect(skipMapLibreOfflineRegion(kFranceWestBasemapStyleUrl), isTrue);
    expect(skipMapLibreOfflineRegion(kAlpsSouthBasemapStyleUrl), isTrue);
    expect(
      skipMapLibreOfflineRegion('https://tiles.openfreemap.org/styles/liberty'),
      isFalse,
    );
  });

  test('basemap archive id follows pack bbox', () {
    expect(basemapArchiveIdForBbox([8.4, 47.3, 8.7, 47.5]), 'dach-z11');
    expect(basemapArchiveIdForBbox([4.7, 45.65, 5.05, 45.9]), 'france-west-z11');
    expect(
      basemapArchiveIdForBbox(overlayRegionById('clermont-ferrand')!.bbox),
      'france-west-z11',
    );
    expect(
      basemapArchiveIdForBbox(overlayRegionById('innsbruck')!.bbox),
      'dach-z11',
    );
    expect(
      basemapArchiveIdForBbox(overlayRegionById('nice')!.bbox),
      'alps-south-z11',
    );
    expect(
      basemapArchiveIdForBbox(overlayRegionById('chambery')!.bbox),
      'alps-south-z11',
    );
    expect(kDachBasemapBbox[0], 5.8);
    expect(kFranceWestBasemapBbox[2], 5.85);
  });

  test('online style switches by viewport, empty fallback is not DACH-only', () {
    expect(basemapArchiveIdForLngLat(8.54, 47.37), 'dach-z11');
    expect(basemapArchiveIdForLngLat(2.35, 48.86), 'france-west-z11');
    expect(basemapArchiveIdForLngLat(7.27, 43.70), 'alps-south-z11');
    expect(basemapArchiveIdForLngLat(10.75, 45.58), 'alps-south-z11');
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
    // Hysteresis: stay on France-west while still inside it.
    expect(
      basemapArchiveIdForLngLat(4.83, 45.76, currentId: 'france-west-z11'),
      'france-west-z11',
    );
  });

  test('rewriteStyleProtomapsUrl points at local archive', () {
    final style = {
      'sources': {
        'protomaps': {'type': 'vector', 'url': 'pmtiles://https://cdn/x.pmtiles'},
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
}
