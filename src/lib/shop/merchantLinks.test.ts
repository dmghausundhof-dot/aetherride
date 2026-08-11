/**
 * Zum Händler — nur echte Produkt-URLs
 * npx tsx src/lib/shop/merchantLinks.test.ts
 */
import assert from "node:assert/strict";
import { isDeepProductUrl, merchantCtaUrl } from "./merchantLinks";

assert.equal(isDeepProductUrl(undefined), false);
assert.equal(isDeepProductUrl(""), false);
assert.equal(isDeepProductUrl("/shop/parts"), false);
assert.equal(isDeepProductUrl("https://www.sram.com/"), false);
assert.equal(isDeepProductUrl("https://www.fox.com/bike/"), false);
assert.equal(isDeepProductUrl("https://www.bosch-ebike.com/de/"), false);

assert.ok(
  isDeepProductUrl(
    "https://dmg-haus-und-hof-shop.myshopify.com/products/orbea-terra-m20"
  )
);
assert.ok(
  isDeepProductUrl(
    "https://www.bike-components.de/de/s/?searchterm=SRAM+XX+Eagle"
  )
);
assert.ok(
  isDeepProductUrl(
    "https://www.bike-discount.de/de/suche?searchparam=Maxxis+Assegai"
  )
);
assert.ok(
  isDeepProductUrl(
    "https://bike.shimano.com/en-EU/product/component/deorext-m8100.html"
  )
);
assert.ok(
  isDeepProductUrl("https://oneupcomponents.com/products/v3-dropper-post")
);

assert.equal(merchantCtaUrl("https://www.sram.com/de/"), undefined);
assert.equal(
  merchantCtaUrl("https://oneupcomponents.com/products/v3-dropper-post"),
  "https://oneupcomponents.com/products/v3-dropper-post"
);

console.log("merchantLinks.test.ts OK");
