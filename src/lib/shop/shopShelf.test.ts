/**
 * Shop-Regal-Klassifikation — npx tsx src/lib/shop/shopShelf.test.ts
 */
import assert from "node:assert/strict";
import {
  classifyShopProduct,
  isMerchProduct,
  isPartsProduct,
  splitShopProducts,
} from "./shopShelf";

const pad = classifyShopProduct({
  tags: ["slot:brake_pads", "magura_shape:8", "category:mtb"],
  productType: "Brake Pads",
  title: "Magura 8.P Beläge",
  handle: "magura-8p-pads",
});
assert.equal(pad.shelf, "parts");
assert.equal(
  isPartsProduct({
    tags: ["slot:brake_pads"],
    productType: "Brake Pads",
  }),
  true
);

const tee = classifyShopProduct({
  tags: ["merch"],
  productType: "T-Shirt",
  title: "FlowLine Gravel Tee",
  handle: "aetherride-gravel-tee",
});
assert.equal(tee.shelf, "merch");
assert.equal(
  isMerchProduct({
    tags: ["merch", "category:gravel"],
    productType: "T-Shirt",
    title: "Gravel Tee",
  }),
  true,
  "Merch-Tag gewinnt — T-Shirt nicht über Gravel-Fit filtern"
);

const capNoTag = classifyShopProduct({
  tags: [],
  productType: "Cap",
  title: "FlowLine Cap",
  handle: "aetherride-cap",
});
assert.equal(capNoTag.shelf, "merch");

const bottle = classifyShopProduct({
  tags: ["merchandise"],
  productType: "Bottle",
  title: "Trinkflasche",
});
assert.equal(bottle.shelf, "merch");

const merchCollection = classifyShopProduct({
  tags: [],
  productType: "Sticker",
  title: "Logo Sticker",
  collectionHandle: "merchandise",
});
assert.equal(merchCollection.shelf, "merch");

const tire = classifyShopProduct({
  tags: ["slot:tire", "category:gravel", "wheel:700c"],
  productType: "Tire",
  title: "Schwalbe G-One R",
});
assert.equal(tire.shelf, "parts");

const hook = classifyShopProduct({
  tags: ["garage-bike", "category:gravel", "wheel:700c"],
  productType: "Garage Bike",
  handle: "ar-garage-bike-1",
  title: "Canyon Grizl · Garage-Fit",
});
assert.equal(hook.shelf, "garage_hook");

const hookByHandle = classifyShopProduct({
  tags: ["category:mtb"],
  handle: "ar-garage-abc-123",
  productType: "Bicycle",
});
assert.equal(hookByHandle.shelf, "garage_hook");

const split = splitShopProducts([
  { tags: ["slot:chain", "shift_compat:sram"], productType: "Chain", handle: "chain" },
  { tags: ["merch"], productType: "T-Shirt", handle: "tee" },
  { tags: ["garage-bike"], handle: "ar-garage-x", productType: "Garage Bike" },
  { tags: ["category:gravel", "wheel:700c"], productType: "Tire", handle: "g-one" },
]);
assert.equal(split.parts.length, 2);
assert.equal(split.merch.length, 1);
assert.equal(split.other.length, 1);
assert.ok(split.parts.some((p) => p.handle === "chain"));
assert.ok(split.parts.some((p) => p.handle === "g-one"));
assert.equal(split.merch[0].handle, "tee");

console.log("shopShelf.test.ts OK");
