// G-SCH-03 — BikeCategory → schema template + layers.
// Keep in sync with src/lib/garage/schema/mapper.ts

import '../bike.dart';
import '../component.dart';

/// Base SVG templates under assets/garage/silhouettes/
enum BikeSchemaTemplate { road, gravel, mtb, city }

class BikeSchemaPlan {
  const BikeSchemaPlan({
    required this.template,
    required this.showShock,
    required this.showEbike,
    required this.hotspotSlots,
  });

  /// null → hiking (no diamond SVG)
  final BikeSchemaTemplate? template;
  final bool showShock;
  final bool showEbike;
  final List<ComponentSlot> hotspotSlots;

  String? get assetKey => switch (template) {
        BikeSchemaTemplate.road => 'road',
        BikeSchemaTemplate.gravel => 'gravel',
        BikeSchemaTemplate.mtb => 'mtb',
        BikeSchemaTemplate.city => 'city',
        null => null,
      };
}

const _coreSlots = <ComponentSlot>[
  ComponentSlot.tireFront,
  ComponentSlot.fork,
  ComponentSlot.brakeFront,
  ComponentSlot.handlebar,
  ComponentSlot.stem,
  ComponentSlot.frame,
  ComponentSlot.seatpost,
  ComponentSlot.saddle,
  ComponentSlot.crankset,
  ComponentSlot.chain,
  ComponentSlot.cassette,
  ComponentSlot.tireRear,
  ComponentSlot.brakeRear,
];

/// Map garage category + runtime flags → drawing plan.
BikeSchemaPlan planBikeSchema({
  required BikeCategory category,
  bool isEbike = false,
  bool hasRearShock = false,
}) {
  final ebike = isEbike ||
      category == BikeCategory.emtb ||
      category == BikeCategory.etrekking;

  if (category == BikeCategory.hiking) {
    return const BikeSchemaPlan(
      template: null,
      showShock: false,
      showEbike: false,
      hotspotSlots: [
        // Hiking slots not in mobile ComponentSlot enum — skip SVG hotspots
      ],
    );
  }

  final BikeSchemaTemplate template;
  switch (category) {
    case BikeCategory.road:
      template = BikeSchemaTemplate.road;
    case BikeCategory.gravel:
      template = BikeSchemaTemplate.gravel;
    case BikeCategory.urban:
    case BikeCategory.etrekking:
      template = BikeSchemaTemplate.city;
    case BikeCategory.mtbTrail:
    case BikeCategory.mtbAm:
    case BikeCategory.mtbEnduro:
    case BikeCategory.dh:
    case BikeCategory.emtb:
    case BikeCategory.hiking:
      template = BikeSchemaTemplate.mtb;
  }

  final categoryFully = category == BikeCategory.mtbAm ||
      category == BikeCategory.mtbEnduro ||
      category == BikeCategory.dh ||
      category == BikeCategory.emtb;

  final showShock =
      template == BikeSchemaTemplate.mtb && (categoryFully || hasRearShock);

  final slots = List<ComponentSlot>.of(_coreSlots);
  if (showShock) slots.add(ComponentSlot.rearShock);
  if (ebike) {
    slots.add(ComponentSlot.motor);
    slots.add(ComponentSlot.battery);
  }

  return BikeSchemaPlan(
    template: template,
    showShock: showShock,
    showEbike: ebike,
    hotspotSlots: slots,
  );
}
