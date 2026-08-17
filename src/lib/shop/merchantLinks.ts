/**
 * "Beim Händler kaufen" / external CTA rules:
 * - Real product (or product-search) URLs only
 * - Never bare merchant homepages
 * - Omit CTA if unknown / not deep enough
 * - Bike24 DE: /p123456.html (no slash after p) is a product URL
 */

import { trackedMerchantUrl } from "@/lib/shop/affiliateTracking";

function isBike24Host(host: string): boolean {
  return /(^|\.)bike24\.(de|com|at|ch|nl|fr|it|es)$/i.test(host);
}

function isShopifyHost(host: string): boolean {
  return host.endsWith(".myshopify.com") || host.includes("shopify.com");
}

export function isDeepProductUrl(url: string | null | undefined): boolean {
  if (!url || !url.trim()) return false;
  const trimmed = url.trim();
  // In-app routes are not merchant links
  if (trimmed.startsWith("/")) return false;
  try {
    const u = new URL(trimmed);
    const path = u.pathname.replace(/\/+$/, "") || "";
    const host = u.hostname.toLowerCase();

    // Shopify Online Store — only concrete product handles
    if (isShopifyHost(host)) {
      return /\/products\/[^/]+$/i.test(path) || /\/products\/[^/]+/i.test(path);
    }

    // Bare homepage (origin only)
    if (!path || path === "") return false;

    // Explicit product paths
    if (/\/products?\//i.test(path)) return true;
    if (/\/(dp|gp|item|p)\//i.test(path)) return true;
    // Bike24: /p2391234.html (p + digits, no slash after p)
    if (/\/p\d+(\.html)?$/i.test(path)) return true;
    // Bike24 SEO slug: /sram-xx-eagle-chain-p2391234.html
    if (isBike24Host(host) && /p\d+(\.html)?$/i.test(path)) return true;
    // Manufacturer product tree (e.g. shimano .../product/component/...)
    if (/\/product\//i.test(path)) return true;

    // Search with query that looks product-specific
    const q =
      u.searchParams.get("searchparam") ||
      u.searchParams.get("searchterm") ||
      u.searchParams.get("q") ||
      u.searchParams.get("query") ||
      "";
    if (q.trim().length >= 3) return true;

    // Brand-only category pages (/de/SRAM/) — not product enough
    return false;
  } catch {
    return false;
  }
}

/** Returns URL for merchant CTA or undefined to omit the button */
export function merchantCtaUrl(
  url: string | null | undefined
): string | undefined {
  return isDeepProductUrl(url) ? url!.trim() : undefined;
}

/**
 * „Beim Händler kaufen“ — tiefe Nicht-Shopify-URLs, optional tracking wrap.
 * Shopify bleibt hinter SHOPIFY_COMMERCE_ENABLED, kein zweiter Händler-Button.
 */
export function dealerCtaUrl(
  url: string | null | undefined
): string | undefined {
  const cta = merchantCtaUrl(url);
  if (!cta) return undefined;
  try {
    const host = new URL(cta).hostname.toLowerCase();
    if (isShopifyHost(host)) {
      return undefined;
    }
  } catch {
    return undefined;
  }
  return trackedMerchantUrl(cta);
}
