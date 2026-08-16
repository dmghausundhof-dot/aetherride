/**
 * npx tsx src/lib/shop/listingRedirect.test.ts
 */
import assert from "node:assert/strict";
import { shopListingHref } from "./listingRedirect";

assert.equal(shopListingHref({}), "/shop?door=parts");
assert.equal(
  shopListingHref({ bike: "b1", fit: "bike", slot: "chain" }),
  "/shop?door=parts&bike=b1&fit=bike&slot=chain"
);
assert.equal(
  shopListingHref({ door: "merch", bike: ["x", "y"] }),
  "/shop?door=parts"
);

console.log("listingRedirect.test.ts OK");
