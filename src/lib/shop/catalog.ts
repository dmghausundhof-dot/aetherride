/**
 * F-SHP-001 / F-SHP-003 — Partnerkatalog mit ComponentModel-Bezug
 * Affiliate: Kauf beim Partner, kein In-App-Zahlungsverkehr (Spec 0.4.4 / 8.4).
 */

import type { ComponentSlot } from "@/types";

export interface ShopProduct {
  id: string;
  name: string;
  manufacturer: string;
  slot: ComponentSlot;
  componentModelId: string;
  priceEur: number;
  description: string;
  /** Partner-Händler Checkout-URL (Affiliate) */
  affiliateUrl: string;
  merchantName: string;
  /** Kurzer visueller Hinweis für Platzhalter-Karte (ohne Asset-Pipeline) */
  visualHint: string;
}

/** Browse-Chips im Shop (Fahrer-Jobs, nicht Spec-IDs) */
export const SHOP_BROWSE_SLOTS: { slot: ComponentSlot | "all"; label: string }[] =
  [
    { slot: "all", label: "Alle" },
    { slot: "chain", label: "Kette" },
    { slot: "brake_pads_front", label: "Beläge" },
    { slot: "tire_front", label: "Reifen" },
    { slot: "cassette", label: "Kassette" },
    { slot: "fork", label: "Gabel" },
    { slot: "rear_shock", label: "Dämpfer" },
    { slot: "seatpost", label: "Dropper" },
    { slot: "battery", label: "Akku" },
  ];

export const SHOP_PRODUCTS: ShopProduct[] = [
  {
    id: "sp-sram-xx-chain",
    name: "SRAM XX Eagle Transmission Chain",
    manufacturer: "SRAM",
    slot: "chain",
    componentModelId: "cm-sram-xx-chain",
    priceEur: 119,
    description: "12-fach Kette — Wechselziel 0,5 % Längung (Velopit/Park Tool)",
    affiliateUrl: "https://www.bike-components.de/de/SRAM/",
    merchantName: "bike-components (Demo-Partner)",
    visualHint: "chain",
  },
  {
    id: "sp-shimano-pad-demo",
    name: "Shimano XT Resin Beläge (Paar)",
    manufacturer: "Shimano",
    slot: "brake_pads_front",
    componentModelId: "cm-shimano-xt-pad",
    priceEur: 29,
    description: "Ersatzbeläge — Wechsel bei < 0,5–1 mm (BIKE Magazin)",
    affiliateUrl: "https://www.bike-components.de/de/Shimano/",
    merchantName: "bike-components (Demo-Partner)",
    visualHint: "pads",
  },
  {
    id: "sp-fox-36",
    name: "Fox 36 Factory Grip2 170mm",
    manufacturer: "Fox",
    slot: "fork",
    componentModelId: "cm-fox-36-factory-170",
    priceEur: 1249,
    description: "Enduro-Gabel 170 mm, Grip2, Boost 15×110",
    affiliateUrl: "https://www.bike-components.de/de/Fox/",
    merchantName: "bike-components (Demo-Partner)",
    visualHint: "fork",
  },
  {
    id: "sp-maxxis-assegai",
    name: "Maxxis Assegai 29×2.5 WT MaxxGrip",
    manufacturer: "Maxxis",
    slot: "tire_front",
    componentModelId: "cm-maxxis-assegai-29-25",
    priceEur: 89,
    description: "Vorderreifen DD MaxxGrip",
    affiliateUrl: "https://www.bike-discount.de/",
    merchantName: "bike-discount (Demo-Partner)",
    visualHint: "tire",
  },
  {
    id: "sp-maxxis-dhr",
    name: "Maxxis Minion DHR II 29×2.4 WT",
    manufacturer: "Maxxis",
    slot: "tire_rear",
    componentModelId: "cm-maxxis-dhr2-29-24",
    priceEur: 85,
    description: "Hinterreifen MaxxTerra DD",
    affiliateUrl: "https://www.bike-discount.de/",
    merchantName: "bike-discount (Demo-Partner)",
    visualHint: "tire",
  },
  {
    id: "sp-sram-cassette-xd",
    name: "SRAM X0 Eagle T-Type 10-52 XD",
    manufacturer: "SRAM",
    slot: "cassette",
    componentModelId: "cm-sram-x0-cassette-xd",
    priceEur: 329,
    description: "Kassette XD — Freilauf muss XD sein",
    affiliateUrl: "https://www.chainreactioncycles.com/",
    merchantName: "CRC (Demo-Partner)",
    visualHint: "cassette",
  },
  {
    id: "sp-shimano-ms",
    name: "Shimano XT M8100 10-51 Micro Spline",
    manufacturer: "Shimano",
    slot: "cassette",
    componentModelId: "cm-shimano-xt-cassette-ms",
    priceEur: 189,
    description: "Kassette Micro Spline — inkompatibel zu XD-Naben",
    affiliateUrl: "https://bike.shimano.com/",
    merchantName: "Shimano Händlernetz (Demo)",
    visualHint: "cassette",
  },
  {
    id: "sp-rs-superdeluxe",
    name: "RockShox Super Deluxe Ultimate 230×65",
    manufacturer: "RockShox",
    slot: "rear_shock",
    componentModelId: "cm-rockshox-superdeluxe-23065",
    priceEur: 679,
    description: "Standard-Eyelet 230×65 — Rahmenmaß prüfen",
    affiliateUrl: "https://www.sram.com/en/rockshox",
    merchantName: "SRAM/RockShox Händler (Demo)",
    visualHint: "shock",
  },
  {
    id: "sp-fox-x2",
    name: "Fox Float X2 Factory 205×65 Trunnion",
    manufacturer: "Fox",
    slot: "rear_shock",
    componentModelId: "cm-fox-float-x2-20565",
    priceEur: 749,
    description: "Trunnion 205×65",
    affiliateUrl: "https://www.ridefox.com/",
    merchantName: "Fox Händler (Demo)",
    visualHint: "shock",
  },
  {
    id: "sp-bosch-800",
    name: "Bosch PowerTube 800 Wh",
    manufacturer: "Bosch",
    slot: "battery",
    componentModelId: "cm-bosch-powertube-800",
    priceEur: 999,
    description: "Smart System Akku — nur bei passendem Motor-Interface",
    affiliateUrl: "https://www.bosch-ebike.com/",
    merchantName: "Bosch eBike Händler (Demo)",
    visualHint: "battery",
  },
  {
    id: "sp-oneup-316",
    name: "OneUp V3 Dropper 31.6",
    manufacturer: "OneUp",
    slot: "seatpost",
    componentModelId: "cm-oneup-v3-dropper-31-6",
    priceEur: 289,
    description: "Dropper Ø 31,6 mm",
    affiliateUrl: "https://oneupcomponents.com/",
    merchantName: "OneUp (Demo)",
    visualHint: "dropper",
  },
];

export function getShopProduct(id: string): ShopProduct | undefined {
  return SHOP_PRODUCTS.find((p) => p.id === id);
}

export function productsForSlot(slot: ComponentSlot): ShopProduct[] {
  if (slot === "brake_pads_rear") {
    return SHOP_PRODUCTS.filter(
      (p) => p.slot === "brake_pads_front" || p.slot === "brake_pads_rear"
    );
  }
  if (slot === "tire_rear") {
    return SHOP_PRODUCTS.filter(
      (p) => p.slot === "tire_front" || p.slot === "tire_rear"
    );
  }
  return SHOP_PRODUCTS.filter((p) => p.slot === slot);
}

/** Wear-Kind → Shop-Slot für Deep-Links */
export function wearKindToShopSlot(
  kind: string
): ComponentSlot | undefined {
  switch (kind) {
    case "chain":
      return "chain";
    case "brake_pads_front":
      return "brake_pads_front";
    case "brake_pads_rear":
      return "brake_pads_rear";
    case "cassette":
      return "cassette";
    case "tires":
      return "tire_front";
    default:
      return undefined;
  }
}

export function shopHref(opts?: {
  productId?: string;
  slot?: ComponentSlot | string;
  job?: "replace" | "browse" | "season";
}): string {
  const params = new URLSearchParams();
  if (opts?.productId) params.set("focus", opts.productId);
  if (opts?.slot) params.set("slot", opts.slot);
  if (opts?.job) params.set("job", opts.job);
  const q = params.toString();
  return q ? `/shop?${q}` : "/shop";
}
