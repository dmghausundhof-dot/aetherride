import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/bike_owner.dart';
import 'package:aetherride_mobile/domain/component.dart';
import 'package:aetherride_mobile/domain/garage/die_box.dart';
import 'package:aetherride_mobile/domain/garage/werkstatt_setup.dart';
import 'package:aetherride_mobile/domain/maintenance/intervals.dart';
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

BikeComponent _part(
  String bikeId,
  ComponentSlot slot, {
  String? model,
  String? catalogModelId,
}) =>
    BikeComponent(
      id: '$bikeId-${slot.name}',
      bikeId: bikeId,
      slot: slot,
      model: model ?? slot.label,
      catalogModelId: catalogModelId,
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
  test('Ausweis chip only when Rahmennummer is set', () {
    final empty = planDieBox(
      bike: _bike(id: 'c1', name: 'City', category: BikeCategory.urban),
    );
    expect(empty.chips.map((c) => c.label), isNot(contains('Ausweis')));
    final withSerial = planDieBox(
      bike: Bike(
        id: 'c2',
        name: 'City',
        category: BikeCategory.urban,
        isActive: true,
        owner: const BikeOwner(serialNumber: 'WS-1'),
      ),
    );
    expect(withSerial.chips.map((c) => c.label), contains('Ausweis'));
  });

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
    expect(plan.chips.where((c) => !c.known), isEmpty);
    expect(plan.chips.map((c) => c.label), isNot(contains('SAG')));
    expect(plan.chips.map((c) => c.label), isNot(contains('Licht')));
    expect(plan.addableSlots, contains(ComponentSlot.light));
    expect(plan.addableSlots, isNot(contains(ComponentSlot.fork)));
    expect(plan.today.any((t) => t.id == DieBoxItemId.sagUnknown), isFalse);
    expect(plan.today.any((t) => t.id == DieBoxItemId.lightsMissing), isTrue);
    expect(plan.today.any((t) => t.id == DieBoxItemId.lockMissing), isFalse);
    expect(plan.today.any((t) => t.id == DieBoxItemId.rackMissing), isFalse);
    expect(plan.sentence.toLowerCase(), contains('wohnt hier'));
    expect(plan.sentence.toLowerCase(), isNot(contains('nicht')));
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
    expect(
        catalog.today.any((t) => t.id == DieBoxItemId.pressureUnknown), isTrue);

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
    expect(
        user.today.any((t) => t.id == DieBoxItemId.pressureUnknown), isFalse);
  });

  test('Empty honesty: no trophy sentence, no ghost fork for city', () {
    final plan = planDieBox(
      bike: _bike(id: 'c1', name: 'City', category: BikeCategory.urban),
    );
    expect(plan.sentence.toLowerCase(), isNot(contains('teile')));
    expect(plan.onBike, isEmpty);
    expect(plan.addableSlots, isNot(contains(ComponentSlot.rearShock)));
  });

  test('Lastenrad wohnt in der City-Box, ohne SAG', () {
    final plan = planDieBox(
      bike: _bike(id: 'l1', name: 'Lasten', category: BikeCategory.cargo),
    );
    expect(plan.setup.kind, WerkstattKind.urban);
    expect(plan.sentence.toLowerCase(), isNot(contains('sag')));
    expect(plan.addableSlots, contains(ComponentSlot.light));
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
    expect(plan.chips.map((c) => c.label), isNot(contains('CSC')));
  });

  test('STEPS without a wheel sensor asks to pair CSC', () {
    final plan = planDieBox(
      bike: _bike(
        id: 'e2',
        name: 'EP8',
        category: BikeCategory.emtb,
        travelF: 140,
        travelR: 140,
        ebike: true,
      ),
      cscPaired: false,
      driveNeedsWheelSensor: true,
    );
    expect(plan.today.any((t) => t.id == DieBoxItemId.pairCsc), isTrue);
    expect(
      plan.today.where((t) => t.id == DieBoxItemId.pairCsc).first.cta,
      'Koppeln',
    );
  });

  test('STEPS with CSC does not nag again', () {
    final plan = planDieBox(
      bike: _bike(
        id: 'e3',
        name: 'EP8',
        category: BikeCategory.emtb,
        travelF: 140,
        travelR: 140,
        ebike: true,
      ),
      cscPaired: true,
      driveNeedsWheelSensor: true,
    );
    expect(plan.today.any((t) => t.id == DieBoxItemId.pairCsc), isFalse);
    expect(plan.chips.map((c) => c.label), contains('CSC'));
  });

  test('Am Rad lists installed checklist parts, ghosts stay addable', () {
    final bike = _bike(
      id: 'j1',
      name: 'JAM2',
      category: BikeCategory.emtb,
      travelF: 150,
      travelR: 150,
      wheel: WheelSize.w29,
      ebike: true,
    );
    final parts = [
      _part('j1', ComponentSlot.tireFront, catalogModelId: 'cm-tire'),
      _part('j1', ComponentSlot.headset, catalogModelId: 'cm-headset'),
      _part('j1', ComponentSlot.saddle, catalogModelId: 'cm-saddle'),
      _part('j1', ComponentSlot.motor, catalogModelId: 'cm-motor'),
      _part('j1', ComponentSlot.lock, model: 'Abus'),
    ];
    final plan = planDieBox(bike: bike, components: parts);
    final slots = plan.onBike.map((c) => c.slot).toList();
    expect(slots, contains(ComponentSlot.tireFront));
    expect(slots, contains(ComponentSlot.motor));
    expect(slots, contains(ComponentSlot.lock));
    expect(slots, isNot(contains(ComponentSlot.headset)));
    expect(slots, isNot(contains(ComponentSlot.saddle)));
    expect(plan.addableSlots, contains(ComponentSlot.headset));
    expect(plan.addableSlots, contains(ComponentSlot.frontHub));
    expect(plan.addableSlots, isNot(contains(ComponentSlot.saddle)));
    expect(
      listedWorkshopParts(
        installed: parts,
        addable: plan.addableSlots,
      ).map((c) => c.id),
      plan.onBike.map((c) => c.id),
    );
    expect(plan.sentence.toLowerCase(), contains('e-antrieb'));
    expect(plan.chips.where((c) => !c.known), isEmpty);
  });

  test('Rider drivetrain stays, catalog headset dump does not', () {
    final bike = _bike(
      id: 'k1',
      name: 'Konflikt',
      category: BikeCategory.mtbTrail,
      travelF: 140,
      travelR: 140,
    );
    final parts = [
      BikeComponent(
        id: 'k1-cass',
        bikeId: 'k1',
        slot: ComponentSlot.cassette,
        manufacturer: 'SRAM',
        model: 'XO Eagle',
        installedAt: DateTime.utc(2026, 1, 1),
      ),
      BikeComponent(
        id: 'k1-hub',
        bikeId: 'k1',
        slot: ComponentSlot.rearHub,
        manufacturer: 'DT Swiss',
        model: '350',
        installedAt: DateTime.utc(2026, 1, 1),
      ),
      _part('k1', ComponentSlot.headset, catalogModelId: 'cm-headset'),
    ];
    final plan = planDieBox(bike: bike, components: parts);
    expect(
      plan.onBike.map((c) => c.slot),
      containsAll([ComponentSlot.cassette, ComponentSlot.rearHub]),
    );
    expect(plan.onBike.map((c) => c.slot), isNot(contains(ComponentSlot.headset)));
  });

  test('Heute rest does not repeat the primary', () {
    final plan = planDieBox(
      bike: _bike(
        id: 'm1',
        name: 'Luna',
        category: BikeCategory.mtbTrail,
        travelF: 140,
        travelR: 140,
      ),
    );
    expect(plan.primary, isNotNull);
    expect(
      plan.heuteRest.map((t) => t.id),
      isNot(contains(plan.primary!.id)),
    );
    expect(plan.sentence.toLowerCase(), isNot(contains('nicht gemessen')));
    expect(plan.sentence.toLowerCase(), isNot(contains('offen')));
  });

  test('Paired CSC is a known chip, unpaired is not', () {
    final bike = _bike(
      id: 'e1',
      name: 'Cargo',
      category: BikeCategory.etrekking,
      ebike: true,
    );
    expect(
      planDieBox(bike: bike, cscPaired: false).chips.map((c) => c.label),
      isNot(contains('CSC')),
    );
    expect(
      planDieBox(bike: bike, cscPaired: true).chips.map((c) => c.label),
      contains('CSC'),
    );
  });

  test('tafelCareItem ignores Die-Box Heute, only due care', () {
    final bike = _bike(
      id: 'r1',
      name: 'Aeroad',
      category: BikeCategory.road,
      wheel: WheelSize.c700,
    );
    final plan = planDieBox(
      bike: bike,
      components: [
        _part('r1', ComponentSlot.chain),
      ],
    );
    expect(plan.today, isNotEmpty);
    expect(
      listDueMaintenance(bike: bike, components: [
        _part('r1', ComponentSlot.chain),
      ]),
      isEmpty,
    );
    expect(tafelCareItem(plan), isNull);
  });

  test('defaultSetupValuesFor never seeds Fox clicks or psi', () {
    final road = planWerkstattSetup(
      bike: _bike(
        id: 'r1',
        name: 'Aero',
        category: BikeCategory.road,
        wheel: WheelSize.c700,
      ),
    );
    expect(defaultSetupValuesFor(road), isEmpty);

    final mtb = planWerkstattSetup(
      bike: _bike(
        id: 'm1',
        name: 'Luna',
        category: BikeCategory.mtbTrail,
        travelF: 140,
        travelR: 140,
      ),
    );
    expect(defaultSetupValuesFor(mtb), isEmpty);
    expect(
      defaultSetupValuesFor(mtb).any((v) => v.adjusterKey.contains('fork')),
      isFalse,
    );
  });

  test('Gravel with fork asks for SAG; city with typed travel does not', () {
    final gravelPlan = planDieBox(
      bike: _bike(id: 'g2', name: 'Kora', category: BikeCategory.gravel),
      components: [_part('g2', ComponentSlot.fork)],
    );
    expect(gravelPlan.setup.showsFahrwerk, isTrue);
    expect(
        gravelPlan.today.any((t) => t.id == DieBoxItemId.sagUnknown), isTrue);
    expect(gravelPlan.addableSlots, contains(ComponentSlot.fork));
    expect(gravelPlan.addableSlots, isNot(contains(ComponentSlot.rearShock)));

    final cityPlan = planDieBox(
      bike: _bike(
        id: 'c2',
        name: 'City',
        category: BikeCategory.urban,
        travelF: 80,
      ),
    );
    expect(cityPlan.setup.hasSuspension, isTrue);
    expect(cityPlan.setup.showsFahrwerk, isFalse);
    expect(cityPlan.today.any((t) => t.id == DieBoxItemId.sagUnknown), isFalse);
    expect(cityPlan.addableSlots, isNot(contains(ComponentSlot.fork)));
  });

  test('bikeHealthLine names readiness and km', () {
    expect(
      bikeHealthLine(
        readiness: DieBoxReadiness.ready,
        odometerKm: 412.4,
        readyLabel: 'Bereit',
        almostLabel: 'Fast',
        unknownLabel: 'Unklar',
      ),
      'Bereit · 412 km',
    );
  });

  test('ghostSlotsFor hides quiet fit slots and schema slots', () {
    final ghosts = ghostSlotsFor(
      addable: [
        ComponentSlot.tireFront,
        ComponentSlot.chain,
        ComponentSlot.headset,
        ComponentSlot.frontHub,
        ComponentSlot.lock,
      ],
      installed: {ComponentSlot.tireFront},
      schemaSlots: [ComponentSlot.chain],
    );
    expect(ghosts, contains(ComponentSlot.lock));
    expect(ghosts, isNot(contains(ComponentSlot.headset)));
    expect(ghosts, isNot(contains(ComponentSlot.frontHub)));
    expect(ghosts, isNot(contains(ComponentSlot.chain)));
    expect(ghosts, isNot(contains(ComponentSlot.tireFront)));
  });
}
