/**
 * Parts catalog mapping & filters — npx tsx src/lib/shop/partsCatalog.test.ts
 */
import assert from "node:assert/strict";
import {
  filterAndRankParts,
  mapStorefrontProduct,
  shopPartsHref,
  shopReplaceHref,
} from "./partsCatalog";
import type { ShopifyStorefrontProduct } from "./shopifyStorefront";
import type { SoftFitContext } from "./softFit";
import {
  matchGarageFit,
  parseGarageFitConstraint,
  type GarageBikeProfile,
} from "./garageFit";

const sample: ShopifyStorefrontProduct = {
  id: "gid://shopify/Product/1",
  handle: "magura-8p-pads",
  title: "Magura 8.P Beläge",
  vendor: "Magura",
  productType: "Brake Pads",
  tags: ["slot:brake_pads", "magura_shape:8", "pad:shape-8", "caliper:mt7"],
  description: "Passend zu MT5/MT7",
  availableForSale: true,
  featuredImage: {
    url: "https://cdn.shopify.com/s/files/1/test/pad.jpg",
    altText: "Beläge",
  },
  priceRange: {
    minVariantPrice: { amount: "29.90", currencyCode: "EUR" },
  },
  onlineStoreUrl: null,
};

const mapped = mapStorefrontProduct(sample);
assert.equal(mapped.name, "Magura 8.P Beläge");
assert.equal(mapped.priceEur, 29.9);
assert.equal(mapped.softFit.maguraShape, "8");
assert.ok(mapped.affiliateUrl.includes("/products/magura-8p-pads"));
assert.ok(mapped.imageUrl?.includes("cdn.shopify.com"));

const grip = mapStorefrontProduct({
  ...sample,
  id: "gid://shopify/Product/2",
  handle: "ergon-gp1-l",
  title: "Ergon GP1",
  vendor: "Ergon",
  productType: "Grips",
  tags: ["slot:grips", "size:L"],
  priceRange: { minVariantPrice: { amount: "39.95", currencyCode: "EUR" } },
});

const ctx: SoftFitContext = {
  bikeId: "b1",
  bikeName: "Trail",
  maguraShape: "8",
  calipers: ["mt7"],
  size: "L",
  shiftCompat: [],
  installedSlots: ["brake_front", "grips"],
};

const ranked = filterAndRankParts([mapped, grip], {
  slot: "brake_pads",
  fit: "bike",
  ctx,
});
assert.equal(ranked.length, 1);
assert.equal(ranked[0].product.handle, "magura-8p-pads");
assert.equal(ranked[0].verdict, "passt");
assert.match(ranked[0].chip, /passt/);

const mismatch = mapStorefrontProduct({
  ...sample,
  id: "gid://shopify/Product/3",
  handle: "magura-7p",
  title: "Magura 7.P",
  tags: ["slot:brake_pads", "magura_shape:7"],
});
const filtered = filterAndRankParts([mapped, mismatch], {
  slot: "all",
  fit: "bike",
  ctx,
});
assert.equal(filtered.length, 1);
assert.equal(filtered[0].product.handle, "magura-8p-pads");

assert.equal(shopPartsHref(), "/shop?door=parts");
assert.equal(
  shopPartsHref({ bike: "b1", fit: "bike", slot: "brake_pads" }),
  "/shop?slot=brake_pads&bike=b1&fit=bike&door=parts"
);
assert.equal(
  shopReplaceHref({ bike: "b1", slot: "chain" }),
  "/shop?slot=chain&bike=b1&fit=bike&door=parts"
);
assert.equal(
  shopReplaceHref({ bike: "b1", slot: "fork" }),
  "/shop?bike=b1&fit=bike&door=parts"
);
assert.equal(
  shopReplaceHref({ bike: "b1", slot: "tires" }),
  "/shop?bike=b1&fit=bike&door=parts"
);
assert.equal(
  shopReplaceHref({ bike: "b1", slot: "tire_front" }),
  "/shop?slot=tire&bike=b1&fit=bike&door=parts"
);

const gravelBike: GarageBikeProfile = {
  id: "grizl",
  name: "Canyon Grizl",
  brand: "Canyon",
  model: "Grizl",
  category: "gravel",
  categoryLabel: "Gravel",
  wheelSizes: ["700c"],
  isEbike: false,
  drivetrain: ["shimano"],
  families: ["gravel"],
};
const mtbBike: GarageBikeProfile = {
  id: "spectral",
  name: "Canyon Spectral",
  brand: "Canyon",
  model: "Spectral",
  category: "mtb_enduro",
  categoryLabel: "Enduro",
  wheelSizes: ["29"],
  isEbike: false,
  drivetrain: ["sram"],
  families: ["mtb"],
};

const gOne = mapStorefrontProduct({
  ...sample,
  id: "gid://shopify/Product/10",
  handle: "schwalbe-g-one",
  title: "Schwalbe G-One R 40-622",
  vendor: "Schwalbe",
  productType: "Tire",
  tags: ["slot:tire", "category:gravel", "wheel:700c"],
});
const assegai = mapStorefrontProduct({
  ...sample,
  id: "gid://shopify/Product/11",
  handle: "maxxis-assegai",
  title: "Maxxis Assegai 29×2.5",
  vendor: "Maxxis",
  productType: "Tire",
  tags: ["slot:tire", "category:mtb", "wheel:29"],
});

const emptyCtx: SoftFitContext = {
  bikeId: "grizl",
  bikeName: "Canyon Grizl",
  maguraShape: undefined,
  calipers: [],
  size: undefined,
  shiftCompat: ["shimano"],
  installedSlots: [],
};

const garageRanked = filterAndRankParts([gOne, assegai], {
  slot: "all",
  fit: "bike",
  bikes: [
    { profile: gravelBike, softCtx: emptyCtx },
    {
      profile: mtbBike,
      softCtx: { ...emptyCtx, bikeId: "spectral", shiftCompat: ["sram"] },
    },
  ],
  selectedBikeId: "all",
});
assert.equal(garageRanked.length, 2, "Union: Gravel- und MTB-Reifen je ein Treffer");
assert.ok(garageRanked.some((r) => r.product.handle === "schwalbe-g-one"));
assert.ok(garageRanked.some((r) => r.product.handle === "maxxis-assegai"));
assert.match(garageRanked.find((r) => r.product.handle === "schwalbe-g-one")?.fitLabel ?? "", /Grizl/);

const onlyGravel = filterAndRankParts([gOne, assegai], {
  slot: "all",
  fit: "bike",
  bikes: [{ profile: gravelBike, softCtx: emptyCtx }],
  selectedBikeId: "grizl",
});
assert.equal(onlyGravel.length, 1);
assert.equal(onlyGravel[0].product.handle, "schwalbe-g-one");

assert.equal(matchGarageFit(parseGarageFitConstraint({ tags: [] }), []).kind, "universal");

const merchTee = mapStorefrontProduct({
  ...sample,
  id: "gid://shopify/Product/99",
  handle: "aetherride-tee",
  title: "FlowLine Gravel Tee",
  vendor: "FlowLine",
  productType: "T-Shirt",
  tags: ["merch", "category:gravel"],
});
const mixedShelf = filterAndRankParts([gOne, merchTee], {
  slot: "all",
  fit: "bike",
  bikes: [{ profile: gravelBike, softCtx: emptyCtx }],
  selectedBikeId: "grizl",
});
assert.equal(mixedShelf.length, 1);
assert.equal(mixedShelf[0].product.handle, "schwalbe-g-one");
assert.ok(
  !mixedShelf.some((r) => r.product.handle === "aetherride-tee"),
  "Merch nicht über Garage-Fit filtern / nicht im Teile-Regal"
);

console.log("partsCatalog.test.ts OK");
