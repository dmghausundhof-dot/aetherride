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

  test('named catalog bike is resident over placeholder', () {
    expect(
      hofResidentBike(const [phantom, aeroad, namedOther])?.id,
      'aeroad',
    );
    expect(
      hofResidentBike(const [
        Bike(
          id: 'ph-active',
          name: 'Mein Bike',
          category: BikeCategory.urban,
          isActive: true,
        ),
        namedOther,
      ])?.id,
      'luna',
    );
  });

  test('only placeholders stay honest as resident', () {
    expect(hofResidentBike(const [phantom, phantom2])?.id, 'ph1');
    expect(hofResidentBike(const []), isNull);
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

  test('empty name is also an unnamed placeholder', () {
    expect(
      isUnnamedPlaceholderBike(
        const Bike(id: 'e', name: '', category: BikeCategory.urban),
      ),
      isTrue,
    );
    expect(
      isUnnamedPlaceholderBike(
        const Bike(id: 'g', name: 'Gravel', category: BikeCategory.gravel),
      ),
      isFalse,
    );
    expect(
      isUnnamedPlaceholderBike(
        const Bike(id: 'web', name: 'Mein Rad', category: BikeCategory.urban),
      ),
      isTrue,
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
