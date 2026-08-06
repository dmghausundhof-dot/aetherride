/**
 * F-SHP-003 Marketplace — EU-Pflichtangaben aus Env (keine erfundenen Firmendaten).
 */

export type CommerceMode = "affiliate" | "marketplace";

export interface MarketplaceLegal {
  imprint: string;
  withdrawal: string;
  shipping: string;
  warranty: string;
  gpsr: string;
  dispute: string;
  batteryNote: string;
  /** false wenn Pflichtfelder (Impressum) nicht konfiguriert */
  configured: boolean;
}

function env(name: string): string {
  if (typeof process === "undefined") return "";
  return (process.env[name] || "").trim();
}

export function getMarketplaceLegal(): MarketplaceLegal {
  const imprint = env("NEXT_PUBLIC_LEGAL_IMPRINT");
  const withdrawal =
    env("NEXT_PUBLIC_LEGAL_WITHDRAWAL") ||
    "Widerrufsbelehrung: 14 Tage Widerrufsrecht ab Warenerhalt für Verbraucher in der EU. Details: /legal/widerruf";
  const shipping =
    env("NEXT_PUBLIC_LEGAL_SHIPPING") ||
    "Versandkosten und Lieferzeit werden vor Kaufabschluss angezeigt.";
  const warranty =
    env("NEXT_PUBLIC_LEGAL_WARRANTY") ||
    "Gewährleistung nach EU-Recht. Vertragspartner ist der jeweilige Händler bzw. AetherRide laut Impressum.";
  const gpsr =
    env("NEXT_PUBLIC_LEGAL_GPSR") ||
    "GPSR: Herstellerangaben je Produkt im Katalog bzw. vor Checkout.";
  const dispute =
    env("NEXT_PUBLIC_LEGAL_DISPUTE") ||
    "Online-Streitbeilegung: https://ec.europa.eu/consumers/odr";
  const batteryNote =
    env("NEXT_PUBLIC_LEGAL_BATTERY") ||
    "Lithium-Akkus: in Affiliate-Stufe nicht vermittelt; Marketplace nur über Händler mit Gefahrgutzulassung (Spec 8.5).";

  return {
    imprint: imprint || "",
    withdrawal,
    shipping,
    warranty,
    gpsr,
    dispute,
    batteryNote,
    configured: Boolean(imprint),
  };
}

/** @deprecated use getMarketplaceLegal() */
export const MARKETPLACE_LEGAL: MarketplaceLegal = getMarketplaceLegal();

export interface MarketplaceCheckoutDraft {
  mode: CommerceMode;
  items: { name: string; priceEur: number; qty: number }[];
  shippingEur: number;
  totalEur: number;
  legalAccepted: boolean;
  stripeNote: string;
}

export function buildMarketplaceDraft(
  items: { name: string; priceEur: number; qty: number }[]
): MarketplaceCheckoutDraft {
  const sub = items.reduce((s, i) => s + i.priceEur * i.qty, 0);
  const shipping = items.length ? 5.9 : 0;
  return {
    mode: "marketplace",
    items,
    shippingEur: shipping,
    totalEur: Math.round((sub + shipping) * 100) / 100,
    legalAccepted: false,
    stripeNote:
      "Stripe Checkout Session. Kein Apple IAP für physische Waren (Store-Regel).",
  };
}
