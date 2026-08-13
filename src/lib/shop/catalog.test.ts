/**
 * Shop-Katalog Hilfsfunktionen — Deep-Links & Verschleiß-Slots
 * npx tsx src/lib/shop/catalog.test.ts
 */
import assert from "node:assert/strict";
import {
  FEATURED_BIKE_HANDLE_CANDIDATES,
  FEATURED_PARTS_IN_APP_HREF,
  SHOP_PRODUCTS,
  SHOPIFY_FEATURED_BIKES,
  SHOPIFY_STORE_BASE,
  getFeaturedPartsProducts,
  getFeaturedShopifyProducts,
  getShopProduct,
  getShopProductByFocus,
  isProductAffiliateUrl,
  productsForSlot,
  shopCollectionHref,
  shopHref,
  shopifyCollectionUrl,
  shopifyProductUrl,
  wearKindToShopSlot,
} from "./catalog";
import { isDeepProductUrl, merchantCtaUrl } from "./merchantLinks";

assert.ok(getShopProduct("sp-sram-xx-chain"), "Kette im Katalog");
assert.ok(getShopProduct("sp-shimano-pad-demo"), "Beläge im Katalog");
assert.ok(
  SHOP_PRODUCTS.every((p) => p.visualHint && p.sports?.length),
  "Jedes Produkt hat visualHint + sports"
);
assert.equal(SHOP_PRODUCTS.length >= 14, true, "Multi-Sport-Katalog");
assert.ok(
  SHOP_PRODUCTS.some((p) => p.sports.includes("road")),
  "Road-Produkte vorhanden"
);

assert.equal(SHOPIFY_FEATURED_BIKES.length, 5, "5 Shopify Featured Bike snapshots");
assert.equal(FEATURED_BIKE_HANDLE_CANDIDATES.length, 5);
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

// Live featured bikes only via Storefront sync (/api/shop/featured)
assert.equal(getFeaturedShopifyProducts().length, 0, "no sync-less live featured bikes");
assert.ok(
  SHOPIFY_FEATURED_BIKES.every(
    (p) =>
      p.merchantName === "AetherRide Shop" &&
      p.affiliateUrl &&
      p.affiliateUrl.includes("/products/") &&
      p.slot === "frame"
  ),
  "Featured bike snapshots have deep Shopify product URLs (probe via API)"
);
assert.ok(
  SHOP_PRODUCTS.slice(0, 5).every((p) => p.id.startsWith("sp-shopify-")),
  "Featured Shopify bikes stehen am Anfang von SHOP_PRODUCTS"
);

// Merchant/dealer links must not be bare homepages; omit when unknown
const dealerLinks = SHOP_PRODUCTS.filter(
  (p) => !p.id.startsWith("sp-shopify-")
).map((p) => p.affiliateUrl);
for (const url of dealerLinks) {
  if (!url) continue;
  assert.ok(
    isDeepProductUrl(url),
    `dealer link must be deep product/search URL: ${url}`
  );
  assert.equal(merchantCtaUrl(url), url.trim());
}
assert.equal(
  merchantCtaUrl(undefined),
  undefined,
  "unknown merchant → omit Zum Händler"
);
assert.equal(merchantCtaUrl("https://www.sram.com/"), undefined);
assert.ok(merchantCtaUrl(shopifyProductUrl("orbea-terra-m20")));

assert.equal(
  shopifyProductUrl("orbea-terra-m20"),
  `${SHOPIFY_STORE_BASE}/products/orbea-terra-m20`
);
assert.equal(
  shopifyCollectionUrl("featured-gravel"),
  `${SHOPIFY_STORE_BASE}/collections/featured-gravel`
);
assert.equal(
  shopifyCollectionUrl("featured-parts"),
  `${SHOPIFY_STORE_BASE}/collections/featured-parts`
);
// In-app sport/parts hrefs — never password-gated Online Store collections
assert.equal(shopCollectionHref("gravel"), "/shop?sport=gravel");
assert.equal(shopCollectionHref("city"), "/shop?sport=city");
assert.equal(shopCollectionHref("light-e"), "/shop?sport=light-e");
assert.equal(shopCollectionHref("urban"), "/shop?sport=city");
assert.equal(shopCollectionHref("parts"), "/shop?door=parts");

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
  "/shop?door=parts"
);
assert.equal(
  shopHref({ slot: "cassette", job: "browse" }),
  "/shop?door=parts&slot=cassette"
);
assert.equal(
  shopHref({ slot: "brake_pads_front", bike: "bike-1" }),
  "/shop?door=parts&slot=brake_pads&bike=bike-1&fit=bike"
);
assert.equal(
  shopHref({ job: "replace", bike: "bike-1", slot: "chain" }),
  "/shop?door=parts&slot=chain&bike=bike-1&fit=bike"
);
assert.equal(
  shopHref({ sport: "gravel" }),
  "/shop?sport=gravel"
);
assert.equal(
  shopHref({ focus: "orbea-terra-m20", sport: "gravel" }),
  "/shop?focus=orbea-terra-m20&sport=gravel"
);
assert.equal(shopCollectionHref("parts"), "/shop?door=parts");
assert.equal(FEATURED_PARTS_IN_APP_HREF, "/shop");

assert.ok(
  isProductAffiliateUrl(`${SHOPIFY_STORE_BASE}/products/orbea-terra-m20`),
  "Shopify product URL counts as product link"
);
assert.equal(
  isProductAffiliateUrl("https://www.bike-components.de/"),
  false,
  "dealer homepage is not a product link"
);
assert.equal(
  isProductAffiliateUrl("https://www.bike-discount.de/"),
  false,
  "dealer root is not a product link"
);
assert.ok(
  getFeaturedPartsProducts().every((p) => p.slot !== "frame"),
  "featured parts exclude complete bikes"
);
assert.ok(getFeaturedPartsProducts().length >= 8, "parts catalog non-empty");

console.log("catalog.test.ts OK", {
  products: SHOP_PRODUCTS.length,
  featuredSnapshots: SHOPIFY_FEATURED_BIKES.length,
  liveFeatured: getFeaturedShopifyProducts().length,
  candidates: FEATURED_BIKE_HANDLE_CANDIDATES.length,
  featuredPartsSeeds: getFeaturedPartsProducts().length,
});
