/**
 * F-SHP-003 Phase 3 Marketplace — Stub mit EU-Pflichtangaben
 * Spec: nur bei belegter Nachfrage; physische Waren NICHT über Apple IAP.
 * Stufe 1 Affiliate bleibt Default.
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
}

export const MARKETPLACE_LEGAL: MarketplaceLegal = {
  imprint:
    "AetherRide Demo GmbH (Muster) · Musterstraße 1 · 80331 München · info@aetherride.demo",
  withdrawal:
    "Widerrufsbelehrung: 14 Tage Widerrufsrecht ab Warenerhalt (Verbraucher, EU).",
  shipping:
    "Versandkosten und Lieferzeit werden vor Kaufabschluss angezeigt (hier: 5,90 € / 2–4 Werktage Demo).",
  warranty: "Gewährleistung nach EU-Recht. Händler bleibt Vertragspartner.",
  gpsr:
    "GPSR: Herstellerangaben je Produkt erforderlich. Demo-Produkte: siehe Partnerkatalog.",
  dispute:
    "Online-Streitbeilegung: https://ec.europa.eu/consumers/odr — Demo-Hinweis.",
  batteryNote:
    "Lithium-Akkus: in Stufe 1 nicht vermittelt; Stufe 2 nur über Händler mit Gefahrgutzulassung (Spec 8.5).",
};

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
      "Produktion: Stripe Checkout Session. Kein Apple IAP für physische Waren (Store-Regel).",
  };
}
