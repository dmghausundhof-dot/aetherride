import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/bike_owner.dart';
import 'package:aetherride_mobile/domain/component.dart';
import 'package:aetherride_mobile/domain/maintenance/intervals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Kette: MTB 1000, eMTB 700, Road 1500 km prüfen', () {
    expect(
      chainCheckKm(const Bike(id: '1', name: 'm', category: BikeCategory.mtbAm)),
      1000,
    );
    expect(
      chainCheckKm(const Bike(id: '2', name: 'e', category: BikeCategory.emtb)),
      700,
    );
    expect(
      chainCheckKm(const Bike(id: '3', name: 'r', category: BikeCategory.road)),
      1500,
    );
  });

  test('ohne Inspektion und mit km: ehrlich überfällig, kein Alles-grün', () {
    const bike = Bike(
      id: 'b1',
      name: 'Alt',
      category: BikeCategory.gravel,
      odometerKm: 2400,
      hours: 40,
    );
    final due = listDueMaintenance(bike: bike, components: const []);
    expect(due.any((a) => a.neverLogged && a.status == DueStatus.overdue), isTrue);
    expect(due.any((a) => a.label.contains('Inspektion')), isTrue);
    expect(due.any((a) => a.slot == ComponentSlot.chain), isTrue);
  });

  test('letzte Inspektion vor 2 Monaten ist noch ok', () {
    const bike = Bike(
      id: 'b1',
      name: 'Frisch',
      category: BikeCategory.road,
      odometerKm: 400,
      owner: BikeOwner(lastServiceAt: '2026-06-20'),
    );
    final due = listDueMaintenance(
      bike: bike,
      components: const [],
      now: DateTime.utc(2026, 8, 19),
    );
    expect(due.any((a) => a.label.contains('Inspektion')), isFalse);
  });

  test('Inspektion in 20 Tagen ist Heute-nah', () {
    const bike = Bike(
      id: 'b1',
      name: 'Bald',
      category: BikeCategory.urban,
      owner: BikeOwner(lastServiceAt: '2025-09-10'),
    );
    final due = listDueMaintenance(
      bike: bike,
      components: const [],
      now: DateTime.utc(2026, 8, 19),
    );
    final insp = due.firstWhere((a) => a.label.contains('Inspektion'));
    expect(insp.status, DueStatus.dueSoon);
  });

  test('Bosch-Erstcheck: Kaufdatum + 300 km', () {
    const bike = Bike(
      id: 'e1',
      name: 'CX',
      category: BikeCategory.emtb,
      odometerKm: 320,
      isEbike: true,
      owner: BikeOwner(purchasedAt: '2026-07-01'),
    );
    final due = listDueMaintenance(
      bike: bike,
      components: const [],
      now: DateTime.utc(2026, 8, 19),
    );
    expect(due.any((a) => a.label.contains('Erste')), isTrue);
  });

  test('Gabel Lower-Leg 50 h bleibt, Vollservice 125 h', () {
    final t = intervalTemplatesFor(
      const Bike(id: 'm', name: 'T', category: BikeCategory.mtbAm),
    );
    expect(
      t.any((e) => e.label.contains('Lower-Leg') && e.intervalHours == 50),
      isTrue,
    );
    expect(
      t.any((e) => e.label.contains('Vollservice') && e.intervalHours == 125),
      isTrue,
    );
  });

  test('Road bekommt kein Gabel-Stundenintervall', () {
    final t = intervalTemplatesFor(
      const Bike(id: 'r', name: 'R', category: BikeCategory.road),
    );
    expect(t.any((e) => e.slot == ComponentSlot.fork), isFalse);
  });

  test('80 % Fortschritt ist Heute-nah, die Hälfte nicht', () {
    const near = Bike(
      id: 'b1',
      name: 'Nah',
      category: BikeCategory.gravel,
      odometerKm: 980,
      owner: BikeOwner(lastServiceAt: '2026-07-01'),
    );
    const mid = Bike(
      id: 'b2',
      name: 'Mitte',
      category: BikeCategory.gravel,
      odometerKm: 600,
      owner: BikeOwner(lastServiceAt: '2026-07-01'),
    );
    final soon = listDueMaintenance(bike: near, components: const []);
    final later = listDueMaintenance(bike: mid, components: const []);
    expect(soon.any((a) => a.slot == ComponentSlot.chain), isTrue);
    expect(
      soon.firstWhere((a) => a.slot == ComponentSlot.chain).status,
      DueStatus.dueSoon,
    );
    expect(later.any((a) => a.slot == ComponentSlot.chain), isFalse);
  });

  test('Alles-grün nur jung oder mit gemerkter Inspektion', () {
    const young = Bike(
      id: 'y',
      name: 'Neu',
      category: BikeCategory.urban,
      odometerKm: 40,
    );
    const used = Bike(
      id: 'u',
      name: 'Alt',
      category: BikeCategory.gravel,
      odometerKm: 2400,
      hours: 40,
    );
    const inspected = Bike(
      id: 'i',
      name: 'Check',
      category: BikeCategory.road,
      odometerKm: 2400,
      owner: BikeOwner(lastServiceAt: '2026-07-01'),
    );
    expect(maintenanceEmptyIsHonestOk(bike: young), isTrue);
    expect(maintenanceEmptyIsHonestOk(bike: used), isFalse);
    expect(maintenanceEmptyIsHonestOk(bike: inspected), isTrue);
  });

  test('nächste Schwelle erscheint im Wartung-Tab (includeUpcoming)', () {
    const bike = Bike(
      id: 'b1',
      name: 'Halb',
      category: BikeCategory.gravel,
      odometerKm: 800,
      owner: BikeOwner(lastServiceAt: '2026-07-01'),
    );
    final soon = listDueMaintenance(bike: bike, components: const []);
    final next = listDueMaintenance(
      bike: bike,
      components: const [],
      includeUpcoming: true,
    );
    expect(soon.any((a) => a.slot == ComponentSlot.chain), isFalse);
    expect(next.any((a) => a.slot == ComponentSlot.chain), isTrue);
    expect(
      next.firstWhere((a) => a.slot == ComponentSlot.chain).remainingLabel,
      contains('km'),
    );
  });

  test('Log setzt Ketten-Zähler zurück', () {
    const bike = Bike(
      id: 'b1',
      name: 'T',
      category: BikeCategory.mtbAm,
      odometerKm: 2500,
    );
    final due = listDueMaintenance(
      bike: bike,
      components: const [],
      logs: [
        {
          'bikeId': 'b1',
          'date': '2026-08-01',
          'activity': 'Kette gemessen',
          'odometerKm': 2400,
        },
      ],
    );
    expect(due.any((a) => a.slot == ComponentSlot.chain), isFalse);
  });

  test('Log setzt Kette auch mit verbautem Teil zurück', () {
    const bike = Bike(
      id: 'b1',
      name: 'T',
      category: BikeCategory.mtbAm,
      odometerKm: 2500,
    );
    final chain = BikeComponent(
      id: 'c1',
      bikeId: 'b1',
      slot: ComponentSlot.chain,
      model: 'XX1',
      installedAt: DateTime.utc(2025, 1, 1),
    );
    final due = listDueMaintenance(
      bike: bike,
      components: [chain],
      logs: [
        {
          'bikeId': 'b1',
          'date': '2026-08-01',
          'activity': 'Kette gemessen',
          'odometerKm': 2400,
        },
      ],
    );
    expect(due.any((a) => a.slot == ComponentSlot.chain), isFalse);
  });

  test('Erledigt ohne Stunden lässt Gabel überfällig', () {
    const bike = Bike(
      id: 'm1',
      name: 'Trail',
      category: BikeCategory.mtbAm,
      hours: 80,
      travelFrontMm: 140,
    );
    final fork = BikeComponent(
      id: 'f1',
      bikeId: 'm1',
      slot: ComponentSlot.fork,
      model: 'Pike',
      installedAt: DateTime.utc(2025, 1, 1),
    );
    final stillDue = listDueMaintenance(
      bike: bike,
      components: [fork],
      logs: [
        {
          'bikeId': 'm1',
          'date': '2026-08-01',
          'activity': 'Gabel Lower-Leg Service',
          'odometerKm': 1200,
        },
      ],
    );
    expect(
      stillDue.any((a) => a.label.contains('Lower-Leg')),
      isTrue,
    );
    final reset = listDueMaintenance(
      bike: bike,
      components: [fork],
      logs: [
        {
          'bikeId': 'm1',
          'date': '2026-08-01',
          'activity': 'Gabel Lower-Leg Service',
          'odometerKm': 1200,
          'hours': 80,
        },
      ],
    );
    expect(reset.any((a) => a.label.contains('Lower-Leg')), isFalse);
  });
}
