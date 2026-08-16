import 'package:aetherride_mobile/data/routing/bike_overlay.dart';
import 'package:aetherride_mobile/data/routing/overlay_regions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GPS picks DACH overlay region, not RN default', () {
    expect(overlayRegionForPoint(16.373, 48.208)?.id, 'wien');
    expect(overlayRegionForPoint(11.575, 48.137)?.id, 'muenchen');
    expect(overlayRegionForPoint(8.541, 47.376)?.id, 'zuerich');
    expect(overlayRegionForPoint(9.993, 53.551)?.id, 'hamburg');
    expect(overlayRegionForPoint(8.694, 49.409)?.id, 'rhein-neckar');
    expect(overlayRegionForPoint(3.885, 43.61)?.id, 'montpellier');
    expect(overlayRegionForPoint(3.082, 45.777)?.id, 'clermont-ferrand');
    expect(overlayRegionById('vosges')?.id, 'vosges');
    expect(overlayRegionForPoint(-30, 0), isNull);
  });

  test('online cycle mesh covers DACH, not ocean or Paris', () {
    expect(pointInOnlineCycleMesh(8.54, 47.37), isTrue);
    expect(pointInOnlineCycleMesh(2.35, 48.86), isFalse);
    expect(pointInOnlineCycleMesh(-30, 0), isFalse);
    expect(overlayDataExpectedAt(8.54, 47.37), isTrue);
    expect(overlayDataExpectedAt(2.35, 48.86), isFalse);
    expect(overlayDataExpectedAt(-30, 0), isFalse);
  });

  test('ways overlay at z12 in Hausberge, mesh at atlas zoom', () {
    expect(detailOverlayPackIdForPoint(8.68, 49.41), 'rhein-neckar');
    expect(detailOverlayPackIdForPoint(7.85, 47.99), 'schwarzwald-nord');
    expect(detailOverlayPackIdForPoint(13.405, 52.52), isNull);

    final hdAtlas = chooseOnlineBikeOverlay(
      lng: 8.68,
      lat: 49.41,
      zoom: 8,
    );
    expect(hdAtlas.kind, OnlineBikeOverlayKind.mesh);
    expect(hdAtlas.url, contains('cycle-routes.pmtiles'));

    final hdWays = chooseOnlineBikeOverlay(
      lng: 8.68,
      lat: 49.41,
      zoom: 13,
    );
    expect(hdWays.kind, OnlineBikeOverlayKind.ways);
    expect(hdWays.url, contains('/rhein-neckar/bike-overlay.pmtiles'));

    final paris = chooseOnlineBikeOverlay(
      lng: 2.35,
      lat: 48.86,
      zoom: 13,
    );
    expect(paris.kind, OnlineBikeOverlayKind.none);
  });
}
