/**
 * Workflow identify/map — npx tsx src/lib/shop/garageBikeWorkflow.test.ts
 */
import assert from "node:assert/strict";
import { identifyGarageBike } from "./garageBikeWorkflow";
import { mapGarageBikeToShopify, shopifyHandleFromBikeId } from "./garageBikeTags";

const id = "bike-stable-1";
const identified = identifyGarageBike({
  bikeId: id,
  name: "Mein Gravel",
  category: "gravel",
  isEbike: false,
  wheelSizeFront: "700c",
  components: [
    { slot: "cassette", manufacturer: "Shimano", model: "GRX 11-34" },
  ],
});
assert.equal(identified.category, "gravel");
assert.equal(identified.bikeId, id);

const mapped = mapGarageBikeToShopify(identified);
assert.ok(mapped);
assert.equal(mapped!.handle, shopifyHandleFromBikeId(id));
assert.ok(mapped!.tags.includes("category:gravel"));
assert.ok(mapped!.tags.includes("wheel:700c"));
assert.ok(mapped!.tags.includes("shift_compat:shimano"));

const again = mapGarageBikeToShopify(identified);
assert.equal(again!.handle, mapped!.handle);
assert.equal(again!.sku, mapped!.sku);
assert.deepEqual(again!.tags, mapped!.tags);

const hike = identifyGarageBike({
  bikeId: "h1",
  name: "Trailrun",
  category: "hiking",
});
assert.equal(hike.category, "hiking");
assert.equal(mapGarageBikeToShopify(hike), null);

console.log("garageBikeWorkflow.test.ts OK");
