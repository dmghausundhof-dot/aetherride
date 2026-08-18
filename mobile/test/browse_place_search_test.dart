import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/data/routing/geocode_client.dart';
import 'package:aetherride_mobile/domain/routing/browse_place_search.dart';

void main() {
  test('Berlin flies; Wiesloch prefix stays a tour filter', () {
    const tours = [
      'Wiesloch Feierabend',
      'Schwetzingen Schloss–Rhein',
    ];
    expect(
      BrowsePlaceSearch.shouldFlyToPlace(
        query: 'Berlin',
        visibleTourNames: tours,
      ),
      isTrue,
    );
    expect(
      BrowsePlaceSearch.shouldFlyToPlace(
        query: 'Wiesloch',
        visibleTourNames: tours,
      ),
      isFalse,
    );
    expect(
      BrowsePlaceSearch.shouldFlyToPlace(
        query: '  ',
        visibleTourNames: tours,
      ),
      isFalse,
    );
  });

  test('coords always fly', () {
    expect(
      BrowsePlaceSearch.shouldFlyToPlace(
        query: '52.52, 13.40',
        visibleTourNames: const ['Wiesloch Feierabend'],
      ),
      isTrue,
    );
  });

  test('place chips from 3 characters', () {
    expect(BrowsePlaceSearch.shouldOfferPlaceHits('Be'), isFalse);
    expect(BrowsePlaceSearch.shouldOfferPlaceHits('Ber'), isTrue);
  });

  test('Berlin ranks above Berlingen', () {
    final ranked = rankGeocodeHits('Berlin', const [
      GeocodeHit(
        label: 'Berlingen, Moselle, Frankreich',
        lat: 49.24,
        lng: 6.67,
        kind: 'city',
      ),
      GeocodeHit(
        label: 'Berliner Straße, Sandhausen',
        lat: 49.37,
        lng: 8.66,
        kind: 'street',
      ),
      GeocodeHit(
        label: 'Berlin, Deutschland',
        lat: 52.52,
        lng: 13.4,
        kind: 'city',
      ),
    ]);
    expect(ranked.first.label.startsWith('Berlin,'), isTrue);
    expect(geocodeNameMatchesQuery('Berlingen', 'Berlin'), isFalse);
    expect(geocodeNameMatchesQuery('Berlin', 'Berlin'), isTrue);
  });

  test('Hauptbahnhof query ranks the station over the city', () {
    final frankfurt = rankGeocodeHits('Hauptbahnhof Frankfurt', const [
      GeocodeHit(
        label: 'Frankfurt, Hessen, Deutschland',
        lat: 50.11,
        lng: 8.68,
        kind: 'city',
        name: 'Frankfurt',
      ),
      GeocodeHit(
        label: 'Frankfurt Hauptbahnhof, Frankfurt, Deutschland',
        lat: 50.107,
        lng: 8.664,
        kind: 'station',
        name: 'Frankfurt Hauptbahnhof',
      ),
    ]);
    expect(frankfurt.first.kind, 'station');

    final wiesloch = rankGeocodeHits('Hauptbahnhof Wiesloch', const [
      GeocodeHit(
        label: 'Wiesloch, Baden-Württemberg, Deutschland',
        lat: 49.295,
        lng: 8.698,
        kind: 'city',
        name: 'Wiesloch',
      ),
      GeocodeHit(
        label: 'Wiesloch-Walldorf Bahnhof, Wiesloch, Deutschland',
        lat: 49.291,
        lng: 8.664,
        kind: 'station',
        name: 'Wiesloch-Walldorf Bahnhof',
      ),
    ]);
    expect(wiesloch.first.kind, 'station');

    final photonHouse = rankGeocodeHits('Hauptbahnhof Frankfurt', const [
      GeocodeHit(
        label: 'Hauptbahnhof Frankfurt (Oder), Frankfurt (Oder), Deutschland',
        lat: 52.336,
        lng: 14.546,
        kind: 'house',
        name: 'Hauptbahnhof Frankfurt (Oder)',
      ),
      GeocodeHit(
        label: 'Frankfurt (Main) Hauptbahnhof, Frankfurt am Main, Deutschland',
        lat: 50.107,
        lng: 8.664,
        kind: 'house',
        name: 'Frankfurt (Main) Hauptbahnhof',
      ),
    ]);
    expect(photonHouse.first.label, contains('Main'));

    final city = rankGeocodeHits('Frankfurt', const [
      GeocodeHit(
        label: 'Frankfurt Hauptbahnhof, Frankfurt, Deutschland',
        lat: 50.107,
        lng: 8.664,
        kind: 'station',
        name: 'Frankfurt Hauptbahnhof',
      ),
      GeocodeHit(
        label: 'Frankfurt, Hessen, Deutschland',
        lat: 50.11,
        lng: 8.68,
        kind: 'city',
        name: 'Frankfurt',
      ),
    ]);
    expect(city.first.kind, 'city');
  });
}
