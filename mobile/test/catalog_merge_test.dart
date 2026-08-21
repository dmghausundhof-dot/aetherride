import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/catalog_bike.dart';
import 'package:flutter_test/flutter_test.dart';

CatalogBikeVariant _bike(String id, String name) => CatalogBikeVariant(
      id: id,
      name: name,
      year: 2024,
      category: BikeCategory.gravel,
      frameSizeOptions: const ['M'],
      wheelSizeFront: WheelSize.w29,
      wheelSizeRear: WheelSize.w29,
      isEbike: false,
      oemComponents: const {},
    );

void main() {
  test('Canyon-IDs werden zu einem Hersteller mit allen Modellen', () {
    final merged = mergeCatalogManufacturers([
      CatalogManufacturer(
        id: 'canyon',
        name: 'Canyon',
        bikes: [_bike('canyon-grail-cf-sl-8', 'Grail CF SL 8')],
      ),
      CatalogManufacturer(
        id: 'mfr-canyon',
        name: 'Canyon',
        bikes: [_bike('canyon-spectral-cf-8', 'Spectral CF 8')],
      ),
    ]);
    expect(merged, hasLength(1));
    expect(merged.single.id, 'mfr-canyon');
    expect(merged.single.bikes.map((b) => b.id), containsAll([
      'canyon-grail-cf-sl-8',
      'canyon-spectral-cf-8',
    ]));
  });

  test('Treffer findet Grail über Herstellername wenn IDs splitten', () {
    final list = mergeCatalogManufacturers([
      CatalogManufacturer(
        id: 'canyon',
        name: 'Canyon',
        bikes: [_bike('canyon-grail-cf-sl-8', 'Grail CF SL 8')],
      ),
    ]);
    final found = findCatalogBikeInList(
      list,
      bikeId: 'canyon-grail-cf-sl-8',
      manufacturerId: 'mfr-canyon',
      manufacturerName: 'Canyon',
    );
    expect(found?.bike.name, 'Grail CF SL 8');
    expect(found?.mfr.name, 'Canyon');
  });
}
