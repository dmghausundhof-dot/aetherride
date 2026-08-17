import 'package:flutter_test/flutter_test.dart';

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
}
