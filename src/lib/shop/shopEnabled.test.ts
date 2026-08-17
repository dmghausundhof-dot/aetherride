/**
 * Run: npx tsx src/lib/shop/shopEnabled.test.ts
 */
import assert from "node:assert/strict";
import { isShopEnabled, isShopifyCommerceEnabled } from "./shopEnabled";

const prevShop = process.env.NEXT_PUBLIC_SHOP_ENABLED;
const prevCommerce = process.env.SHOPIFY_COMMERCE_ENABLED;
const prevPublicCommerce = process.env.NEXT_PUBLIC_SHOPIFY_COMMERCE_ENABLED;
const prevStage = process.env.NEXT_PUBLIC_APP_STAGE;

try {
  delete process.env.NEXT_PUBLIC_SHOP_ENABLED;
  delete process.env.SHOPIFY_COMMERCE_ENABLED;
  delete process.env.NEXT_PUBLIC_SHOPIFY_COMMERCE_ENABLED;
  delete process.env.NEXT_PUBLIC_APP_STAGE;

  assert.equal(
    isShopEnabled(),
    false,
    "Web /shop stays off until launch"
  );
  assert.equal(
    isShopifyCommerceEnabled(),
    false,
    "Shopify checkout stays off without env"
  );

  process.env.SHOPIFY_COMMERCE_ENABLED = "true";
  assert.equal(
    isShopifyCommerceEnabled(),
    false,
    "Shopify stays off before launch even if env is on"
  );
  delete process.env.SHOPIFY_COMMERCE_ENABLED;

  process.env.NEXT_PUBLIC_SHOP_ENABLED = "false";
  assert.equal(isShopEnabled(), false);

  process.env.NEXT_PUBLIC_SHOP_ENABLED = "true";
  assert.equal(isShopEnabled(), true);

  process.env.NEXT_PUBLIC_APP_STAGE = "launched";
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
  if (prevStage === undefined) delete process.env.NEXT_PUBLIC_APP_STAGE;
  else process.env.NEXT_PUBLIC_APP_STAGE = prevStage;
}

console.log("shopEnabled.test.ts OK");
