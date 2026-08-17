import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/component.dart';
import 'package:aetherride_mobile/domain/garage/werkstatt_setup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const road = Bike(
    id: 'r1',
    name: 'Aero',
    category: BikeCategory.road,
    wheelSize: WheelSize.c700,
  );
  const mtbBare = Bike(
    id: 'm1',
    name: 'Luna',
    category: BikeCategory.mtbTrail,
  );
  const mtbTravel = Bike(
    id: 'm2',
    name: 'Luna',
    category: BikeCategory.mtbTrail,
    travelFrontMm: 140,
    travelRearMm: 140,
  );
  const gravel = Bike(
    id: 'g1',
    name: 'Kora',
    category: BikeCategory.gravel,
    wheelSize: WheelSize.b650,
  );
  const urban = Bike(
    id: 'u1',
    name: 'City',
    category: BikeCategory.urban,
  );
  const emtb = Bike(
    id: 'e1',
    name: 'Volt',
    category: BikeCategory.emtb,
    isEbike: true,
    travelFrontMm: 160,
  );

  test('road bike: tires + cockpit, no suspension UI', () {
    final plan = planWerkstattSetup(bike: road);
    expect(plan.kind, WerkstattKind.road);
    expect(plan.hasSuspension, isFalse);
    expect(plan.emphasis, contains(WerkstattEmphasis.tires));
    expect(plan.emphasis, contains(WerkstattEmphasis.cockpit));
    expect(plan.emphasis, contains(WerkstattEmphasis.wheel));
    expect(plan.emphasis, isNot(contains(WerkstattEmphasis.suspension)));
    expect(plan.primaryAdjusterKey, 'tire_front.pressure_psi');
    expect(plan.wheelLabel, '700c');
    expect(
      plan.emphasisSlots,
      isNot(contains(ComponentSlot.fork)),
    );
  });

  test('MTB without travel does not invent Fahrwerk numbers', () {
    final plan = planWerkstattSetup(bike: mtbBare);
    expect(plan.hasSuspension, isFalse);
    expect(plan.emphasis, contains(WerkstattEmphasis.suspensionUnknown));
    expect(plan.emphasis, isNot(contains(WerkstattEmphasis.suspension)));
  });

  test('MTB with travel shows Fahrwerk', () {
    final plan = planWerkstattSetup(bike: mtbTravel);
    expect(plan.hasSuspension, isTrue);
    expect(plan.showsFahrwerk, isTrue);
    expect(plan.hasRearShock, isTrue);
    expect(plan.emphasis, contains(WerkstattEmphasis.suspension));
    expect(plan.primaryAdjusterKey, 'fork.rebound');
  });

  test('dropper only when the seatpost is tagged', () {
    final untagged = planWerkstattSetup(
      bike: mtbTravel,
      components: const [
        BikeComponent(
          id: 'sp',
          bikeId: 'm2',
          slot: ComponentSlot.seatpost,
          model: 'Race Face Turbine',
        ),
      ],
    );
    expect(untagged.hasDropper, isFalse);

    final tagged = planWerkstattSetup(
      bike: mtbTravel,
      components: const [
        BikeComponent(
          id: 'sp',
          bikeId: 'm2',
          slot: ComponentSlot.seatpost,
          model: 'Fox Transfer',
        ),
      ],
    );
    expect(tagged.hasDropper, isTrue);
    expect(tagged.emphasis, contains(WerkstattEmphasis.dropper));
  });

  test('gravel: 650b, bags/cockpit, no MTB shock', () {
    final plan = planWerkstattSetup(bike: gravel);
    expect(plan.kind, WerkstattKind.gravel);
    expect(plan.wheelLabel, '650b');
    expect(plan.emphasis, contains(WerkstattEmphasis.bagsCockpit));
    expect(plan.hasSuspension, isFalse);
  });

  test('urban: lights/rack, no suspension', () {
    final plan = planWerkstattSetup(bike: urban);
    expect(plan.kind, WerkstattKind.urban);
    expect(plan.emphasis, contains(WerkstattEmphasis.lightsRack));
    expect(plan.hasSuspension, isFalse);
  });

  test('eMTB: battery honesty, no invented SoC', () {
    final plan = planWerkstattSetup(bike: emtb);
    expect(plan.hasElectricAssist, isTrue);
    expect(plan.emphasis, contains(WerkstattEmphasis.batteryHonest));
    expect(plan.emphasisSlots, contains(ComponentSlot.battery));
  });

  test('fork component on gravel is real suspension, not a category guess', () {
    final plan = planWerkstattSetup(
      bike: gravel,
      components: const [
        BikeComponent(
          id: 'f',
          bikeId: 'g1',
          slot: ComponentSlot.fork,
          model: 'Fox 32 AX',
        ),
      ],
    );
    expect(plan.hasSuspension, isTrue);
    expect(plan.showsFahrwerk, isTrue);
    expect(plan.hasRearShock, isFalse);
  });

  test('city with typed travel does not show Fahrwerk UX', () {
    const cityTravel = Bike(
      id: 'u2',
      name: 'City',
      category: BikeCategory.urban,
      travelFrontMm: 80,
    );
    final plan = planWerkstattSetup(bike: cityTravel);
    expect(plan.hasSuspension, isTrue);
    expect(plan.showsFahrwerk, isFalse);
    expect(plan.emphasis, isNot(contains(WerkstattEmphasis.suspension)));
    expect(plan.primaryAdjusterKey, 'tire_front.pressure_psi');
    expect(plan.emphasisSlots, isNot(contains(ComponentSlot.fork)));
  });
}
