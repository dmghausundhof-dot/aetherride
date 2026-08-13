import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/component.dart';
import 'package:aetherride_mobile/domain/garage/die_box.dart';
import 'package:aetherride_mobile/domain/setup.dart';
import 'package:flutter_test/flutter_test.dart';

Bike _bike({
  required String id,
  required String name,
  required BikeCategory category,
  WheelSize? wheel,
  int? travelF,
  int? travelR,
  bool active = true,
  bool ebike = false,
}) =>
    Bike(
      id: id,
      name: name,
      category: category,
      wheelSize: wheel,
      travelFrontMm: travelF,
      travelRearMm: travelR,
      isActive: active,
      isEbike: ebike,
    );

BikeComponent _part(String bikeId, ComponentSlot slot, {String? model}) =>
    BikeComponent(
      id: '$bikeId-${slot.name}',
      bikeId: bikeId,
      slot: slot,
      model: model ?? slot.label,
      installedAt: DateTime.utc(2026, 1, 1),
    );

BikeSetup _setup({
  required String bikeId,
  required String createdBy,
  List<SetupValue> values = const [],
  String label = 'Basis',
  String conditions = 'general',
  bool current = true,
}) =>
    BikeSetup(
      id: '$bikeId-$createdBy',
      bikeId: bikeId,
      label: label,
      values: values,
      createdAt: DateTime.utc(2026, 1, 1),
      isCurrent: current,
      conditions: conditions,
      createdBy: createdBy,
    );

void main() {
  test('City never sees sag or travel; lights/lock/rack are first-class', () {
    final plan = planDieBox(
      bike: _bike(
        id: 'c1',
        name: 'City',
        category: BikeCategory.urban,
        wheel: WheelSize.c700,
      ),
    );
    expect(plan.setup.kind.toString(), contains('urban'));
    expect(plan.sentence.toLowerCase(), isNot(contains('sag')));
    expect(plan.chips.map((c) => c.label), isNot(contains('SAG')));
    expect(plan.chips.map((c) => c.label), containsAll(['Licht', 'Schloss', 'Träger']));
    expect(plan.addableSlots, contains(ComponentSlot.light));
    expect(plan.addableSlots, isNot(contains(ComponentSlot.fork)));
    expect(plan.today.any((t) => t.id == DieBoxItemId.sagUnknown), isFalse);
    expect(plan.today.any((t) => t.id == DieBoxItemId.lightsMissing), isTrue);
  });

  test('DH never sees lights unless the slot is installed', () {
    final bare = planDieBox(
      bike: _bike(
        id: 'd1',
        name: 'Spicy',
        category: BikeCategory.dh,
        travelF: 200,
        travelR: 200,
      ),
    );
    expect(bare.chips.map((c) => c.label), isNot(contains('Licht')));
    expect(bare.addableSlots, isNot(contains(ComponentSlot.light)));
    expect(bare.today.any((t) => t.id == DieBoxItemId.lightsMissing), isFalse);

    final withLight = planDieBox(
      bike: _bike(
        id: 'd1',
        name: 'Spicy',
        category: BikeCategory.dh,
        travelF: 200,
        travelR: 200,
      ),
      components: [_part('d1', ComponentSlot.light)],
    );
    expect(withLight.chips.map((c) => c.label), contains('Licht'));
  });

  test('Chain teach is a reminder, never a wear percent', () {
    final plan = planDieBox(
      bike: _bike(
        id: 'r1',
        name: 'Aero',
        category: BikeCategory.road,
        wheel: WheelSize.c700,
      ),
    );
    final chain = plan.today.firstWhere((t) => t.id == DieBoxItemId.chainTeach);
    expect(chain.title.toLowerCase(), contains('kette'));
    expect(chain.hint.toLowerCase(), contains('lehre'));
    expect('${chain.title}${chain.hint}', isNot(contains('%')));
  });

  test('Baseline catalog pressure is unknown; user setup counts', () {
    final bike = _bike(
      id: 'g1',
      name: 'Kora',
      category: BikeCategory.gravel,
      wheel: WheelSize.b650,
    );
    final catalog = planDieBox(
      bike: bike,
      setups: [
        _setup(
          bikeId: 'g1',
          createdBy: 'catalog',
          values: const [
            SetupValue(
              adjusterKey: 'tire_front.pressure_psi',
              valueNum: 22,
              unit: 'psi',
            ),
          ],
        ),
      ],
    );
    expect(catalog.today.any((t) => t.id == DieBoxItemId.pressureUnknown), isTrue);

    final user = planDieBox(
      bike: bike,
      setups: [
        _setup(
          bikeId: 'g1',
          createdBy: 'user',
          values: const [
            SetupValue(
              adjusterKey: 'tire_front.pressure_psi',
              valueNum: 36,
              unit: 'psi',
            ),
          ],
        ),
      ],
    );
    expect(user.today.any((t) => t.id == DieBoxItemId.pressureUnknown), isFalse);
  });

  test('Empty honesty: no trophy sentence, no ghost fork for city', () {
    final plan = planDieBox(
      bike: _bike(id: 'c1', name: 'City', category: BikeCategory.urban),
    );
    expect(plan.sentence.toLowerCase(), isNot(contains('teile')));
    expect(plan.onBike, isEmpty);
    expect(plan.addableSlots, isNot(contains(ComponentSlot.rearShock)));
  });

  test('Park vs Trail only when both setups already exist', () {
    final bike = _bike(
      id: 'm1',
      name: 'Luna',
      category: BikeCategory.mtbEnduro,
      travelF: 170,
      travelR: 170,
    );
    final one = planDieBox(
      bike: bike,
      setups: [_setup(bikeId: 'm1', createdBy: 'user', conditions: 'trail')],
    );
    expect(one.showParkTrail, isFalse);

    final both = planDieBox(
      bike: bike,
      setups: [
        _setup(
          bikeId: 'm1',
          createdBy: 'user',
          label: 'Park',
          conditions: 'bikepark',
        ),
        _setup(
          bikeId: 'm1',
          createdBy: 'user',
          label: 'Trail',
          conditions: 'trail',
          current: false,
        ),
      ],
    );
    expect(both.showParkTrail, isTrue);
  });

  test('Primary CTA is never Zum Setup', () {
    final plan = planDieBox(
      bike: _bike(
        id: 'm1',
        name: 'Luna',
        category: BikeCategory.mtbTrail,
        travelF: 140,
        travelR: 140,
      ),
    );
    expect(plan.primary?.cta, isNot('Zum Setup'));
    expect(plan.isReady, isFalse);
  });

  test('E-bike CSC pairing is not a Heute hero', () {
    final plan = planDieBox(
      bike: _bike(
        id: 'e1',
        name: 'Cargo',
        category: BikeCategory.etrekking,
        ebike: true,
      ),
      cscPaired: false,
    );
    expect(plan.today.any((t) => t.id == DieBoxItemId.pairCsc), isFalse);
    expect(plan.chips.map((c) => c.label), contains('CSC'));
  });
}
