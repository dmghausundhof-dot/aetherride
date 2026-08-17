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
}
