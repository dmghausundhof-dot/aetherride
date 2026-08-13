import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/component.dart';
import 'package:aetherride_mobile/domain/shop/garage_fit.dart';
import 'package:aetherride_mobile/domain/shop/shop_shelf.dart';
import 'package:flutter_test/flutter_test.dart';

GarageBikeProfile _bike({
  required String id,
  required String name,
  BikeCategory category = BikeCategory.gravel,
  List<String> wheelSizes = const ['700c'],
  bool isEbike = false,
  List<String> drivetrain = const [],
  List<String> families = const ['gravel'],
  String? brand,
  String? model,
  String categoryLabel = 'Gravel',
}) {
  return GarageBikeProfile(
    id: id,
    name: name,
    brand: brand,
    model: model,
    category: category,
    categoryLabel: categoryLabel,
    wheelSizes: wheelSizes,
    isEbike: isEbike,
    drivetrain: drivetrain,
    families: families,
  );
}

void main() {
  final grizl = _bike(
    id: 'grizl',
    name: 'Canyon Grizl',
    brand: 'Canyon',
    model: 'Grizl',
    drivetrain: const ['shimano'],
  );
  final spectral = _bike(
    id: 'spectral',
    name: 'Canyon Spectral',
    brand: 'Canyon',
    model: 'Spectral',
    category: BikeCategory.mtbEnduro,
    categoryLabel: 'Enduro',
    wheelSizes: const ['29'],
    families: const ['mtb'],
    drivetrain: const ['sram'],
  );
  final levo = _bike(
    id: 'levo',
    name: 'Turbo Levo',
    brand: 'Specialized',
    model: 'Turbo Levo',
    category: BikeCategory.emtb,
    categoryLabel: 'E-MTB',
    wheelSizes: const ['29'],
    isEbike: true,
    families: const ['mtb'],
    drivetrain: const ['sram'],
  );

  test('700c Gravel-Reifen passt zu Grizl, nicht zu 29er Enduro', () {
    final c = parseGarageFitConstraint(
      tags: const ['slot:tire', 'category:gravel', 'wheel:700c'],
      title: 'Schwalbe G-One R 40-622',
      productType: 'Tire',
      slotKey: 'tire',
    );
    expect(bikeMatchesConstraint(grizl, c), isTrue);
    expect(bikeMatchesConstraint(spectral, c), isFalse);
    expect(
      formatGarageFitLabel([grizl]),
      'passt zu Canyon Grizl · 700c · Gravel',
    );
  });

  test('29× Reifen aus dem Titel — Union über die Garage', () {
    final c = parseGarageFitConstraint(
      tags: const ['slot:tire'],
      title: 'Maxxis Assegai 29×2.5 WT MaxxGrip',
      productType: 'Tire',
      slotKey: 'tire',
    );
    expect(c.wheelSizes, contains('29'));
    final union = matchGarageFit(c, [grizl, spectral]);
    expect(union.kind, 'match');
    expect(union.matchedBikes.map((b) => b.id), ['spectral']);
    final onlyGrizl = matchGarageFit(
      c,
      [grizl, spectral],
      selectedBikeId: 'grizl',
    );
    expect(onlyGrizl.kind, 'mismatch');
  });

  test('leere Garage und ungetaggtes Fluid bleiben sichtbar', () {
    final fluid = parseGarageFitConstraint(
      tags: const ['slot:fluid'],
      title: 'Magura Royal Blood',
      productType: 'Fluid',
      slotKey: 'fluid',
    );
    expect(fluid.isEmpty, isTrue);
    expect(matchGarageFit(fluid, [grizl]).kind, 'universal');
    expect(matchGarageFit(fluid, [grizl]).label, isNull);
    expect(matchGarageFit(fluid, const []).compatible, isTrue);
  });

  test('Akku nur an E-Bikes, analoge Beläge nicht an E-MTB', () {
    final battery = parseGarageFitConstraint(
      tags: const ['slot:battery'],
      title: 'PowerTube 800 Wh',
      productType: 'Battery',
      slotKey: 'battery',
    );
    expect(battery.ebike, 'only');
    expect(bikeMatchesConstraint(levo, battery), isTrue);
    expect(bikeMatchesConstraint(spectral, battery), isFalse);

    final analog = parseGarageFitConstraint(
      tags: const ['slot:brake_pads', 'analog'],
      title: 'Beläge',
      productType: 'Brake Pads',
    );
    expect(analog.ebike, 'no');
    expect(bikeMatchesConstraint(spectral, analog), isTrue);
    expect(bikeMatchesConstraint(levo, analog), isFalse);
  });

  test('27.5 und 650b sind dasselbe Maß; 29 ≠ 700c', () {
    final c = parseGarageFitConstraint(tags: const ['wheel:650b'], title: 'Reifen');
    final plus = _bike(
      id: 'plus',
      name: 'Plus',
      category: BikeCategory.mtbAm,
      categoryLabel: 'MTB',
      wheelSizes: const ['27.5'],
      families: const ['mtb'],
    );
    expect(bikeMatchesConstraint(plus, c), isTrue);
    expect(normalizeWheel('27_5'), '27.5');
    expect(normalizeWheel('700c'), '700c');
  });

  test('Schaltungsfamilie aus shift_compat', () {
    final chain = parseGarageFitConstraint(
      tags: const ['slot:chain', 'shift_compat:sram'],
      title: 'SRAM XX Eagle Chain',
      productType: 'Chain',
    );
    expect(chain.drivetrain, contains('sram'));
    expect(bikeMatchesConstraint(spectral, chain), isTrue);
    expect(bikeMatchesConstraint(grizl, chain), isFalse);
  });

  test('Hiking-Bikes zählen nicht für den Teileshop', () {
    const hike = Bike(
      id: 'h',
      name: 'Wandern',
      category: BikeCategory.hiking,
    );
    expect(profileFromBike(hike), isNull);
  });

  test('profileFromBike liest Laufrad, E-Flag und Schaltung', () {
    const bike = Bike(
      id: 'bike-1',
      name: 'Canyon Grizl CF SL 8',
      category: BikeCategory.gravel,
      brand: 'Canyon',
      model: 'Grizl',
      wheelSize: WheelSize.c700,
    );
    final profile = profileFromBike(
      bike,
      components: const [
        BikeComponent(
          id: 'c1',
          bikeId: 'bike-1',
          slot: ComponentSlot.rearDerailleur,
          manufacturer: 'Shimano',
          model: 'GRX 820',
        ),
      ],
    );
    expect(profile, isNotNull);
    expect(profile!.wheelSizes, ['700c']);
    expect(profile.families, ['gravel']);
    expect(profile.drivetrain, contains('shimano'));
    expect(profile.isEbike, isFalse);
  });

  test('Soft-Fit blendet widersprüchliche Magura-Form aus', () {
    expect(
      productSoftFitOk(tags: const ['magura_shape:8'], maguraShape: '8'),
      isTrue,
    );
    expect(
      productSoftFitOk(tags: const ['magura_shape:8'], maguraShape: '7'),
      isFalse,
    );
    expect(
      productSoftFitOk(tags: const ['slot:fluid'], maguraShape: '7'),
      isTrue,
    );
  });

  test('Merch vs Teile vs Garage-Hook', () {
    expect(
      classifyShopProduct(
        tags: const ['slot:tire', 'category:gravel', 'wheel:700c'],
        productType: 'Tire',
        title: 'Schwalbe G-One',
      ),
      ShopShelf.parts,
    );
    expect(
      classifyShopProduct(
        tags: const ['merch', 'category:gravel'],
        productType: 'T-Shirt',
        title: 'Gravel Tee',
      ),
      ShopShelf.merch,
    );
    expect(
      isMerchProduct(
        tags: const ['merch'],
        productType: 'T-Shirt',
        title: 'Gravel Tee',
      ),
      isTrue,
    );
    expect(
      classifyShopProduct(
        tags: const [],
        productType: 'Cap',
        title: 'AetherRide Cap',
      ),
      ShopShelf.merch,
    );
    expect(
      classifyShopProduct(
        tags: const ['garage-bike', 'category:gravel'],
        productType: 'Garage Bike',
        handle: 'ar-garage-bike-1',
      ),
      ShopShelf.garageHook,
    );
  });
}
