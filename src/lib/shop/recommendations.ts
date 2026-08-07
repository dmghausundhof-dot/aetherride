/**
 * F-SHP-002 — Anlassbezogene Produktempfehlungen
 *
 * Anlässe (Spec): Verschleißgrenze, wiederkehrendes Setup-Problem, Saisonwechsel.
 * MUSS: Jede Empfehlung nennt den auslösenden Datenpunkt. Ohne Anlass = untersagt.
 *
 * Quellen für Schwellwerte:
 * - Velopit / Bavarian Bike: Kette 0,5 % / Beläge / Reifen MTB 1.500–4.000 km
 * - BIKE Magazin: Belag < 0,5–1 mm; Matsch beschleunigt
 * - Rotwild eMTB-Wartung: lieber 3× Kette als 1× Kassette
 */

import { forecastWear, type WearForecast } from "@/lib/maintenance/wearPrediction";
import {
  SHOP_PRODUCTS,
  getShopProduct,
  type ShopProduct,
} from "@/lib/shop/catalog";
import type { Bike, Ride, Setup } from "@/types";

export interface ProductRecommendation {
  id: string;
  product: ShopProduct;
  triggerKind: "wear" | "setup_limit" | "season";
  /** Pflicht: auslösender Datenpunkt (Spec MUSS) */
  triggeringDataPoint: string;
  title: string;
  reason: string;
  sourceLabel: string;
  confidence: "low" | "medium" | "high";
}

function productForWear(f: WearForecast): ShopProduct | undefined {
  switch (f.kind) {
    case "chain":
      return getShopProduct("sp-sram-xx-chain");
    case "brake_pads_front":
    case "brake_pads_rear":
      return getShopProduct("sp-shimano-pad-demo");
    case "cassette":
      return getShopProduct("sp-sram-cassette-xd");
    case "tires":
      return getShopProduct("sp-maxxis-assegai");
    default:
      return undefined;
  }
}

function resolveProduct(f: WearForecast): ShopProduct {
  return (
    productForWear(f) ??
    getShopProduct("sp-sram-xx-chain") ??
    SHOP_PRODUCTS[0]
  );
}

export function recommendProductsFromWear(
  bike: Bike,
  rides: Ride[]
): ProductRecommendation[] {
  const forecasts = forecastWear(bike, rides).filter((f) => f.dueSoon);
  return forecasts.map((f) => {
    const product = resolveProduct(f);
    return {
      id: `rec-wear-${f.kind}-${product.id}`,
      product,
      triggerKind: "wear" as const,
      triggeringDataPoint: f.label,
      title: `${product.name} — wegen Verschleißprognose`,
      reason: `${f.reasoning} → Produktempfehlung nur weil dieser Datenpunkt vorliegt.`,
      sourceLabel: f.sourceLabel,
      confidence: f.usedRatio >= 0.9 ? "high" : "medium",
    };
  });
}

/** Setup am Anschlag: z. B. Rebound max und Feedback „zu schnell“ */
export function recommendFromSetupLimit(
  bike: Bike,
  setup: Setup | undefined,
  notes?: string
): ProductRecommendation[] {
  if (!setup) return [];
  const out: ProductRecommendation[] = [];
  const rebound = setup.values.find(
    (v) => v.slot === "fork" && v.adjusterKey === "rebound"
  );
  if (
    rebound &&
    typeof rebound.valueNum === "number" &&
    rebound.outOfSpec
  ) {
    const shock = SHOP_PRODUCTS.find((p) => p.slot === "rear_shock");
    if (shock) {
      out.push({
        id: `rec-setup-rebound-${shock.id}`,
        product: shock,
        triggerKind: "setup_limit",
        triggeringDataPoint: `fork.rebound=${rebound.valueNum} außerhalb Spec (${rebound.outOfSpec})`,
        title: `${shock.name} — Setup am Anschlag`,
        reason:
          "Zugstufe außerhalb Herstellerbereich und weiterhin unpassend → Service oder anderes Tune prüfen (Spec F-SHP-002).",
        sourceLabel: "Setup-Historie · Herstellerbereich",
        confidence: "medium",
      });
    }
  }
  if (notes && /zu rau|harsh|zu schnell ausschwing/i.test(notes)) {
    const fork = SHOP_PRODUCTS.find((p) => p.slot === "fork");
    if (fork) {
      out.push({
        id: `rec-setup-feel-${fork.id}`,
        product: fork,
        triggerKind: "setup_limit",
        triggeringDataPoint: `Post-Ride-Feedback: „${notes.slice(0, 80)}"`,
        title: `${fork.name} — wiederkehrendes Fahrgefühl`,
        reason:
          "Wiederholtes Feedback zur Front bei bereits optimiertem Setup kann auf Service/Tune hinweisen.",
        sourceLabel: "Ride-Feedback",
        confidence: "low",
      });
    }
  }
  return out;
}

/** Saisonwechsel: nass / Winter → Grip-Reifen */
export function recommendSeasonal(
  month = new Date().getMonth() + 1
): ProductRecommendation[] {
  // Okt–März: nass/kalt
  if (month < 4 || month >= 10) {
    const tire = getShopProduct("sp-maxxis-assegai");
    if (!tire) return [];
    return [
      {
        id: `rec-season-wet-${tire.id}`,
        product: tire,
        triggerKind: "season",
        triggeringDataPoint: `Kalendermonat ${month} (Nass-/Wintersaison DACH)`,
        title: `${tire.name} — Saisonwechsel nass`,
        reason:
          "Saisonale Empfehlung nur im Herbst/Winter: MaxxGrip/Assegai als Ausgangspunkt bei Nässe (Enduro-Praxis).",
        sourceLabel: "Saisonkalender DACH · Enduro Mag Reifenpraxis",
        confidence: "low",
      },
    ];
  }
  return [];
}

export function allProductRecommendations(input: {
  bike: Bike;
  rides: Ride[];
  setup?: Setup;
  feedbackNotes?: string;
}): ProductRecommendation[] {
  const merged = [
    ...recommendProductsFromWear(input.bike, input.rides),
    ...recommendFromSetupLimit(input.bike, input.setup, input.feedbackNotes),
    ...recommendSeasonal(),
  ];
  // Dedup by product
  const seen = new Set<string>();
  return merged.filter((r) => {
    if (seen.has(r.product.id)) return false;
    seen.add(r.product.id);
    return true;
  });
}
