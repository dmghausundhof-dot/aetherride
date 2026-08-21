import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/domain/tours/tour_trait.dart';

void main() {
  group('TourTrait', () {
    test('maps wire tags to rider-facing labels', () {
      expect(TourTrait.label('feierabend'), 'Abendrunde');
      expect(TourTrait.label('60min'), '~1 h');
      expect(TourTrait.label('rhein-neckar'), 'Rhein-Neckar');
      expect(TourTrait.label('wiesloch'), 'Wiesloch');
      expect(TourTrait.label('box-berg'), 'Box Berg');
    });

    test('drops catalog noise and keeps order', () {
      expect(
        TourTrait.visibleWires([
          'catalog',
          'feierabend',
          'wiesloch',
          '60min',
          'rhein-neckar',
          'OSM',
        ]),
        ['feierabend', 'wiesloch', '60min', 'rhein-neckar'],
      );
    });

    test('matches tag or name so chips can filter', () {
      expect(
        TourTrait.matches(
          tags: const ['feierabend', '60min'],
          name: 'Wiesloch Feierabend-Runde',
          wire: 'feierabend',
        ),
        isTrue,
      );
      expect(
        TourTrait.matches(
          tags: const ['gravel'],
          name: 'Wiesloch Feierabend-Runde',
          wire: 'hockenheim',
        ),
        isFalse,
      );
      expect(
        TourTrait.matches(
          tags: const [],
          name: 'Hockenheim Rheinebene',
          wire: 'hockenheim',
        ),
        isTrue,
      );
    });
  });
}
