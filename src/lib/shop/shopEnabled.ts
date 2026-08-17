import { isAppLaunched } from "@/lib/config/appStage";

/**
 * Zwei Schalter, nicht verwechseln:
 *
 * 1. Laden-UI (Affiliate-Katalog)
 *    Web `/shop`: default aus bis Launch. Preview: NEXT_PUBLIC_SHOP_ENABLED=true
 *    App: default aus (`AETHER_SHOP_ENABLED` / AppConfig.shopEnabled)
 *
 * 2. Shopify-Kasse / Custom Tabs / Garage-Hook
 *    Immer aus bis Launch, danach nur mit SHOPIFY_COMMERCE_ENABLED=true
 *    (App: --dart-define=SHOPIFY_COMMERCE_ENABLED=true)
 */

function envFlag(name: string): string {
  if (typeof process === "undefined") return "";
  return (process.env[name] || "").trim().toLowerCase();
}

function isExplicitOff(v: string): boolean {
  return v === "false" || v === "0" || v === "off";
}

function isExplicitOn(v: string): boolean {
  return v === "true" || v === "1" || v === "on";
}

/** Web-Laden-UI (`/shop`). Default: nur nach Launch. App-Tür ist ein anderer Schalter. */
export function isShopEnabled(): boolean {
  const v = envFlag("NEXT_PUBLIC_SHOP_ENABLED");
  if (isExplicitOff(v)) return false;
  if (isExplicitOn(v)) return true;
  return isAppLaunched();
}

/**
 * Shopify als Verkäufer: Storefront-Checkout, Custom Tabs, Garage-Hook.
 * Bleibt zu, solange die App nicht launched ist.
 */
export function isShopifyCommerceEnabled(): boolean {
  if (!isAppLaunched()) return false;
  const v =
    envFlag("SHOPIFY_COMMERCE_ENABLED") ||
    envFlag("NEXT_PUBLIC_SHOPIFY_COMMERCE_ENABLED");
  return isExplicitOn(v);
}

export const SHOP_DISABLED_BODY = {
  ok: false,
  enabled: false,
  error: "shop_disabled",
} as const;
