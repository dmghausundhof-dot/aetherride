/**
 * Zum Händler — nur echte Produkt-URLs
 * npx tsx src/lib/shop/merchantLinks.test.ts
 */
import assert from "node:assert/strict";
import {
  dealerCtaUrl,
  isDeepProductUrl,
  merchantCtaUrl,
} from "./merchantLinks";
import { trackedMerchantUrl } from "./affiliateTracking";

assert.equal(isDeepProductUrl(undefined), false);
assert.equal(isDeepProductUrl(""), false);
assert.equal(isDeepProductUrl("/shop/parts"), false);
assert.equal(isDeepProductUrl("https://www.sram.com/"), false);
assert.equal(isDeepProductUrl("https://www.fox.com/bike/"), false);
assert.equal(isDeepProductUrl("https://www.bosch-ebike.com/de/"), false);
assert.equal(isDeepProductUrl("https://www.bike24.de/"), false);
assert.equal(isDeepProductUrl("https://www.bike24.com/"), false);

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

const bike24Product = "https://www.bike24.de/p2391234.html";
const bike24Slug =
  "https://www.bike24.de/sram-xx-eagle-transmission-chain-p2391234.html";
const bike24Com = "https://www.bike24.com/p1001.html";
assert.ok(isDeepProductUrl(bike24Product), "Bike24 /p123.html");
assert.ok(isDeepProductUrl(bike24Slug), "Bike24 SEO slug + p-id");
assert.ok(isDeepProductUrl(bike24Com), "Bike24.com product");
assert.equal(merchantCtaUrl(bike24Product), bike24Product);
assert.equal(dealerCtaUrl(bike24Product), bike24Product);

assert.equal(merchantCtaUrl("https://www.sram.com/de/"), undefined);
assert.equal(
  merchantCtaUrl("https://oneupcomponents.com/products/v3-dropper-post"),
  "https://oneupcomponents.com/products/v3-dropper-post"
);
assert.equal(
  dealerCtaUrl("https://oneupcomponents.com/products/v3-dropper-post"),
  "https://oneupcomponents.com/products/v3-dropper-post"
);
assert.equal(
  dealerCtaUrl(
    "https://dmg-haus-und-hof-shop.myshopify.com/products/orbea-terra-m20"
  ),
  undefined
);

const prevPrefix = process.env.BIKE24_DEEP_LINK_PREFIX;
const prevEnabled = process.env.BIKE24_AFFILIATE_ENABLED;
try {
  delete process.env.BIKE24_DEEP_LINK_PREFIX;
  delete process.env.BIKE24_AFFILIATE_ENABLED;
  assert.equal(
    trackedMerchantUrl(bike24Product, "bike24"),
    bike24Product,
    "no prefix → raw Bike24 URL"
  );

  process.env.BIKE24_DEEP_LINK_PREFIX =
    "https://www.awin1.com/cread.php?awinmid=PLACEHOLDER&ued=";
  assert.equal(
    trackedMerchantUrl(bike24Product, "bike24"),
    `https://www.awin1.com/cread.php?awinmid=PLACEHOLDER&ued=${encodeURIComponent(bike24Product)}`
  );
  assert.equal(
    trackedMerchantUrl(
      "https://www.bike-components.de/de/s/?searchterm=SRAM",
      "bike-components"
    ),
    "https://www.bike-components.de/de/s/?searchterm=SRAM",
    "non-Bike24 stays raw"
  );

  process.env.BIKE24_AFFILIATE_ENABLED = "false";
  assert.equal(
    trackedMerchantUrl(bike24Product, "bike24"),
    bike24Product,
    "explicit off → raw"
  );
} finally {
  if (prevPrefix === undefined) delete process.env.BIKE24_DEEP_LINK_PREFIX;
  else process.env.BIKE24_DEEP_LINK_PREFIX = prevPrefix;
  if (prevEnabled === undefined) delete process.env.BIKE24_AFFILIATE_ENABLED;
  else process.env.BIKE24_AFFILIATE_ENABLED = prevEnabled;
}

console.log("merchantLinks.test.ts OK");
