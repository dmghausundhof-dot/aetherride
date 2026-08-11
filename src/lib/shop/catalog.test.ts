/**
 * Shop-Katalog Hilfsfunktionen — Deep-Links & Verschleiß-Slots
 * npx tsx src/lib/shop/catalog.test.ts
 */
import assert from "node:assert/strict";
import {
  FEATURED_PARTS_IN_APP_HREF,
  SHOP_PRODUCTS,
  SHOPIFY_FEATURED_BIKES,
  SHOPIFY_STORE_BASE,
  UNPUBLISHED_FEATURED_BIKE_HANDLES,
  getFeaturedShopifyProducts,
  getShopProduct,
  getShopProductByFocus,
  isShopifyProductHandleLive,
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

assert.equal(SHOPIFY_FEATURED_BIKES.length, 5, "5 Shopify Featured Bike snapshots");
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

// Unpublished handles must not be exposed as live featured CTAs
assert.equal(getFeaturedShopifyProducts().length, 0, "no live featured bikes");
assert.ok(
  UNPUBLISHED_FEATURED_BIKE_HANDLES.every((h) => !isShopifyProductHandleLive(h))
);
assert.ok(
  SHOPIFY_FEATURED_BIKES.every(
    (p) =>
      p.merchantName === "AetherRide Shop" &&
      p.affiliateUrl === FEATURED_PARTS_IN_APP_HREF &&
      p.slot === "frame"
  ),
  "Featured bike snapshots CTA → /shop/parts (no dead myshopify product URLs)"
);
assert.ok(
  SHOP_PRODUCTS.slice(0, 5).every((p) => p.id.startsWith("sp-shopify-")),
  "Featured Shopify bikes stehen am Anfang von SHOP_PRODUCTS"
);

// Merchant/dealer links must not be bare homepages
const dealerLinks = SHOP_PRODUCTS.filter(
  (p) => !p.id.startsWith("sp-shopify-")
).map((p) => p.affiliateUrl);
for (const url of dealerLinks) {
  const u = new URL(url);
  const path = u.pathname.replace(/\/$/, "");
  assert.ok(
    path.length > 1 || u.search.length > 1,
    `dealer link must be deep, not homepage: ${url}`
  );
}

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
  "/shop/parts"
);
assert.equal(
  shopHref({ slot: "cassette", job: "browse" }),
  "/shop/parts?slot=cassette"
);
assert.equal(
  shopHref({ slot: "brake_pads_front", bike: "bike-1" }),
  "/shop/parts?slot=brake_pads&bike=bike-1&fit=bike"
);
assert.equal(
  shopHref({ sport: "gravel" }),
  "/shop?sport=gravel"
);
assert.equal(
  shopHref({ focus: "orbea-terra-m20", sport: "gravel" }),
  "/shop?focus=orbea-terra-m20&sport=gravel"
);
assert.equal(
  shopCollectionHref("parts"),
  `${SHOPIFY_STORE_BASE}/collections/featured-parts`
);

console.log("catalog.test.ts OK", {
  products: SHOP_PRODUCTS.length,
  featuredSnapshots: SHOPIFY_FEATURED_BIKES.length,
  liveFeatured: getFeaturedShopifyProducts().length,
});
