import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/home/hof_stand.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const aeroad = Bike(
    id: 'aeroad',
    name: 'Aeroad',
    category: BikeCategory.road,
    catalogBikeId: 'canyon-aeroad',
    isActive: true,
  );
  const phantom = Bike(
    id: 'ph1',
    name: 'Mein Bike',
    category: BikeCategory.mtbAm,
  );
  const phantom2 = Bike(
    id: 'ph2',
    name: 'Mein Bike',
    category: BikeCategory.urban,
  );
  const namedOther = Bike(
    id: 'luna',
    name: 'Luna',
    category: BikeCategory.mtbTrail,
  );

  test('placeholder is only the unnamed default', () {
    expect(isUnnamedPlaceholderBike(phantom), isTrue);
    expect(isUnnamedPlaceholderBike(aeroad), isFalse);
    expect(
      isUnnamedPlaceholderBike(
        const Bike(
          id: 'x',
          name: 'Mein Bike',
          category: BikeCategory.road,
          brand: 'Canyon',
        ),
      ),
      isFalse,
    );
  });

  test('hofStandOthers hides default phantoms when resident is real', () {
    final others = hofStandOthers(
      active: aeroad,
      all: const [aeroad, phantom, phantom, phantom2, namedOther],
    );
    expect(others.map((b) => b.id), ['luna']);
  });

  test('e-assist resident label is E-MTB, not MTB', () {
    expect(
      const Bike(
        id: 'lacuba',
        name: 'Bulls Lacuba EVO 10',
        category: BikeCategory.mtbAm,
        isEbike: true,
      ).categoryLabel,
      'E-MTB',
    );
  });

  test('riddenWithLabel prefers real preferred, else active Aeroad', () {
    expect(
      riddenWithLabel(
        preferredBikeId: 'ph1',
        bikes: const [aeroad, phantom],
        active: aeroad,
      ),
      'Aeroad',
    );
    expect(
      riddenWithLabel(
        preferredBikeId: 'luna',
        bikes: const [aeroad, namedOther],
        active: aeroad,
      ),
      'Luna',
    );
    expect(
      riddenWithLabel(
        preferredBikeId: null,
        bikes: const [aeroad],
        active: aeroad,
      ),
      'Aeroad',
    );
  });
}
