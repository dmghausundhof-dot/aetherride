import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/bike_assist.dart';
import 'package:aetherride_mobile/domain/catalog_bike.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BikeAssistUx', () {
    test('persistCategory keeps E subtypes (no etrekking collapse)', () {
      expect(
        BikeAssistUx.persistCategory(
          BikeCategory.emtb,
          BikeAssistMode.ebike,
        ),
        BikeCategory.emtb,
      );
      expect(
        BikeAssistUx.persistCategory(
          BikeCategory.urban,
          BikeAssistMode.ebike,
        ),
        BikeCategory.urban,
      );
      expect(
        BikeAssistUx.persistCategory(
          BikeCategory.gravel,
          BikeAssistMode.ebike,
        ),
        BikeCategory.gravel,
      );
      expect(
        BikeAssistUx.persistCategory(
          BikeCategory.road,
          BikeAssistMode.ebike,
        ),
        BikeCategory.road,
      );
      expect(
        BikeAssistUx.persistCategory(
          BikeCategory.etrekking,
          BikeAssistMode.ebike,
        ),
        BikeCategory.etrekking,
      );
      expect(
        BikeAssistUx.persistCategory(
          BikeCategory.mtbAm,
          BikeAssistMode.muscle,
        ),
        BikeCategory.mtbAm,
      );
    });

    test('persistIsEbike mirrors assist mode', () {
      expect(
        BikeAssistUx.persistIsEbike(BikeCategory.urban, BikeAssistMode.ebike),
        isTrue,
      );
      expect(
        BikeAssistUx.persistIsEbike(BikeCategory.urban, BikeAssistMode.muscle),
        isFalse,
      );
      expect(
        BikeAssistUx.persistIsEbike(BikeCategory.emtb, BikeAssistMode.muscle),
        isTrue,
      );
    });

    test('resolveCatalogPersist keeps gravel/urban + isEbike', () {
      const eTrekking = CatalogBikeVariant(
        id: 't1',
        name: 'Tour',
        year: 2024,
        category: BikeCategory.etrekking,
        frameSizeOptions: ['L'],
        wheelSizeFront: WheelSize.w29,
        wheelSizeRear: WheelSize.w29,
        isEbike: true,
        oemComponents: {},
      );
      final a = BikeAssistUx.resolveCatalogPersist(eTrekking);
      expect(a.category, BikeCategory.etrekking);
      expect(a.isEbike, isTrue);

      const gravelE = CatalogBikeVariant(
        id: 'g1',
        name: 'Gravel E',
        year: 2024,
        category: BikeCategory.gravel,
        frameSizeOptions: ['L'],
        wheelSizeFront: WheelSize.c700,
        wheelSizeRear: WheelSize.c700,
        isEbike: true,
        oemComponents: {},
      );
      final b = BikeAssistUx.resolveCatalogPersist(gravelE);
      expect(b.category, BikeCategory.gravel);
      expect(b.isEbike, isTrue);

      const cityE = CatalogBikeVariant(
        id: 'c1',
        name: 'City E',
        year: 2024,
        category: BikeCategory.urban,
        frameSizeOptions: ['M'],
        wheelSizeFront: WheelSize.c700,
        wheelSizeRear: WheelSize.c700,
        isEbike: true,
        oemComponents: {},
      );
      final c = BikeAssistUx.resolveCatalogPersist(cityE);
      expect(c.category, BikeCategory.urban);
      expect(c.isEbike, isTrue);
    });

    test('subtype labels distinguish E-City from City', () {
      expect(
        BikeAssistUx.subtypeLabel(BikeCategory.urban, BikeAssistMode.muscle),
        'City',
      );
      expect(
        BikeAssistUx.subtypeLabel(BikeCategory.urban, BikeAssistMode.ebike),
        'E-City',
      );
    });

    test('modeFor restores ebike from isEbike + muscle category', () {
      expect(
        BikeAssistUx.modeFor(
          category: BikeCategory.urban,
          isEbike: true,
        ),
        BikeAssistMode.ebike,
      );
      expect(
        BikeAssistUx.modeFor(
          category: BikeCategory.gravel,
          isEbike: true,
        ),
        BikeAssistMode.ebike,
      );
      expect(
        BikeAssistUx.modeFor(
          category: BikeCategory.road,
          isEbike: true,
        ),
        BikeAssistMode.ebike,
      );
      expect(
        BikeAssistUx.modeFor(category: BikeCategory.urban),
        BikeAssistMode.muscle,
      );
    });

    test('displayLabel restores E-City after persist', () {
      expect(
        BikeAssistUx.displayLabel(
          category: BikeCategory.urban,
          isEbike: true,
        ),
        'E-City',
      );
      expect(
        BikeAssistUx.displayLabel(
          category: BikeCategory.gravel,
          isEbike: true,
        ),
        'E-Gravel',
      );
      expect(
        BikeAssistUx.displayLabel(
          category: BikeCategory.road,
          isEbike: true,
        ),
        'E-Road',
      );
    });
  });

  group('Bike categoryLabel', () {
    test('E-City / E-Gravel / E-Road via isEbike', () {
      expect(
        const Bike(
          id: '1',
          name: 'C',
          category: BikeCategory.urban,
          isEbike: true,
        ).categoryLabel,
        'E-City',
      );
      expect(
        const Bike(
          id: '2',
          name: 'G',
          category: BikeCategory.gravel,
          isEbike: true,
        ).categoryLabel,
        'E-Gravel',
      );
      expect(
        const Bike(
          id: '3',
          name: 'R',
          category: BikeCategory.road,
          isEbike: true,
        ).categoryLabel,
        'E-Road',
      );
      expect(
        const Bike(
          id: '4',
          name: 'U',
          category: BikeCategory.urban,
        ).categoryLabel,
        'City',
      );
    });
  });
}
