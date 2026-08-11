/**
 * Soft-fit filter contract — npx tsx src/lib/shop/softFit.test.ts
 */
import assert from "node:assert/strict";
import {
  caliperTagFromModel,
  maguraShapeFromCaliperModel,
  normalizePartsSlot,
  parseSoftFitTags,
  productMatchesSlotFilter,
  productMatchesSoftFitFilter,
  softFitContextFromBike,
  softFitVerdict,
  type SoftFitContext,
} from "./softFit";
import type { Bike } from "@/types";

assert.equal(normalizePartsSlot("brake_pads_front"), "brake_pads");
assert.equal(normalizePartsSlot("tire_rear"), "tire");
assert.equal(normalizePartsSlot("all"), "all");

assert.equal(maguraShapeFromCaliperModel("MT7"), "8");
assert.equal(maguraShapeFromCaliperModel("MT5"), "8");
assert.equal(maguraShapeFromCaliperModel("MT8"), "7");
assert.equal(maguraShapeFromCaliperModel("MT4"), "7");
assert.equal(maguraShapeFromCaliperModel("7.P Performance"), "7");
assert.equal(maguraShapeFromCaliperModel("8.P"), "8");
assert.equal(caliperTagFromModel("MT7 HC"), "mt7");

const tags = parseSoftFitTags([
  "slot:brake_pads",
  "magura_shape:8",
  "pad:shape-8",
  "caliper:mt7",
  "caliper:mt*",
]);
assert.deepEqual(tags.slots, ["brake_pads"]);
assert.equal(tags.maguraShape, "8");
assert.equal(tags.padShape, "8");
assert.ok(tags.calipers.includes("mt7"));
assert.ok(tags.calipers.includes("mt*"));

const gripTags = parseSoftFitTags(["slot:grips", "size:L", "shift_compat:shimano"]);
assert.equal(gripTags.size, "L");
assert.deepEqual(gripTags.shiftCompat, ["shimano"]);

const bikeCtx: SoftFitContext = {
  bikeId: "b1",
  bikeName: "Trail",
  maguraShape: "8",
  calipers: ["mt7"],
  size: "L",
  shiftCompat: ["sram"],
  installedSlots: ["brake_front", "grips"],
};

assert.equal(softFitVerdict(tags, bikeCtx), "passt");
assert.equal(
  softFitVerdict(parseSoftFitTags(["magura_shape:7", "slot:brake_pads"]), bikeCtx),
  "pruefen"
);
assert.equal(
  softFitVerdict(parseSoftFitTags(["slot:fluid"]), bikeCtx),
  "universal"
);

assert.equal(
  productMatchesSoftFitFilter(
    parseSoftFitTags(["magura_shape:7"]),
    bikeCtx,
    "bike"
  ),
  false
);
assert.equal(
  productMatchesSoftFitFilter(
    parseSoftFitTags(["magura_shape:7"]),
    bikeCtx,
    "all"
  ),
  true
);

assert.ok(
  productMatchesSlotFilter(tags, "Brake Pads", "brake_pads_front")
);
assert.ok(
  productMatchesSlotFilter(parseSoftFitTags(["slot:grips"]), "Grips", "grips")
);
assert.equal(
  productMatchesSlotFilter(parseSoftFitTags([]), "Misc", "brake_pads"),
  false
);
assert.ok(productMatchesSlotFilter(parseSoftFitTags([]), "Misc", "all"));

const bike = {
  id: "bike-1",
  name: "Enduro",
  category: "mtb_enduro",
  components: [
    {
      id: "c1",
      bikeId: "bike-1",
      slot: "brake_front",
      componentModelId: "cm-magura-mt7-front",
      installedAt: "2024-01-01",
    },
  ],
} as unknown as Bike;

const ctx = softFitContextFromBike(bike, (id) =>
  id === "cm-magura-mt7-front"
    ? ({
        id,
        slot: "brake_front",
        manufacturer: "Magura",
        model: "MT7",
        attributes: [],
        adjusters: [],
        torqueSpecs: [],
        source: "manufacturer_doc",
        sourceUrl: "",
        verifiedAt: "",
        verifiedBy: "",
        safetyCritical: true,
      } as never)
    : undefined
);
assert.equal(ctx.maguraShape, "8");
assert.ok(ctx.calipers.includes("mt7"));

console.log("softFit.test.ts OK");
