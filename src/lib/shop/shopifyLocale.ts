import {
  chromeDateLocale,
  chromeLangFrom,
  type ChromeLang,
} from "@/lib/i18n/chromeLang";
import { SHOPIFY_STORE_BASE } from "@/lib/shop/catalog";

/** Shopify Storefront LanguageCode for @inContext. */
export type ShopifyLanguageCode = "DE" | "EN" | "FR" | "IT";

export function shopifyLanguageCode(lang: ChromeLang): ShopifyLanguageCode {
  switch (lang) {
    case "en":
      return "EN";
    case "fr":
      return "FR";
    case "it":
      return "IT";
    default:
      return "DE";
  }
}

export function shopifyLangFromSearch(raw?: string | null): ChromeLang {
  return chromeLangFrom(raw);
}

/** EUR prices; number grouping follows chrome locale, not a second currency. */
export function formatShopPrice(
  eur: number,
  currency: string,
  lang: ChromeLang
): string {
  const locale = chromeDateLocale(lang);
  try {
    return new Intl.NumberFormat(locale, {
      style: "currency",
      currency: currency || "EUR",
    }).format(eur);
  } catch {
    return `${eur.toLocaleString(locale)} €`;
  }
}

/** DACH shop primary language — no prefix. en/fr/it use /en /fr /it. */
export function shopifyLocalePrefix(lang: ChromeLang): string {
  return lang === "de" ? "" : `/${lang}`;
}

const LOCALE_SEG = /^(de|en|fr|it)(-[a-z]{2})?$/i;

/**
 * Insert or swap the Online Store locale path on FlowLine’s Shopify origin.
 * Other hosts (Shimano, OneUp, …) stay unchanged.
 */
export function withShopifyLocale(url: string, lang: ChromeLang): string {
  let parsed: URL;
  try {
    parsed = new URL(url);
  } catch {
    return url;
  }
  let base: URL;
  try {
    base = new URL(SHOPIFY_STORE_BASE);
  } catch {
    return url;
  }
  if (parsed.origin !== base.origin) return url;

  const segs = parsed.pathname.split("/").filter(Boolean);
  if (segs[0] && LOCALE_SEG.test(segs[0])) segs.shift();
  const prefix = shopifyLocalePrefix(lang);
  const rest = segs.length ? `/${segs.join("/")}` : "/";
  parsed.pathname = prefix ? `${prefix}${rest === "/" ? "/" : rest}` : rest;
  return parsed.toString();
}
