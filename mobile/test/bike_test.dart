import 'package:aetherride_mobile/domain/bike.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Bike copyWith behält id', () {
    const bike = Bike(
      id: 'x',
      name: 'Trail',
      category: BikeCategory.mtbAm,
    );
    final next = bike.copyWith(name: 'Enduro');
    expect(next.id, 'x');
    expect(next.name, 'Enduro');
    expect(next.category, BikeCategory.mtbAm);
  });

  test('Bike categoryLabel hält E-Untertypen mit isEbike', () {
    expect(
      const Bike(
        id: '1',
        name: 'E-City',
        category: BikeCategory.urban,
        isEbike: true,
      ).categoryLabel,
      'E-City',
    );
    expect(
      const Bike(
        id: '2',
        name: 'City',
        category: BikeCategory.urban,
      ).categoryLabel,
      'City',
    );
  });
}
