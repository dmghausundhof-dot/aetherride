import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/bike_owner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalize trims serial and rejects junk dates', () {
    final owner = BikeOwner.normalize(
      serialNumber: '  ws 1847-ktm  ',
      color: ' Graphit ',
      weightKg: '14,2',
      purchasedAt: '12.04.2023',
      purchasePriceEur: '2499',
      insurancePolicy: '',
    );
    expect(owner.serialNumber, 'ws 1847-ktm');
    expect(owner.color, 'Graphit');
    expect(owner.weightKg, 14.2);
    expect(owner.purchasedAt, '2023-04-12');
    expect(owner.purchasePriceEur, 2499);
    expect(owner.insurancePolicy, isNull);
    expect(owner.hasSerial, isTrue);
    expect(owner.isEmpty, isFalse);
  });

  test('Werkstatt und Termin überleben JSON', () {
    final owner = BikeOwner.normalize(
      workshopName: 'Radladen Hof',
      workshopPhone: '06227 1',
      nextServiceAt: '20.09.2026',
      nextServiceNote: 'Kette',
    );
    expect(owner.hasWorkshop, isTrue);
    expect(owner.hasServiceAppointment, isTrue);
    expect(owner.nextServiceAt, '2026-09-20');
    final round = BikeOwner.fromJson(owner.toJson());
    expect(round.workshopName, 'Radladen Hof');
    expect(round.nextServiceNote, 'Kette');
    expect(round.toSyncFields().containsKey('invoicePhotoPath'), isFalse);
  });

  test('Werkstatt ohne Name bleibt sichtbar', () {
    final addressOnly = BikeOwner.normalize(
      workshopAddress: 'Hauptstr. 1',
      workshopPhone: '06227 1',
    );
    expect(addressOnly.hasWorkshop, isTrue);
    expect(addressOnly.workshopLabel, 'Hauptstr. 1');
    expect(BikeOwner.normalize(workshopPhone: '06227 1').workshopLabel, '06227 1');
    expect(BikeOwner.normalize().hasWorkshop, isFalse);
  });

  test('normalize drops impossible weight and future-ancient dates', () {
    expect(BikeOwner.normalize(weightKg: 2).weightKg, isNull);
    expect(BikeOwner.normalize(weightKg: 200).weightKg, isNull);
    expect(BikeOwner.normalize(purchasedAt: '1899-01-01').purchasedAt, isNull);
    expect(BikeOwner.normalize(purchasedAt: 'nicht-ein-datum').purchasedAt, isNull);
    expect(BikeOwner.normalize().isEmpty, isTrue);
  });

  test('fromSync reads nested owner or flat web fields', () {
    final nested = BikeOwner.fromSync({
      'owner': {'serialNumber': 'ABC-1', 'color': 'rot'},
    });
    expect(nested.serialNumber, 'ABC-1');
    expect(nested.color, 'rot');

    final flat = BikeOwner.fromSync({
      'serialNumber': 'XYZ',
      'frameNumber': 'ignored-because-serial-first',
      'weightKg': 13,
    });
    expect(flat.serialNumber, 'XYZ');
    expect(flat.weightKg, 13);
  });

  test('fromJson accepts Rahmennummer aliases', () {
    final o = BikeOwner.fromJson({
      'rahmennummer': 'DE-99',
      'shop': 'Radladen',
      'policy': 'P-1',
    });
    expect(o.serialNumber, 'DE-99');
    expect(o.purchasedFrom, 'Radladen');
    expect(o.insurancePolicy, 'P-1');
  });

  test('Bike copyWith keeps owner unless replaced', () {
    const bike = Bike(
      id: 'b',
      name: 'Trail',
      category: BikeCategory.mtbAm,
      owner: BikeOwner(serialNumber: 'S1'),
    );
    expect(bike.copyWith(name: 'Enduro').owner.serialNumber, 'S1');
    expect(
      bike.copyWith(owner: const BikeOwner(serialNumber: 'S2')).owner.serialNumber,
      'S2',
    );
  });
}
