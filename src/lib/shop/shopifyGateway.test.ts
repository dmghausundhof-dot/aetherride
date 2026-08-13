/**
 * Shopify gateway URLs — npx tsx src/lib/shop/shopifyGateway.test.ts
 */
import assert from "node:assert/strict";
import type { Bike } from "@/types";
import { SHOPIFY_STORE_BASE } from "./catalog";
import {
  shopifyCollectionPath,
  shopifyFitTags,
  shopifyHandleize,
  shopifyMerchUrl,
  shopifyPartsFitUrl,
} from "./shopifyGateway";

function bike(partial: Partial<Bike> & Pick<Bike, "id" | "name" | "category">): Bike {
  return {
    type: "gravel",
    isActive: true,
    isEbike: false,
    createdAt: "",
    updatedAt: "",
    components: [],
    setups: [],
    totalOdometerKm: 0,
    totalHours: 0,
    ...partial,
  };
}

assert.equal(shopifyHandleize("category:gravel"), "category-gravel");
assert.equal(shopifyHandleize("wheel:700c"), "wheel-700c");
assert.equal(shopifyHandleize("  Featured Parts  "), "featured-parts");

const grizl = bike({
  id: "grizl",
  name: "Canyon Grizl",
  category: "gravel",
  type: "gravel",
  wheelSizeFront: "700c",
  wheelSizeRear: "700c",
});

assert.deepEqual(shopifyFitTags(grizl), ["category:gravel", "wheel:700c"]);
assert.deepEqual(shopifyFitTags(grizl, "chain"), [
  "category:gravel",
  "slot:chain",
]);

assert.equal(
  shopifyCollectionPath("featured-parts", ["category:gravel", "wheel:700c"]),
  "/collections/featured-parts/category-gravel+wheel-700c"
);

assert.equal(
  shopifyPartsFitUrl(grizl),
  `${SHOPIFY_STORE_BASE}/collections/featured-parts/category-gravel+wheel-700c`
);

assert.equal(
  shopifyMerchUrl(),
  `${SHOPIFY_STORE_BASE}/collections/merchandise`
);

const hike = bike({
  id: "hike",
  name: "Wandern",
  category: "hiking",
  type: "hiking",
});
assert.deepEqual(shopifyFitTags(hike), []);

console.log("shopifyGateway.test.ts OK");
