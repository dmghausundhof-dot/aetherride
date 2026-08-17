/**
 * Run: npx tsx src/lib/shop/shopEnabled.test.ts
 */
import assert from "node:assert/strict";
import { isShopEnabled, isShopifyCommerceEnabled } from "./shopEnabled";

const prevShop = process.env.NEXT_PUBLIC_SHOP_ENABLED;
const prevCommerce = process.env.SHOPIFY_COMMERCE_ENABLED;
const prevPublicCommerce = process.env.NEXT_PUBLIC_SHOPIFY_COMMERCE_ENABLED;

try {
  delete process.env.NEXT_PUBLIC_SHOP_ENABLED;
  delete process.env.SHOPIFY_COMMERCE_ENABLED;
  delete process.env.NEXT_PUBLIC_SHOPIFY_COMMERCE_ENABLED;

  assert.equal(
    isShopEnabled(),
    true,
    "Web /shop affiliate catalog is on by default"
  );
  assert.equal(
    isShopifyCommerceEnabled(),
    false,
    "Shopify checkout stays off without env"
  );

  process.env.NEXT_PUBLIC_SHOP_ENABLED = "false";
  assert.equal(isShopEnabled(), false);

  process.env.NEXT_PUBLIC_SHOP_ENABLED = "true";
  assert.equal(isShopEnabled(), true);

  process.env.SHOPIFY_COMMERCE_ENABLED = "true";
  assert.equal(isShopifyCommerceEnabled(), true);

  process.env.SHOPIFY_COMMERCE_ENABLED = "false";
  process.env.NEXT_PUBLIC_SHOPIFY_COMMERCE_ENABLED = "true";
  assert.equal(isShopifyCommerceEnabled(), false, "explicit server off wins");
} finally {
  if (prevShop === undefined) delete process.env.NEXT_PUBLIC_SHOP_ENABLED;
  else process.env.NEXT_PUBLIC_SHOP_ENABLED = prevShop;
  if (prevCommerce === undefined) delete process.env.SHOPIFY_COMMERCE_ENABLED;
  else process.env.SHOPIFY_COMMERCE_ENABLED = prevCommerce;
  if (prevPublicCommerce === undefined) {
    delete process.env.NEXT_PUBLIC_SHOPIFY_COMMERCE_ENABLED;
  } else {
    process.env.NEXT_PUBLIC_SHOPIFY_COMMERCE_ENABLED = prevPublicCommerce;
  }
}

console.log("shopEnabled.test.ts OK");
