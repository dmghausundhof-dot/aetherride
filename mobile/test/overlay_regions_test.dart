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
    expect(overlayRegionForPoint(8.40, 49.01)?.id, 'karlsruhe');
    expect(overlayRegionForPoint(8.42, 49.045)?.id, 'karlsruhe');
    expect(overlayRegionForPoint(-30, 0), isNull);
  });

  test('online cycle mesh follows the Blatt, including Paris', () {
    expect(pointInOnlineCycleMesh(8.54, 47.37), isTrue);
    expect(pointInOnlineCycleMesh(2.35, 48.86), isTrue);
    expect(pointInOnlineCycleMesh(-30, 0), isFalse);
    expect(overlayDataExpectedAt(8.54, 47.37), isTrue);
    expect(overlayDataExpectedAt(2.35, 48.86), isTrue);
    expect(overlayDataExpectedAt(-30, 0), isFalse);
  });

  test('ways overlay at z12 in Hausberge, mesh at atlas zoom', () {
    expect(detailOverlayPackIdForPoint(8.68, 49.41), 'rhein-neckar');
    expect(detailOverlayPackIdForPoint(7.85, 47.99), 'schwarzwald-nord');
    expect(detailOverlayPackIdForPoint(13.405, 52.52), isNull);
    expect(detailOverlayPackIdForPoint(2.35, 48.86), 'paris');
    expect(detailOverlayPackIdForPoint(4.835, 45.76), 'lyon');
    expect(detailOverlayPackIdForPoint(6.13, 45.9), 'annecy');

    final hdAtlas = chooseOnlineBikeOverlay(
      lng: 8.68,
      lat: 49.41,
      zoom: 8,
    );
    expect(hdAtlas.kind, OnlineBikeOverlayKind.mesh);
    expect(hdAtlas.url, contains('cycle-routes.pmtiles'));
    expect(hdAtlas.url, isNot(contains('france-west')));

    final hdWays = chooseOnlineBikeOverlay(
      lng: 8.68,
      lat: 49.41,
      zoom: 13,
    );
    expect(hdWays.kind, OnlineBikeOverlayKind.ways);
    expect(hdWays.url, contains('/rhein-neckar/bike-overlay.pmtiles'));

    final parisAtlas = chooseOnlineBikeOverlay(
      lng: 2.35,
      lat: 48.86,
      zoom: 8,
    );
    expect(parisAtlas.kind, OnlineBikeOverlayKind.mesh);
    expect(parisAtlas.url, contains('cycle-routes-france-west.pmtiles'));

    final parisWays = chooseOnlineBikeOverlay(
      lng: 2.35,
      lat: 48.86,
      zoom: 13,
    );
    expect(parisWays.kind, OnlineBikeOverlayKind.ways);
    expect(parisWays.url, contains('/paris/bike-overlay.pmtiles'));
  });
}
