/**
 * Online Store lock / owner-preview status.
 * Password never ships to the client — only a boolean UX flag.
 *
 * SHOPIFY_ONLINE_STORE_LOCKED:
 *   unset / "true" → treat Online Store as password-gated (default for demo shop)
 *   "false"        → Online Store is public; external product URLs are OK
 *
 * SHOPIFY_STOREFRONT_PASSWORD (optional, server-only):
 *   Eng browser smoke against locked shop — never NEXT_PUBLIC_*, never API response.
 */

export type ShopStoreStatus = {
  /** Storefront API token present */
  storefrontApiConfigured: boolean;
  /** Online Store sales channel behind password */
  onlineStoreLocked: boolean;
  storeDomain: string;
  /** Best integration path recommendation (for ops / PR docs) */
  recommendedPath: "storefront_api_in_app";
  messageDe: string;
};

export function isOnlineStoreLocked(): boolean {
  const v = (process.env.SHOPIFY_ONLINE_STORE_LOCKED || "").trim().toLowerCase();
  if (v === "false" || v === "0" || v === "off") return false;
  if (v === "true" || v === "1" || v === "on") return true;
  // Default: this shop is currently password-gated
  return true;
}

export function getShopStoreStatus(): ShopStoreStatus {
  const configured = Boolean(
    (process.env.SHOPIFY_STOREFRONT_ACCESS_TOKEN || "").trim()
  );
  const locked = isOnlineStoreLocked();
  const domain = (
    process.env.SHOPIFY_STORE_DOMAIN ||
    process.env.NEXT_PUBLIC_SHOPIFY_STORE_DOMAIN ||
    "dmg-haus-und-hof-shop.myshopify.com"
  )
    .trim()
    .replace(/^https?:\/\//, "")
    .replace(/\/$/, "");

  return {
    storefrontApiConfigured: configured,
    onlineStoreLocked: locked,
    storeDomain: domain,
    recommendedPath: "storefront_api_in_app",
    messageDe: locked
      ? configured
        ? "Online Store ist passwortgeschützt — Katalog läuft in FlowLine über die Storefront API. Externe Shopify-Links führen zur Passwort-Seite (Inhaber-Vorschau)."
        : "Online Store ist passwortgeschützt und Storefront API nicht konfiguriert. Setze SHOPIFY_STOREFRONT_ACCESS_TOKEN für In-App-Katalog."
      : "Online Store ist öffentlich — externe Produktlinks funktionieren.",
  };
}

/** In-app product URL — never myshopify password wall */
export function inAppProductHref(handle: string): string {
  return `/shop/p/${encodeURIComponent(handle)}`;
}

/** True if URL points at the locked myshopify Online Store */
export function isShopifyOnlineStoreUrl(url: string): boolean {
  try {
    const u = new URL(url);
    return (
      u.hostname.endsWith(".myshopify.com") ||
      u.hostname.includes("shopify.com")
    );
  } catch {
    return /myshopify\.com/i.test(url);
  }
}
