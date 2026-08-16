/**
 * npx tsx src/lib/shop/featuredSync.test.ts
 */
import assert from "node:assert/strict";
import { toLiveFeaturedBike } from "./featuredSync";
import type { PartsProduct } from "./partsCatalog";
import type { ShopProduct } from "./catalog";

const live: PartsProduct = {
  id: "gid://shopify/Product/9",
  handle: "orbea-terra-m20",
  name: "Orbea Terra M20 Team",
  manufacturer: "Orbea",
  productType: "Bicycle",
  description: "Live Storefront",
  priceEur: 3199,
  currencyCode: "EUR",
  imageUrl: "https://cdn.shopify.com/s/files/1/live.jpg",
  availableForSale: true,
  affiliateUrl:
    "https://dmg-haus-und-hof-shop.myshopify.com/products/orbea-terra-m20",
  tags: ["sport:gravel"],
  softFit: {
    slots: [],
    calipers: [],
    shiftCompat: [],
    raw: ["sport:gravel"],
  },
  slotKey: "other",
};

const snap = {
  id: "sp-shopify-orbea-terra-m20",
  name: "Orbea Terra M20",
  description: "Snapshot, nicht rendern",
  sports: ["gravel"],
} as ShopProduct;

const bike = toLiveFeaturedBike(live, snap);
assert.equal(bike.id, "gid://shopify/Product/9");
assert.equal(bike.handle, "orbea-terra-m20");
assert.equal(bike.name, "Orbea Terra M20 Team", "Storefront-Titel, kein Snapshot");
assert.equal(bike.href, "/shop/p/orbea-terra-m20");
assert.equal(bike.merchantUrl, undefined, "Shopify ist kein Zum-Händler");
assert.ok(!bike.href.includes("sp-"));
assert.deepEqual(bike.sports, ["gravel"]);

const dealer = toLiveFeaturedBike({
  ...live,
  affiliateUrl: "https://oneupcomponents.com/products/v3-dropper-post",
});
assert.equal(
  dealer.merchantUrl,
  "https://oneupcomponents.com/products/v3-dropper-post"
);

console.log("featuredSync.test.ts OK");
