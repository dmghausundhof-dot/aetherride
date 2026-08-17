// G-SCH-03 — BikeCategory → schema template + layers.
// Keep in sync with src/lib/garage/schema/mapper.ts

import '../bike.dart';
import '../component.dart';

/// Base SVG templates under assets/garage/silhouettes/
enum BikeSchemaTemplate {
  road,
  gravel,
  mtb,
  city,
  mtbTrail,
  mtbAm,
  mtbEnduro,
  dh,
  emtb,
  urban,
  etrekking,
  cargo,
  folding,
  kids,
}

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
        BikeSchemaTemplate.mtbTrail => 'mtb_trail',
        BikeSchemaTemplate.mtbAm => 'mtb_am',
        BikeSchemaTemplate.mtbEnduro => 'mtb_enduro',
        BikeSchemaTemplate.dh => 'dh',
        BikeSchemaTemplate.emtb => 'emtb',
        BikeSchemaTemplate.urban => 'urban',
        BikeSchemaTemplate.etrekking => 'etrekking',
        BikeSchemaTemplate.cargo => 'cargo',
        BikeSchemaTemplate.folding => 'folding',
        BikeSchemaTemplate.kids => 'kids',
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
      template = BikeSchemaTemplate.urban;
    case BikeCategory.etrekking:
      template = BikeSchemaTemplate.etrekking;
    case BikeCategory.cargo:
      template = BikeSchemaTemplate.cargo;
    case BikeCategory.folding:
      template = BikeSchemaTemplate.folding;
    case BikeCategory.kids:
      template = BikeSchemaTemplate.kids;
    case BikeCategory.mtbTrail:
      template = BikeSchemaTemplate.mtbTrail;
    case BikeCategory.mtbAm:
      template = BikeSchemaTemplate.mtbAm;
    case BikeCategory.mtbEnduro:
      template = BikeSchemaTemplate.mtbEnduro;
    case BikeCategory.dh:
      template = BikeSchemaTemplate.dh;
    case BikeCategory.emtb:
      template = BikeSchemaTemplate.emtb;
    case BikeCategory.hiking:
      template = BikeSchemaTemplate.mtb;
  }

  final categoryFully = category == BikeCategory.mtbAm ||
      category == BikeCategory.mtbEnduro ||
      category == BikeCategory.dh ||
      category == BikeCategory.emtb;

  const mtbFamily = {
    BikeSchemaTemplate.mtb,
    BikeSchemaTemplate.mtbTrail,
    BikeSchemaTemplate.mtbAm,
    BikeSchemaTemplate.mtbEnduro,
    BikeSchemaTemplate.dh,
    BikeSchemaTemplate.emtb,
  };
  final showShock = mtbFamily.contains(template) && (categoryFully || hasRearShock);

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
