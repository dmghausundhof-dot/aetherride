/**
 * Run: npx tsx src/lib/shop/shopifyLocale.test.ts
 */
import assert from "node:assert/strict";
import { SHOPIFY_STORE_BASE } from "@/lib/shop/catalog";
import {
  formatShopPrice,
  shopifyLanguageCode,
  shopifyLangFromSearch,
  shopifyLocalePrefix,
  withShopifyLocale,
} from "./shopifyLocale";

assert.equal(shopifyLanguageCode("de"), "DE");
assert.equal(shopifyLanguageCode("en"), "EN");
assert.equal(shopifyLanguageCode("fr"), "FR");
assert.equal(shopifyLanguageCode("it"), "IT");

assert.equal(shopifyLangFromSearch("fr-CH"), "fr");
assert.equal(shopifyLangFromSearch("en_US"), "en");
assert.equal(shopifyLangFromSearch(null), "de");
assert.equal(shopifyLangFromSearch("nl"), "de");

assert.equal(shopifyLocalePrefix("de"), "");
assert.equal(shopifyLocalePrefix("en"), "/en");
assert.equal(shopifyLocalePrefix("fr"), "/fr");
assert.equal(shopifyLocalePrefix("it"), "/it");

const home = `${SHOPIFY_STORE_BASE}/`;
assert.equal(withShopifyLocale(home, "de"), home);
assert.equal(new URL(withShopifyLocale(home, "en")).pathname, "/en/");

const product = `${SHOPIFY_STORE_BASE}/products/orbea-terra-m20`;
assert.equal(withShopifyLocale(product, "de"), product);
assert.equal(
  withShopifyLocale(product, "fr"),
  `${SHOPIFY_STORE_BASE}/fr/products/orbea-terra-m20`,
);

const already = `${SHOPIFY_STORE_BASE}/en/products/orbea-terra-m20`;
assert.equal(withShopifyLocale(already, "en"), already);
assert.equal(withShopifyLocale(already, "de"), product);
assert.equal(
  withShopifyLocale(already, "it"),
  `${SHOPIFY_STORE_BASE}/it/products/orbea-terra-m20`,
);

const parts = `${SHOPIFY_STORE_BASE}/collections/featured-parts/category-gravel+wheel-700c`;
assert.equal(
  withShopifyLocale(parts, "en"),
  `${SHOPIFY_STORE_BASE}/en/collections/featured-parts/category-gravel+wheel-700c`,
);

assert.equal(
  withShopifyLocale(
    "https://bike.shimano.com/en-EU/product/component/deorext-m8100.html",
    "fr",
  ),
  "https://bike.shimano.com/en-EU/product/component/deorext-m8100.html",
);

assert.ok(formatShopPrice(19.9, "EUR", "de").includes("€"));
assert.ok(formatShopPrice(19.9, "EUR", "fr").includes("€"));

console.log("shopifyLocale.test.ts OK");
