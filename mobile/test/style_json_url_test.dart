import 'package:flutter_test/flutter_test.dart';
import 'package:aetherride_mobile/data/routing/basemap_street_contrast.dart';
import 'package:aetherride_mobile/data/routing/map_style_url.dart';

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
      isMapLibreStyleJsonUrl(
        'https://krmgatsugplouzrhhozn.supabase.co/storage/v1/object/public/offline-packs/basemap/dach-z11-style.json',
      ),
      isTrue,
    );
    expect(
      isMapLibreStyleJsonUrl('https://example.com/lifestyle'),
      isFalse,
    );
  });

  test('skipMapLibreOfflineRegion for DACH pmtiles style', () {
    expect(
      skipMapLibreOfflineRegion(
        'https://krmgatsugplouzrhhozn.supabase.co/storage/v1/object/public/offline-packs/basemap/dach-z11-style.json',
      ),
      isTrue,
    );
    expect(
      skipMapLibreOfflineRegion(
        'https://krmgatsugplouzrhhozn.supabase.co/storage/v1/object/public/offline-packs/basemap/france-west-z11-style.json',
      ),
      isTrue,
    );
    expect(
      skipMapLibreOfflineRegion('https://tiles.openfreemap.org/styles/liberty'),
      isFalse,
    );
  });

  test('basemap archive id follows pack bbox', () {
    expect(basemapArchiveIdForBbox([8.4, 47.3, 8.7, 47.5]), 'dach-z11');
    expect(
        basemapArchiveIdForBbox([4.7, 45.65, 5.05, 45.9]), 'france-west-z11');
  });

  test('DACH/FR z11 packs are overview-only, Liberty is street-level', () {
    const dach =
        'https://krmgatsugplouzrhhozn.supabase.co/storage/v1/object/public/offline-packs/basemap/dach-z11-style.json';
    const local = 'file:///data/user/0/app/files/basemap/dach-z11-style.json';
    const france =
        'https://cdn.example/offline-packs/basemap/france-west-z11-style.json';
    expect(isOverviewOnlyBasemap(dach), isTrue);
    expect(isStreetLevelBasemap(dach), isFalse);
    expect(isOverviewOnlyBasemap(local), isTrue);
    expect(isOverviewOnlyBasemap(france), isTrue);
    expect(
      isStreetLevelBasemap('https://tiles.openfreemap.org/styles/liberty'),
      isTrue,
    );
    expect(
      isOverviewOnlyBasemap('https://tiles.openfreemap.org/styles/liberty'),
      isFalse,
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

  test(
      'liveMapStyleUrl ignores overview packs and prefers Bright, not Alidade',
      () {
    const dach =
        'https://krmgatsugplouzrhhozn.supabase.co/storage/v1/object/public/offline-packs/basemap/dach-z11-style.json';
    expect(
      liveMapStyleUrl(pmtilesOrStyleUrl: dach, stadiaApiKey: 'stadia-test'),
      'https://tiles.stadiamaps.com/styles/osm_bright.json?api_key=stadia-test',
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
    expect(isNatureParkFillLayer('highway_path'), isFalse);
    expect(styleNeedsGrayStreetBoost(kOpenFreeMapBrightStyleUrl), isFalse);
    expect(
      styleNeedsGrayStreetBoost(
        'https://tiles.stadiamaps.com/styles/osm_bright.json?api_key=x',
      ),
      isFalse,
    );
  });
}
