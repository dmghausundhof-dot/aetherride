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
}
