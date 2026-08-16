/**
 * npx tsx src/lib/shop/storeStatus.test.ts
 */
import assert from "node:assert/strict";
import {
  getShopStoreStatus,
  inAppProductHref,
  isOnlineStoreLocked,
  isShopifyOnlineStoreUrl,
} from "./storeStatus";

const prev = process.env.SHOPIFY_ONLINE_STORE_LOCKED;
const prevTok = process.env.SHOPIFY_STOREFRONT_ACCESS_TOKEN;

try {
  delete process.env.SHOPIFY_ONLINE_STORE_LOCKED;
  assert.equal(isOnlineStoreLocked(), true, "default locked");

  process.env.SHOPIFY_ONLINE_STORE_LOCKED = "false";
  assert.equal(isOnlineStoreLocked(), false);

  process.env.SHOPIFY_ONLINE_STORE_LOCKED = "true";
  process.env.SHOPIFY_STOREFRONT_ACCESS_TOKEN = "shpat_test";
  const status = getShopStoreStatus();
  assert.equal(status.onlineStoreLocked, true);
  assert.equal(status.storefrontApiConfigured, true);
  assert.equal(status.recommendedPath, "storefront_api_in_app");
  assert.ok(status.messageDe.includes("FlowLine"));
  assert.ok(!("password" in status));

  assert.equal(inAppProductHref("magura-8p"), "/shop/p/magura-8p");
  assert.ok(
    isShopifyOnlineStoreUrl(
      "https://dmg-haus-und-hof-shop.myshopify.com/products/x"
    )
  );
  assert.equal(isShopifyOnlineStoreUrl("/shop/p/x"), false);

  console.log("storeStatus.test.ts OK");
} finally {
  if (prev === undefined) delete process.env.SHOPIFY_ONLINE_STORE_LOCKED;
  else process.env.SHOPIFY_ONLINE_STORE_LOCKED = prev;
  if (prevTok === undefined) delete process.env.SHOPIFY_STOREFRONT_ACCESS_TOKEN;
  else process.env.SHOPIFY_STOREFRONT_ACCESS_TOKEN = prevTok;
}
