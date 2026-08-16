import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/garage/pressure_unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Alltag, Gravel, Rennrad merken Druck in bar', () {
    expect(pressureUsesBar(BikeCategory.urban), isTrue);
    expect(pressureUsesBar(BikeCategory.cargo), isTrue);
    expect(pressureUsesBar(BikeCategory.road), isTrue);
    expect(pressureUsesBar(BikeCategory.gravel), isTrue);
    expect(pressureUnitLabel(BikeCategory.folding), 'bar');
  });

  test('MTB merkt Druck in psi', () {
    expect(pressureUsesBar(BikeCategory.mtbAm), isFalse);
    expect(pressureUsesBar(BikeCategory.emtb), isFalse);
    expect(pressureUnitLabel(BikeCategory.dh), 'psi');
    expect(enteredPressureToPsi(22, BikeCategory.mtbAm), 22);
  });

  test('bar-Eingabe landet als psi im Speicher', () {
    final psi = enteredPressureToPsi(4.5, BikeCategory.urban);
    expect(psi, closeTo(65.3, 0.1));
    expect(psiToBar(psi), 4.5);
  });
}
