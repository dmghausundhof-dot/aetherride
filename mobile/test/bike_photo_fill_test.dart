import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/bike_owner.dart';
import 'package:aetherride_mobile/domain/catalog_bike.dart';
import 'package:aetherride_mobile/domain/component.dart';
import 'package:aetherride_mobile/domain/garage/bike_photo_fill.dart';
import 'package:flutter_test/flutter_test.dart';

CatalogBikeVariant _canyon() => const CatalogBikeVariant(
      id: 'canyon-spectral-125',
      name: 'Spectral 125 CF',
      year: 2025,
      category: BikeCategory.mtbAm,
      frameSizeOptions: ['M'],
      wheelSizeFront: WheelSize.w29,
      wheelSizeRear: WheelSize.w29,
      isEbike: false,
      oemComponents: {'fork': 'fox-34', 'chain': 'sram-gx'},
      travelFrontMm: 140,
      travelRearMm: 125,
    );

void main() {
  test('füllt nur leere Specs, lässt gesetzte Werte und Zähler', () {
    const bike = Bike(
      id: 'b1',
      name: 'Mein Spectral',
      category: BikeCategory.urban,
      brand: 'SchonDa',
      odometerKm: 420,
      hours: 12,
      owner: BikeOwner(serialNumber: 'SN-1', color: 'grün'),
    );
    final fill = fillEmptyBikeFromCatalog(
      bike: bike,
      manufacturerName: 'Canyon',
      catalog: _canyon(),
    );
    expect(fill.bike.brand, 'SchonDa');
    expect(fill.bike.model, 'Spectral 125 CF');
    expect(fill.bike.year, 2025);
    expect(fill.bike.travelFrontMm, 140);
    expect(fill.bike.category, BikeCategory.urban);
    expect(fill.bike.odometerKm, 420);
    expect(fill.bike.hours, 12);
    expect(fill.bike.owner.serialNumber, 'SN-1');
    expect(fill.bike.owner.color, 'grün');
    expect(fill.filled, isNot(contains('Marke')));
    expect(fill.filled, contains('Modell'));
  });

  test('Platzhalter-Name und Default-Laufrad werden ergänzt', () {
    const bike = Bike(
      id: 'b1',
      name: 'City',
      category: BikeCategory.urban,
      wheelSize: WheelSize.c700,
    );
    final fill = fillEmptyBikeFromCatalog(
      bike: bike,
      manufacturerName: 'Canyon',
      catalog: _canyon(),
    );
    expect(fill.bike.name, 'Canyon Spectral 125 CF');
    expect(fill.bike.wheelSize, WheelSize.w29);
    expect(fill.bike.frameSize, 'M');
    expect(fill.oemSlots, isNotEmpty);
  });

  test('erfindet keine Rahmennummer und keinen Federweg 0', () {
    const bike = Bike(
      id: 'b1',
      name: 'Road',
      category: BikeCategory.road,
    );
    final fill = fillEmptyBikeFromCatalog(
      bike: bike,
      manufacturerName: 'Canyon',
      catalog: const CatalogBikeVariant(
        id: 'endurace',
        name: 'Endurace',
        year: 2024,
        category: BikeCategory.road,
        frameSizeOptions: ['S', 'M', 'L'],
        wheelSizeFront: WheelSize.c700,
        wheelSizeRear: WheelSize.c700,
        isEbike: false,
        oemComponents: {},
        travelFrontMm: 0,
      ),
    );
    expect(fill.bike.owner.serialNumber, isNull);
    expect(fill.bike.travelFrontMm, isNull);
    expect(fill.bike.frameSize, isNull);
  });

  test('Grok-Wert ohne Katalog-ID bleibt rider-typed', () {
    final list = oemSuggestionsFromMap(
      const {},
      vision: const [
        OemPartSuggestion(
          slot: ComponentSlot.fork,
          manufacturer: 'Fox',
          model: '36 Grip2',
          source: OemPartSource.vision,
        ),
      ],
    );
    expect(list, hasLength(1));
    expect(list.first.catalogModelId, isNull);
    expect(list.first.isGrokOnly, isTrue);
    expect(list.first.canInstall, isTrue);
    expect(list.first.title, 'Fox 36 Grip2');
    expect(list.first.sourceLabel, 'Von Grok, nicht im Katalog');
  });

  test('Katalog-OEM und Grok-only stehen gemischt in einer Liste', () {
    final list = oemSuggestionsFromMap(
      const {'chain': 'sram-gx'},
      vision: const [
        OemPartSuggestion(
          slot: ComponentSlot.fork,
          manufacturer: 'Fox',
          model: '36 Grip2',
          source: OemPartSource.vision,
        ),
      ],
    );
    expect(list, hasLength(2));
    final grok = list.firstWhere((s) => s.slot == ComponentSlot.fork);
    final oem = list.firstWhere((s) => s.slot == ComponentSlot.chain);
    expect(grok.catalogModelId, isNull);
    expect(grok.isGrokOnly, isTrue);
    expect(oem.catalogModelId, 'sram-gx');
    expect(oem.isGrokOnly, isFalse);
  });

  test('unbekannter Vision-Slot verwirft den Grok-Wert nicht', () {
    final list = visionPartsFromIdentify(const [
      CatalogVisionPart(
        slotApiId: 'mystery_gizmo',
        manufacturer: 'SRAM',
        model: 'GX Eagle',
      ),
    ]);
    expect(list, hasLength(1));
    expect(list.first.slot, ComponentSlot.other);
    expect(list.first.catalogModelId, isNull);
    expect(list.first.title, 'SRAM GX Eagle');
  });

  test('Teile ohne Queries halten den Identify-Flow offen', () {
    const result = CatalogIdentifyResult(
      reason: 'no_catalog',
      queries: [],
      visionParts: [
        CatalogVisionPart(
          slotApiId: 'fork',
          manufacturer: 'Fox',
          model: '36 Grip2',
        ),
      ],
    );
    expect(result.hasHits, isFalse);
    expect(result.queries, isEmpty);
    expect(result.visionParts, isNotEmpty);
    expect(result.canContinue, isTrue);
    expect(result.readSummary, 'Fox 36 Grip2');
  });

  test('Identify ohne Text und ohne Teile bricht nicht still ab', () {
    const result = CatalogIdentifyResult(reason: 'no_key');
    expect(result.canContinue, isFalse);
    expect(result.readSummary, isEmpty);
    expect(identifyReasonMessage(result.reason), contains('Vision-Schlüssel'));
  });

  test('Grok-Rohtext bleibt ohne Katalogtreffer sichtbar', () {
    const result = CatalogIdentifyResult(
      reason: 'no_catalog',
      queries: ['Canyon Spectral'],
      visionParts: [
        CatalogVisionPart(
          slotApiId: 'fork',
          manufacturer: 'Fox',
          model: '36 Grip2',
        ),
        CatalogVisionPart(
          slotApiId: 'rear_derailleur',
          manufacturer: 'SRAM',
          model: 'GX',
        ),
      ],
    );
    expect(result.hasHits, isFalse);
    expect(result.hasVisionRead, isTrue);
    expect(result.canContinue, isTrue);
    expect(
      result.readSummary,
      'Canyon Spectral · Fox 36 Grip2 · SRAM GX',
    );
  });

  test('Identify-JSON liefert Queries auch ohne Matches', () {
    final result = CatalogIdentifyResult.fromJson({
      'matches': [],
      'reason': 'no_catalog',
      'queries': ['Canyon Spectral', '  '],
      'parts': [
        {'slot': 'fork', 'manufacturer': 'Fox', 'model': '36 Grip2'},
      ],
    });
    expect(result.hasHits, isFalse);
    expect(result.queries, ['Canyon Spectral']);
    expect(result.readSummary, 'Canyon Spectral · Fox 36 Grip2');
  });

  test('Name aus Grok nur bei Platzhalter, keine erfundenen Specs', () {
    const placeholder = Bike(
      id: 'b1',
      name: 'City',
      category: BikeCategory.urban,
    );
    final applied = suggestNameFromGrokRead(
      bike: placeholder,
      query: 'Canyon Spectral',
    );
    expect(applied.changed, isTrue);
    expect(applied.bike.name, 'Canyon Spectral');
    expect(applied.bike.year, isNull);
    expect(applied.bike.travelFrontMm, isNull);
    expect(applied.bike.owner.serialNumber, isNull);
    expect(applied.filled, ['Name']);

    const named = Bike(
      id: 'b1',
      name: 'Mein Spectral',
      category: BikeCategory.urban,
    );
    final kept = suggestNameFromGrokRead(
      bike: named,
      query: 'Canyon Spectral',
    );
    expect(kept.changed, isFalse);
    expect(kept.bike.name, 'Mein Spectral');
  });
}
