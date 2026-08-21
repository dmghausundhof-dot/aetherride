import 'dart:convert';

import 'package:aetherride_mobile/data/routing/bike_overlay.dart';
import 'package:aetherride_mobile/domain/routing/bike_overlay_class.dart';
import 'package:aetherride_mobile/domain/routing/browse_map_paint.dart';
import 'package:aetherride_mobile/domain/routing/browse_map_stack.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('label layer is the first symbol candidate', () {
    expect(
      browseNetworkBeforeLayerId(['roads', 'pois', 'places']),
      'pois',
    );
    expect(browseNetworkBeforeLayerId(['roads', 'places']), 'places');
    expect(browseNetworkBeforeLayerId(['background', 'roads']), isNull);
  });

  test('paths sit under tracks and cycleways, all under labels', () {
    final stacked = [
      'background',
      'roads',
      ...kBrowseLiveStackBottomToTop,
      ...kBrowseOverlayStackBottomToTop,
      'pois',
      'places',
    ];
    expect(browseNetworkSitsBelowLabels(stacked), isTrue);
    expect(
      browseStackOrderOk(stacked, [
        ...kBrowseLiveStackBottomToTop,
        ...kBrowseOverlayStackBottomToTop,
      ]),
      isTrue,
    );
  });

  test('paths above cycleways fail the stack contract', () {
    expect(
      browseStackOrderOk(
        ['osm-live-cycleway', 'osm-live-path', 'pois'],
        kBrowseLiveStackBottomToTop,
      ),
      isFalse,
    );
    expect(
      browseNetworkSitsBelowLabels([
        'roads',
        'pois',
        'osm-live-path',
        'bike-overlay-road',
      ]),
      isFalse,
    );
  });

  test('live path layer is path/bridleway, not sidewalks', () {
    final json = jsonEncode(osmLivePathFilter());
    expect(json, contains('"path"'));
    expect(json, contains('"bridleway"'));
    for (final skip in kOsmLivePathExcludeSubclasses) {
      expect(json, isNot(contains('"$skip"')));
    }
  });

  test('live cycleway keeps designated footways, not every footway', () {
    final json = jsonEncode(osmLiveCyclewayFilter());
    expect(json, contains('cycleway'));
    expect(json, contains('footway'));
    expect(json, contains('designated'));
    expect(json, contains('yes'));
  });

  test('browse colors stay the three honest swatches', () {
    expect(BikeOverlayColors.unrated, BrowseMapPaint.trailHex);
    expect(BikeOverlayColors.dirt, BrowseMapPaint.trailHex);
    expect(BikeOverlayColors.road, BrowseMapPaint.wayHex);
    expect(BikeOverlayColors.urban, BrowseMapPaint.wayHex);
    expect(BikeOverlayColors.unrated, isNot('#90A4AE'));
    expect(BikeOverlayColors.dirt, isNot('#9A5B32'));
  });

  test('DACH ways hide the live OpenFreeMap fallback', () {
    expect(
      liveNetworkFallbackAt(lng: 13.405, lat: 52.52, zoom: 13),
      isFalse,
    );
    expect(
      liveNetworkFallbackAt(lng: -0.13, lat: 51.51, zoom: 12),
      isTrue,
    );
  });
}
