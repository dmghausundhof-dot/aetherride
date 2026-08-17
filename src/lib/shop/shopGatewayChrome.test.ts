/**
 * Laden-Gateway Tagline — Ausführen: npx tsx src/lib/shop/shopGatewayChrome.test.ts
 */
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { FLOWLINE_TAGLINE_DOTS } from "../content/brand";

assert.equal(FLOWLINE_TAGLINE_DOTS, "Outdoor · Cycling · Flow");
assert.notEqual(FLOWLINE_TAGLINE_DOTS, FLOWLINE_TAGLINE_DOTS.toUpperCase());
assert.ok(FLOWLINE_TAGLINE_DOTS.includes(" · "));

const gateway = readFileSync("src/components/shop/ShopGateway.tsx", "utf8");
assert(
  !gateway.includes("uppercase tracking"),
  "ShopGateway tagline stays sentence case",
);
assert(
  gateway.includes("tracking-[0.18em]"),
  "ShopGateway tagline tracking stays",
);
assert(
  gateway.includes("FLOWLINE_TAGLINE_DOTS"),
  "ShopGateway still uses the brand tagline",
);
assert(
  gateway.includes("{copy.shopTitle}"),
  "ShopGateway screen title is the Hof door",
);
assert(
  !gateway.includes("shopCyclingParts"),
  "ShopGateway screen title is not assortment Parts",
);

const catalog = readFileSync("src/components/shop/ShopCatalogPreview.tsx", "utf8");
assert(
  catalog.includes("products.length === 0"),
  "Dead catalog skips the search field",
);
assert(
  catalog.includes("shopSearchHint"),
  "Search hint stays on a live shelf",
);

const nativeShop = readFileSync(
  "mobile/lib/presentation/shop/shop_screen.dart",
  "utf8",
);
assert(
  nativeShop.includes("l10n.shopGatewayTitle"),
  "Native AppBar uses the Hof door title",
);
assert(
  nativeShop.includes("shop-appbar-title"),
  "Native AppBar title is keyed",
);
assert(
  !nativeShop.includes("l10n.shopCyclingParts"),
  "Native AppBar is not assortment Parts",
);

function cssBlock(src: string, selector: string): string {
  const match = src.match(new RegExp(`${selector.replace(".", "\\.")} \\{[^}]+\\}`));
  assert.ok(match, `${selector} CSS block`);
  return match[0];
}

const worlds = readFileSync(
  "shopify/theme/sections/aetherride-worlds.liquid",
  "utf8",
);
const worldsTag = cssBlock(worlds, ".ar-worlds__tag");
assert(
  !worldsTag.includes("text-transform: uppercase"),
  "Shopify worlds tagline stays sentence case",
);
assert(worldsTag.includes("letter-spacing"), "Shopify worlds tracking stays");
assert(worlds.includes("Outdoor · Cycling · Flow"));

const password = readFileSync(
  "shopify/theme/sections/main-password-header.liquid",
  "utf8",
);
const passwordTag = cssBlock(password, ".password-flowline__tag");
assert(
  !passwordTag.includes("text-transform: uppercase"),
  "Shopify password tagline stays sentence case",
);
assert(passwordTag.includes("letter-spacing"), "Shopify password tracking stays");
assert(password.includes("Outdoor · Cycling · Flow"));

console.log("shopGatewayChrome.test.ts OK");
