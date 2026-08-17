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
    expect(overlayRegionById('clermont-ferrand')?.name, contains('Puy de Dôme'));
    expect(overlayRegionById('missing'), isNull);
  });

  test('online cycle mesh follows the Blatt, including Paris', () {
    expect(pointInOnlineCycleMesh(8.54, 47.37), isTrue);
    expect(pointInOnlineCycleMesh(2.35, 48.86), isTrue);
    expect(pointInOnlineCycleMesh(-30, 0), isFalse);
    expect(overlayDataExpectedAt(8.54, 47.37), isTrue);
    expect(overlayDataExpectedAt(2.35, 48.86), isTrue);
    expect(overlayDataExpectedAt(-30, 0), isFalse);
  });

  test('ways overlay from z10 in DACH, mesh below that', () {
    expect(detailOverlayPackIdForPoint(8.68, 49.41), 'rhein-neckar');
    expect(detailOverlayPackIdForPoint(7.85, 47.99), 'schwarzwald-nord');
    expect(detailOverlayPackIdForPoint(13.405, 52.52), isNull);
    expect(detailOverlayPackIdForPoint(2.35, 48.86), 'paris');
    expect(detailOverlayPackIdForPoint(4.835, 45.76), 'lyon');
    expect(detailOverlayPackIdForPoint(6.13, 45.9), 'annecy');
    expect(detailOverlayPackIdForPoint(4.9, 52.37), 'amsterdam');
    expect(detailOverlayPackIdForPoint(4.3, 52.08), 'den-haag');
    expect(detailOverlayPackIdForPoint(7.75, 48.58), 'strasbourg');
    expect(detailOverlayPackIdForPoint(-0.58, 44.84), 'bordeaux');
    expect(detailOverlayPackIdForPoint(12.5, 41.9), 'roma');

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

    final berlinWays = chooseOnlineBikeOverlay(
      lng: 13.405,
      lat: 52.52,
      zoom: 13,
    );
    expect(berlinWays.kind, OnlineBikeOverlayKind.ways);
    expect(berlinWays.url, contains('dach-ways.pmtiles'));

    final berlinZ10 = chooseOnlineBikeOverlay(
      lng: 13.405,
      lat: 52.52,
      zoom: 10,
    );
    expect(berlinZ10.kind, OnlineBikeOverlayKind.ways);
    expect(berlinZ10.url, contains('dach-ways.pmtiles'));

    final berlinZ9 = chooseOnlineBikeOverlay(
      lng: 13.405,
      lat: 52.52,
      zoom: 9,
    );
    expect(berlinZ9.kind, OnlineBikeOverlayKind.mesh);

    final wienWays = chooseOnlineBikeOverlay(
      lng: 16.373,
      lat: 48.208,
      zoom: 13,
    );
    expect(wienWays.kind, OnlineBikeOverlayKind.ways);
    expect(wienWays.url, contains('dach-ways.pmtiles'));

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

    expect(pointInOnlineCycleMesh(12.5, 41.9), isTrue);
    expect(
      chooseOnlineBikeOverlay(lng: 12.5, lat: 41.9, zoom: 8).kind,
      OnlineBikeOverlayKind.mesh,
    );
    expect(
      chooseOnlineBikeOverlay(lng: 12.5, lat: 41.9, zoom: 8).url,
      contains('cycle-routes-italy-center.pmtiles'),
    );
    expect(
      chooseOnlineBikeOverlay(lng: 16.7, lat: 40.2, zoom: 8).url,
      contains('cycle-routes-italy-south.pmtiles'),
    );

    final amsterdamWays = chooseOnlineBikeOverlay(
      lng: 4.9,
      lat: 52.37,
      zoom: 13,
    );
    expect(amsterdamWays.kind, OnlineBikeOverlayKind.ways);
    expect(amsterdamWays.url, contains('/amsterdam/bike-overlay.pmtiles'));

    final utrechtCountry = chooseOnlineBikeOverlay(
      lng: 5.3,
      lat: 52.2,
      zoom: 12,
    );
    expect(utrechtCountry.kind, OnlineBikeOverlayKind.ways);
    expect(utrechtCountry.url, contains('nl-ways.pmtiles'));

    final brusselsWays = chooseOnlineBikeOverlay(
      lng: 4.35,
      lat: 50.85,
      zoom: 12,
    );
    expect(brusselsWays.kind, OnlineBikeOverlayKind.ways);
    expect(brusselsWays.url, contains('be-ways.pmtiles'));

    final milanCountry = chooseOnlineBikeOverlay(
      lng: 9.19,
      lat: 45.46,
      zoom: 12,
    );
    expect(milanCountry.kind, OnlineBikeOverlayKind.ways);
    expect(milanCountry.url, contains('/milano/bike-overlay.pmtiles'));

    final naplesCountry = chooseOnlineBikeOverlay(
      lng: 14.8,
      lat: 40.85,
      zoom: 12,
    );
    expect(naplesCountry.kind, OnlineBikeOverlayKind.ways);
    expect(naplesCountry.url, contains('italy-ways.pmtiles'));

    final bordeauxRural = chooseOnlineBikeOverlay(
      lng: -0.2,
      lat: 44.6,
      zoom: 12,
    );
    expect(bordeauxRural.kind, OnlineBikeOverlayKind.mesh);
    expect(browseUsesLiveNetworkFallback(bordeauxRural), isTrue);

    final london = chooseOnlineBikeOverlay(
      lng: -0.13,
      lat: 51.51,
      zoom: 12,
    );
    expect(london.kind, OnlineBikeOverlayKind.mesh);
    expect(browseUsesLiveNetworkFallback(london), isTrue);

    expect(
      browseUsesLiveNetworkFallback(berlinWays),
      isFalse,
    );
  });

  test('catalog protomaps is not a live OSM network source', () {
    expect(liveOsmNetworkSourceId(['protomaps']), isNull);
    expect(liveOsmNetworkSourceId(['protomaps', 'terrain-dem']), isNull);
    expect(liveOsmNetworkSourceId(['openmaptiles']), 'openmaptiles');
    expect(
      liveOsmNetworkSourceId(['protomaps', 'openmaptiles']),
      'openmaptiles',
    );
  });
}
