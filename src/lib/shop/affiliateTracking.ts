/**
 * Optional affiliate click wrapping (Bike24 / Uppr / Awin).
 * No publisher credentials in code — prefix comes from env.
 * Unset prefix → raw merchant URL (app works without approval).
 */

export type AffiliateMerchant =
  | "bike24"
  | "bike-components"
  | "bike-discount"
  | "other";

function env(name: string): string {
  if (typeof process === "undefined") return "";
  return (process.env[name] || "").trim();
}

function flagOff(name: string): boolean {
  const v = env(name).toLowerCase();
  return v === "false" || v === "0" || v === "off";
}

export function affiliateMerchantFromHost(host: string): AffiliateMerchant {
  const h = host.toLowerCase();
  if (/(^|\.)bike24\.(de|com|at|ch|nl|fr|it|es)$/i.test(h)) return "bike24";
  if (h.includes("bike-components")) return "bike-components";
  if (h.includes("bike-discount")) return "bike-discount";
  return "other";
}

export function affiliateMerchantFromUrl(
  url: string | null | undefined
): AffiliateMerchant {
  if (!url) return "other";
  try {
    return affiliateMerchantFromHost(new URL(url.trim()).hostname);
  } catch {
    return "other";
  }
}

export function merchantDisclosureName(merchant: AffiliateMerchant): string {
  switch (merchant) {
    case "bike24":
      return "Bike24";
    case "bike-components":
      return "bike-components";
    case "bike-discount":
      return "bike-discount";
    default:
      return "Händler";
  }
}

/** Bike24 click prefix (Awin/Uppr). Public tracking URLs — not secrets. */
export function bike24DeepLinkPrefix(): string {
  return (
    env("BIKE24_DEEP_LINK_PREFIX") ||
    env("NEXT_PUBLIC_BIKE24_DEEP_LINK_PREFIX")
  );
}

function bike24WrapEnabled(): boolean {
  const prefix = bike24DeepLinkPrefix();
  if (!prefix) return false;
  if (flagOff("BIKE24_AFFILIATE_ENABLED")) return false;
  if (flagOff("NEXT_PUBLIC_BIKE24_AFFILIATE_ENABLED")) return false;
  return true;
}

function alreadyWrapped(raw: string, prefix: string): boolean {
  return raw.startsWith(prefix) || /awin1\.com|adtraction\.com|uppr\./i.test(raw);
}

/**
 * Wrap Bike24 product URLs when a click prefix is configured.
 * Other merchants stay raw. Shopify is never wrapped here.
 */
export function trackedMerchantUrl(
  rawUrl: string,
  merchant?: AffiliateMerchant
): string {
  const raw = rawUrl.trim();
  if (!raw) return raw;
  const who = merchant ?? affiliateMerchantFromUrl(raw);
  if (who !== "bike24") return raw;
  if (!bike24WrapEnabled()) return raw;
  const prefix = bike24DeepLinkPrefix();
  if (!prefix || alreadyWrapped(raw, prefix)) return raw;
  return `${prefix}${encodeURIComponent(raw)}`;
}
