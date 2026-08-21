import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/bike_owner.dart';
import 'package:aetherride_mobile/domain/garage/die_box.dart';
import 'package:aetherride_mobile/domain/setup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gemerkter Druck ist kein Chip mehr — die Leiste trägt die Zahl', () {
    final plan = planDieBox(
      bike: const Bike(
        id: 'g1',
        name: 'Grail',
        category: BikeCategory.gravel,
        isActive: true,
      ),
      setups: [
        BikeSetup(
          id: 's',
          bikeId: 'g1',
          label: 'Druck',
          createdAt: DateTime.utc(2026, 8, 1),
          createdBy: 'user',
          values: const [
            SetupValue(adjusterKey: 'tire_front.pressure_psi', valueNum: 26),
            SetupValue(adjusterKey: 'tire_rear.pressure_psi', valueNum: 29),
          ],
        ),
      ],
    );
    expect(plan.chips.map((c) => c.label).join(' '), isNot(contains('bar')));
    expect(plan.chips.map((c) => c.label), isNot(contains('Druck')));
  });

  test('Werkstatt bleibt Chip; km und Termin sitzen auf der Leiste', () {
    final plan = planDieBox(
      bike: Bike(
        id: 'c1',
        name: 'City',
        category: BikeCategory.urban,
        odometerKm: 120,
        hours: 8,
        owner: BikeOwner.normalize(
          nextServiceAt: '2026-08-20',
          workshopName: 'Hof',
        ),
      ),
    );
    expect(plan.chips.map((c) => c.label), isNot(contains('120 km')));
    expect(plan.chips.map((c) => c.label), isNot(contains('8.0 h')));
    expect(plan.chips.map((c) => c.label).join(' '), isNot(contains('Termin')));
    expect(plan.chips.map((c) => c.label), contains('Hof'));
  });
}
