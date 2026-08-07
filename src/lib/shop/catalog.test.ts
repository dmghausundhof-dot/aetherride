/**
 * Shop-Katalog Hilfsfunktionen — Deep-Links & Verschleiß-Slots
 * npx tsx src/lib/shop/catalog.test.ts
 */
import assert from "node:assert/strict";
import {
  SHOP_PRODUCTS,
  getShopProduct,
  productsForSlot,
  shopHref,
  wearKindToShopSlot,
} from "./catalog";

assert.ok(getShopProduct("sp-sram-xx-chain"), "Kette im Katalog");
assert.ok(getShopProduct("sp-shimano-pad-demo"), "Beläge im Katalog");
assert.ok(
  SHOP_PRODUCTS.every((p) => p.visualHint && p.affiliateUrl),
  "Jedes Produkt hat visualHint + Affiliate-URL"
);
assert.equal(SHOP_PRODUCTS.length >= 11, true, "Verschleißteile + Kernkatalog");

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

console.log("catalog.test.ts OK", { products: SHOP_PRODUCTS.length });
