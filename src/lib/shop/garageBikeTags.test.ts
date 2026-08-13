/**
 * Bike → Shopify-Tags — npx tsx src/lib/shop/garageBikeTags.test.ts
 */
import assert from "node:assert/strict";
import {
  mapGarageBikeToShopify,
  shopifyHandleFromBikeId,
  shopifySkuFromBikeId,
  shopifyTagsFromBike,
} from "./garageBikeTags";

const gravelId = "3f1c2a8e-1111-4b2a-9c00-aaaaaaaaaaaa";
const tags = shopifyTagsFromBike({
  bikeId: gravelId,
  name: "Canyon Grizl",
  brand: "Canyon",
  model: "Grizl",
  category: "gravel",
  isEbike: false,
  wheelSizeFront: "700c",
  wheelSizeRear: "700c",
  components: [
    { slot: "rear_derailleur", manufacturer: "Shimano", model: "GRX 820" },
  ],
});

assert.ok(tags.includes("garage-bike"));
assert.ok(tags.includes("category:gravel"));
assert.ok(tags.includes("wheel:700c"));
assert.ok(tags.includes("analog"));
assert.ok(!tags.includes("ebike"));
assert.ok(tags.includes("shift_compat:shimano"));
assert.ok(!tags.some((t) => /bosch|oem|sku:/i.test(t)));
assert.deepEqual(
  tags,
  [...tags].sort(),
  "Tags deterministisch sortiert für Idempotenz"
);

const emtb = shopifyTagsFromBike({
  bikeId: "bike-2",
  name: "Turbo Levo",
  category: "emtb",
  isEbike: true,
  wheelSizeFront: "29",
  drivetrain: ["sram"],
});
assert.ok(emtb.includes("ebike"));
assert.ok(emtb.includes("category:mtb"));
assert.ok(emtb.includes("wheel:29"));
assert.ok(emtb.includes("shift_compat:sram"));
assert.ok(!emtb.includes("analog"));

const hiking = shopifyTagsFromBike({
  bikeId: "hike",
  name: "Wandern",
  category: "hiking",
});
assert.deepEqual(hiking, []);

assert.equal(
  shopifyHandleFromBikeId(gravelId),
  `ar-garage-${gravelId}`
);
assert.equal(
  shopifySkuFromBikeId(gravelId),
  `AR-GARAGE-${gravelId.toUpperCase()}`
);

const twice = shopifyHandleFromBikeId(gravelId);
assert.equal(twice, shopifyHandleFromBikeId(gravelId));

const mapped = mapGarageBikeToShopify({
  bikeId: gravelId,
  name: "Mein Gravel",
  brand: "Canyon",
  model: "Grizl",
  category: "gravel",
  wheelSizeFront: "700c",
  components: [
    { slot: "shifter", manufacturer: "Shimano", model: "GRX" },
  ],
});
assert.ok(mapped);
assert.equal(mapped!.handle, shopifyHandleFromBikeId(gravelId));
assert.equal(mapped!.sku, shopifySkuFromBikeId(gravelId));
assert.equal(mapped!.productType, "Garage Bike");
assert.match(mapped!.title, /Canyon Grizl/);
assert.match(mapped!.descriptionHtml, /kein Verkaufsartikel/i);
assert.ok(!/bosch/i.test(mapped!.descriptionHtml));
assert.equal(
  mapGarageBikeToShopify({
    bikeId: "h",
    name: "Hike",
    category: "hiking",
  }),
  null
);

console.log("garageBikeTags.test.ts OK");
