/**
 * Garage-Fit — npx tsx src/lib/shop/garageFit.test.ts
 */
import assert from "node:assert/strict";
import {
  bikeMatchesConstraint,
  evaluatePartAgainstGarage,
  formatGarageFitLabel,
  inferDrivetrainTokens,
  matchGarageFit,
  normalizeWheel,
  parseGarageFitConstraint,
  profileFromBike,
  profilesFromGarage,
  type GarageBikeProfile,
  type GarageFitBikeInput,
} from "./garageFit";
import type { Bike } from "@/types";
import type { SoftFitContext } from "./softFit";

function bike(
  partial: Partial<GarageBikeProfile> & Pick<GarageBikeProfile, "id" | "name">
): GarageBikeProfile {
  return {
    category: "gravel",
    categoryLabel: "Gravel",
    wheelSizes: ["700c"],
    isEbike: false,
    drivetrain: [],
    families: ["gravel"],
    ...partial,
  };
}

const grizl = bike({
  id: "grizl",
  name: "Canyon Grizl",
  brand: "Canyon",
  model: "Grizl",
  category: "gravel",
  categoryLabel: "Gravel",
  wheelSizes: ["700c"],
  families: ["gravel"],
  drivetrain: ["shimano"],
});

const spectral = bike({
  id: "spectral",
  name: "Canyon Spectral",
  brand: "Canyon",
  model: "Spectral",
  category: "mtb_enduro",
  categoryLabel: "Enduro",
  wheelSizes: ["29"],
  families: ["mtb"],
  drivetrain: ["sram"],
});

const levo = bike({
  id: "levo",
  name: "Turbo Levo",
  brand: "Specialized",
  model: "Turbo Levo",
  category: "emtb",
  categoryLabel: "E-MTB",
  wheelSizes: ["29"],
  isEbike: true,
  families: ["mtb"],
  drivetrain: ["sram"],
});

assert.equal(normalizeWheel("700c"), "700c");
assert.equal(normalizeWheel("27_5"), "27.5");
assert.equal(normalizeWheel("650b"), "650b");
assert.equal(normalizeWheel("29"), "29");
assert.equal(normalizeWheel("20"), "20");
assert.equal(normalizeWheel("24"), "24");
assert.equal(normalizeWheel("16"), "16");
assert.equal(normalizeWheel("26"), "26");

const tire700 = parseGarageFitConstraint({
  tags: ["slot:tire", "category:gravel", "wheel:700c"],
  title: "Schwalbe G-One R 40-622",
  productType: "Tire",
  slotKey: "tire",
});
assert.deepEqual(tire700.families, ["gravel"]);
assert.ok(tire700.wheelSizes.includes("700c"));
assert.equal(bikeMatchesConstraint(grizl, tire700), true);
assert.equal(bikeMatchesConstraint(spectral, tire700), false);

const tire29 = parseGarageFitConstraint({
  tags: ["slot:tire"],
  title: "Maxxis Assegai 29×2.5 WT MaxxGrip",
  productType: "Tire",
  slotKey: "tire",
});
assert.ok(tire29.wheelSizes.includes("29"));
assert.equal(bikeMatchesConstraint(spectral, tire29), true);
assert.equal(bikeMatchesConstraint(grizl, tire29), false, "29er-Reifen ≠ 700c Gravel");

const iso622 = parseGarageFitConstraint({
  title: "Continental GP 5000 S TR 28-622",
  productType: "Tire",
  slotKey: "tire",
});
assert.ok(iso622.wheelSizes.includes("700c"));
assert.equal(bikeMatchesConstraint(grizl, iso622), true);
assert.equal(bikeMatchesConstraint(spectral, iso622), false);

const mixed = matchGarageFit(tire29, [grizl, spectral], "all");
assert.equal(mixed.kind, "match");
assert.equal(mixed.compatible, true);
assert.deepEqual(
  mixed.matchedBikes.map((b) => b.id),
  ["spectral"]
);
assert.match(mixed.label ?? "", /Spectral/);

const onlyGrizl = matchGarageFit(tire29, [grizl, spectral], "grizl");
assert.equal(onlyGrizl.kind, "mismatch");
assert.equal(onlyGrizl.compatible, false);

const unionLabel = formatGarageFitLabel([grizl]);
assert.equal(unionLabel, "passt zu Canyon Grizl · 700c · Gravel");

const fluid = parseGarageFitConstraint({
  tags: ["slot:fluid"],
  title: "Magura Royal Blood",
  productType: "Fluid",
  slotKey: "fluid",
});
assert.equal(fluid.families.length, 0);
assert.equal(fluid.ebike, "any");
const universal = matchGarageFit(fluid, [grizl, spectral], "all");
assert.equal(universal.kind, "universal");
assert.equal(universal.compatible, true);
assert.equal(universal.label, null, "kein Fake-passt-Claim ohne Constraint");

const emptyGarage = matchGarageFit(tire29, [], null);
assert.equal(emptyGarage.kind, "universal");
assert.equal(emptyGarage.compatible, true);

const battery = parseGarageFitConstraint({
  tags: ["slot:battery"],
  title: "PowerTube 800 Wh",
  productType: "Battery",
  slotKey: "battery",
});
assert.equal(battery.ebike, "only");
assert.equal(bikeMatchesConstraint(levo, battery), true);
assert.equal(bikeMatchesConstraint(spectral, battery), false);
assert.equal(bikeMatchesConstraint(grizl, battery), false);

const analogPad = parseGarageFitConstraint({
  tags: ["slot:brake_pads", "analog"],
  title: "Beläge",
  productType: "Brake Pads",
});
assert.equal(analogPad.ebike, "no");
assert.equal(bikeMatchesConstraint(spectral, analogPad), true);
assert.equal(bikeMatchesConstraint(levo, analogPad), false);

const wheelAlias = parseGarageFitConstraint({
  tags: ["wheel:650b"],
  title: "Reifen",
  productType: "Tire",
});
assert.equal(
  bikeMatchesConstraint(
    bike({
      id: "x",
      name: "Plus",
      wheelSizes: ["27.5"],
      families: ["mtb"],
      category: "mtb_am",
      categoryLabel: "All-Mountain",
    }),
    wheelAlias
  ),
  true,
  "27.5 und 650b sind dasselbe Maß"
);

assert.deepEqual(inferDrivetrainTokens("SRAM", "GX Eagle"), ["sram"]);
assert.deepEqual(inferDrivetrainTokens("Shimano", "GRX 800"), ["shimano"]);

const sramChain = parseGarageFitConstraint({
  tags: ["slot:chain", "shift_compat:sram"],
  title: "SRAM XX Eagle Chain",
  productType: "Chain",
});
assert.ok(sramChain.drivetrain.includes("sram"));
assert.equal(bikeMatchesConstraint(spectral, sramChain), true);
assert.equal(bikeMatchesConstraint(grizl, sramChain), false);

const hikingOnly = profilesFromGarage([
  {
    id: "hike",
    name: "Wandern",
    category: "hiking",
    type: "hiking",
    isActive: true,
    isEbike: false,
    createdAt: "",
    updatedAt: "",
    components: [],
    setups: [],
    totalOdometerKm: 0,
    totalHours: 0,
  } as Bike,
]);
assert.equal(hikingOnly.length, 0);

const fromBike = profileFromBike({
  id: "bike-1",
  name: "Canyon Grizl CF SL 8",
  category: "gravel",
  type: "gravel",
  catalogBikeId: undefined,
  wheelSizeFront: "700c",
  wheelSizeRear: "700c",
  isActive: true,
  isEbike: false,
  createdAt: "",
  updatedAt: "",
  components: [
    {
      id: "c1",
      bikeId: "bike-1",
      slot: "rear_derailleur",
      manufacturer: "Shimano",
      model: "GRX 820",
      installedAt: "2024-01-01",
      odometerKmAtInstall: 0,
      hoursAtInstall: 0,
      attributes: [],
      currentSettings: {},
    },
  ],
  setups: [],
  totalOdometerKm: 0,
  totalHours: 0,
} as Bike);
assert.ok(fromBike);
assert.deepEqual(fromBike!.families, ["gravel"]);
assert.deepEqual(fromBike!.wheelSizes, ["700c"]);
assert.ok(fromBike!.drivetrain.includes("shimano"));
assert.equal(fromBike!.isEbike, false);

const soft: SoftFitContext = {
  bikeId: "grizl",
  bikeName: "Canyon Grizl",
  maguraShape: "8",
  calipers: ["mt7"],
  shiftCompat: ["shimano"],
  installedSlots: ["brake_front"],
};
const inputs: GarageFitBikeInput[] = [
  { profile: grizl, softCtx: soft },
  {
    profile: spectral,
    softCtx: {
      ...soft,
      bikeId: "spectral",
      maguraShape: "7",
      calipers: ["mt4"],
      shiftCompat: ["sram"],
    },
  },
];

const magura8 = evaluatePartAgainstGarage({
  tags: ["slot:brake_pads", "magura_shape:8"],
  title: "Magura 8.P Beläge",
  productType: "Brake Pads",
  slotKey: "brake_pads",
  bikes: inputs,
  selectedBikeId: "all",
  fitMode: "bike",
});
assert.equal(magura8.visible, true, "8.P passt zu Grizl (Union)");
assert.ok(magura8.garage.matchedBikes.some((b) => b.id === "grizl"));

const magura8SpectralOnly = evaluatePartAgainstGarage({
  tags: ["slot:brake_pads", "magura_shape:8"],
  title: "Magura 8.P Beläge",
  productType: "Brake Pads",
  slotKey: "brake_pads",
  bikes: inputs,
  selectedBikeId: "spectral",
  fitMode: "bike",
});
assert.equal(magura8SpectralOnly.visible, false, "8.P passt nicht zu Spectral MT4");

const showAll = evaluatePartAgainstGarage({
  tags: ["slot:brake_pads", "magura_shape:8"],
  title: "Magura 8.P Beläge",
  productType: "Brake Pads",
  bikes: inputs,
  selectedBikeId: "spectral",
  fitMode: "all",
});
assert.equal(showAll.visible, true);

console.log("garageFit.test.ts OK");
