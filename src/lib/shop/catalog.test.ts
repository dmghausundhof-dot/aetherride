/**
 * Shop-Katalog Hilfsfunktionen — Deep-Links & Verschleiß-Slots
 * npx tsx src/lib/shop/catalog.test.ts
 */
import assert from "node:assert/strict";
import {
  SHOP_PRODUCTS,
  SHOPIFY_FEATURED_BIKES,
  SHOPIFY_STORE_BASE,
  getFeaturedShopifyProducts,
  getShopProduct,
  getShopProductByFocus,
  productsForSlot,
  shopCollectionHref,
  shopHref,
  shopifyCollectionUrl,
  shopifyProductUrl,
  wearKindToShopSlot,
} from "./catalog";

assert.ok(getShopProduct("sp-sram-xx-chain"), "Kette im Katalog");
assert.ok(getShopProduct("sp-shimano-pad-demo"), "Beläge im Katalog");
assert.ok(
  SHOP_PRODUCTS.every(
    (p) => p.visualHint && p.affiliateUrl && p.sports?.length
  ),
  "Jedes Produkt hat visualHint + Affiliate-URL + sports"
);
assert.equal(SHOP_PRODUCTS.length >= 14, true, "Multi-Sport-Katalog");
assert.ok(
  SHOP_PRODUCTS.some((p) => p.sports.includes("road")),
  "Road-Produkte vorhanden"
);

assert.equal(SHOPIFY_FEATURED_BIKES.length, 5, "5 Shopify Featured Bikes");
assert.ok(
  SHOPIFY_FEATURED_BIKES.every(
    (p) => p.imageUrl && p.imageUrl.includes("cdn.shopify.com")
  ),
  "all 5 featured bikes have imageUrl"
);
assert.ok(
  getShopProduct("sp-shopify-orbea-terra-m20")?.imageUrl?.includes(
    "photo-1485965120184-e220f721d03e.jpg"
  )
);
assert.ok(
  getShopProduct("sp-shopify-cube-attain-gtc-race")?.imageUrl?.includes(
    "24d45399-5a57-45a2-a6ac-da88f92d7199"
  ),
  "Cube Attain has CDN imageUrl"
);
assert.equal(getFeaturedShopifyProducts().length, 5);
assert.ok(
  SHOPIFY_FEATURED_BIKES.every(
    (p) =>
      p.merchantName === "AetherRide Shop" &&
      p.affiliateUrl.startsWith(SHOPIFY_STORE_BASE) &&
      p.affiliateUrl.includes("/products/") &&
      p.slot === "frame"
  ),
  "Featured bikes: AetherRide Shop + myshopify product URLs"
);
assert.ok(
  SHOP_PRODUCTS.slice(0, 5).every((p) =>
    p.id.startsWith("sp-shopify-")
  ),
  "Featured Shopify bikes stehen am Anfang von SHOP_PRODUCTS"
);

assert.equal(
  shopifyProductUrl("orbea-terra-m20"),
  `${SHOPIFY_STORE_BASE}/products/orbea-terra-m20`
);
assert.equal(
  shopifyCollectionUrl("featured-gravel"),
  `${SHOPIFY_STORE_BASE}/collections/featured-gravel`
);
assert.equal(
  shopCollectionHref("gravel"),
  `${SHOPIFY_STORE_BASE}/collections/featured-gravel`
);
assert.equal(
  shopCollectionHref("city"),
  `${SHOPIFY_STORE_BASE}/collections/featured-light-e-city`
);
assert.equal(
  shopCollectionHref("light-e"),
  `${SHOPIFY_STORE_BASE}/collections/featured-light-e-city`
);

assert.ok(getShopProduct("sp-shopify-orbea-terra-m20"));
assert.equal(
  getShopProductByFocus("orbea-terra-m20")?.id,
  "sp-shopify-orbea-terra-m20"
);
assert.equal(
  getShopProductByFocus("sp-shopify-canyon-commuter-7-0")?.name,
  "Canyon Commuter 7.0"
);

assert.equal(wearKindToShopSlot("chain"), "chain");
assert.equal(wearKindToShopSlot("tires"), "tire_front");
assert.equal(wearKindToShopSlot("unknown"), undefined);

assert.ok(productsForSlot("chain").length >= 1);
assert.ok(
  productsForSlot("brake_pads_rear").some((p) => p.id === "sp-shimano-pad-demo")
);

assert.equal(shopHref(), "/shop");
assert.equal(
  shopHref({ productId: "sp-sram-xx-chain", job: "replace" }),
  "/shop?focus=sp-sram-xx-chain&job=replace"
);
assert.equal(
  shopHref({ slot: "cassette", job: "browse" }),
  "/shop?slot=cassette&job=browse"
);
assert.equal(
  shopHref({ sport: "gravel" }),
  "/shop?sport=gravel"
);
assert.equal(
  shopHref({ focus: "orbea-terra-m20", sport: "gravel" }),
  "/shop?focus=orbea-terra-m20&sport=gravel"
);

console.log("catalog.test.ts OK", {
  products: SHOP_PRODUCTS.length,
  featured: SHOPIFY_FEATURED_BIKES.length,
});
