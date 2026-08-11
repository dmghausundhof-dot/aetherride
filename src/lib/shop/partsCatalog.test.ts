/**
 * Parts catalog mapping & filters — npx tsx src/lib/shop/partsCatalog.test.ts
 */
import assert from "node:assert/strict";
import {
  filterAndRankParts,
  mapStorefrontProduct,
  shopPartsHref,
} from "./partsCatalog";
import type { ShopifyStorefrontProduct } from "./shopifyStorefront";
import type { SoftFitContext } from "./softFit";

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

assert.equal(shopPartsHref(), "/shop/parts");
assert.equal(
  shopPartsHref({ bike: "b1", fit: "bike", slot: "brake_pads" }),
  "/shop/parts?slot=brake_pads&bike=b1&fit=bike"
);

console.log("partsCatalog.test.ts OK");
