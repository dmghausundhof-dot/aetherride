/**
 * F-SHP-001 / F-SHP-003 — Beispielkatalog mit ComponentModel-Bezug
 * Affiliate-URLs sind Platzhalter; Kauf nur extern (Spec 0.4.4 / 8.4).
 */

import type { ComponentSlot } from "@/types";

/** Disziplin-Tags für Shop-Filter (Phase C) */
export type ShopSport =
  | "mtb"
  | "road"
  | "gravel"
  | "urban"
  | "ebike"
  | "all";

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
  /** Optional CDN product image (Shopify files); falls back to visualHint icon */
  imageUrl?: string;
  /** Passende Disziplinen — „all“ = universell */
  sports: ShopSport[];
}

export const SHOP_SPORT_FILTERS: { id: ShopSport; label: string }[] = [
  { id: "all", label: "Alle" },
  { id: "road", label: "Rennrad" },
  { id: "gravel", label: "Gravel" },
  { id: "mtb", label: "MTB" },
  { id: "urban", label: "City" },
  { id: "ebike", label: "E-Bike" },
];

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
    { slot: "seatpost", label: "Sattelstütze" },
    { slot: "bar_tape", label: "Lenkerband" },
    { slot: "battery", label: "Akku" },
  ];


/** Shopify Storefront (Phase A — deep links only, no Storefront API token) */
export const SHOPIFY_STORE_BASE =
  "https://dmg-haus-und-hof-shop.myshopify.com";

export function shopifyProductUrl(handle: string): string {
  return `${SHOPIFY_STORE_BASE}/products/${handle}`;
}

export function shopifyCollectionUrl(handle: string): string {
  return `${SHOPIFY_STORE_BASE}/collections/${handle}`;
}

/** Sport-Query → Shopify Collection Handle */
export const SHOPIFY_COLLECTIONS: Record<string, string> = {
  gravel: "featured-gravel",
  city: "featured-light-e-city",
  "light-e": "featured-light-e-city",
  urban: "featured-light-e-city",
};

export function shopCollectionHref(sport: string): string | undefined {
  const handle = SHOPIFY_COLLECTIONS[sport];
  return handle ? shopifyCollectionUrl(handle) : undefined;
}

/** Featured complete bikes from AetherRide Shopify (placeholder images + test prices) */
export const SHOPIFY_FEATURED_BIKES: ShopProduct[] = [
  {
    id: "sp-shopify-orbea-terra-m20",
    name: "Orbea Terra M20",
    manufacturer: "Orbea",
    slot: "frame",
    componentModelId: "cm-shopify-orbea-terra-m20",
    priceEur: 2799,
    description:
      "Gravel-Allrounder — Testpreis. Checkout im AetherRide Shopify-Shop.",
    affiliateUrl: shopifyProductUrl("orbea-terra-m20"),
    merchantName: "AetherRide Shop",
    visualHint: "bike",
    imageUrl:
      "https://cdn.shopify.com/s/files/1/1045/0318/1649/files/photo-1485965120184-e220f721d03e.jpg?v=1786479558",
    sports: ["gravel"],
  },
  {
    id: "sp-shopify-specialized-diverge-carbon",
    name: "Specialized Diverge Carbon",
    manufacturer: "Specialized",
    slot: "frame",
    componentModelId: "cm-shopify-specialized-diverge-carbon",
    priceEur: 3499,
    description:
      "Carbon-Gravel — Testpreis. Checkout im AetherRide Shopify-Shop.",
    affiliateUrl: shopifyProductUrl("specialized-diverge-carbon"),
    merchantName: "AetherRide Shop",
    visualHint: "bike",
    imageUrl:
      "https://cdn.shopify.com/s/files/1/1045/0318/1649/files/photo-1571068316344-75bc76f77890.jpg?v=1786479566",
    sports: ["gravel"],
  },
  {
    id: "sp-shopify-cube-attain-gtc-race",
    name: "Cube Attain GTC Race",
    manufacturer: "Cube",
    slot: "frame",
    componentModelId: "cm-shopify-cube-attain-gtc-race",
    priceEur: 1499,
    description:
      "Leichtes Carbon-Rennrad — Testpreis. Checkout im AetherRide Shopify-Shop.",
    affiliateUrl: shopifyProductUrl("cube-attain-gtc-race"),
    merchantName: "AetherRide Shop",
    visualHint: "bike",
    imageUrl:
      "https://cdn.shopify.com/s/files/1/1045/0318/1649/files/photo-1485965120184-e220f721d03e_24d45399-5a57-45a2-a6ac-da88f92d7199.jpg?v=1786479867",
    sports: ["road", "gravel"],
  },
  {
    id: "sp-shopify-canyon-ultimate-cf-sl-8",
    name: "Canyon Ultimate CF SL 8",
    manufacturer: "Canyon",
    slot: "frame",
    componentModelId: "cm-shopify-canyon-ultimate-cf-sl-8",
    priceEur: 2499,
    description:
      "Rennrad Performance — Testpreis. Checkout im AetherRide Shopify-Shop.",
    affiliateUrl: shopifyProductUrl("canyon-ultimate-cf-sl-8"),
    merchantName: "AetherRide Shop",
    visualHint: "bike",
    imageUrl:
      "https://cdn.shopify.com/s/files/1/1045/0318/1649/files/photo-1532298229144-0ec0c57515c7.jpg?v=1786479572",
    sports: ["road"],
  },
  {
    id: "sp-shopify-canyon-commuter-7-0",
    name: "Canyon Commuter 7.0",
    manufacturer: "Canyon",
    slot: "frame",
    componentModelId: "cm-shopify-canyon-commuter-7-0",
    priceEur: 1299,
    description:
      "City / Light-E Pendlerbike — Testpreis. Checkout im AetherRide Shopify-Shop.",
    affiliateUrl: shopifyProductUrl("canyon-commuter-7-0"),
    merchantName: "AetherRide Shop",
    visualHint: "bike",
    imageUrl:
      "https://cdn.shopify.com/s/files/1/1045/0318/1649/files/photo-1507035895480-2b3156c31fc8.jpg?v=1786479574",
    sports: ["urban", "ebike"],
  },
];

export function getFeaturedShopifyProducts(): ShopProduct[] {
  return SHOPIFY_FEATURED_BIKES;
}

export function shopifyHandleFromProductId(id: string): string | undefined {
  const prefix = "sp-shopify-";
  if (!id.startsWith(prefix)) return undefined;
  return id.slice(prefix.length);
}

export const SHOP_PRODUCTS: ShopProduct[] = [
  ...SHOPIFY_FEATURED_BIKES,
  {
    id: "sp-sram-xx-chain",
    name: "SRAM XX Eagle Transmission Chain",
    manufacturer: "SRAM",
    slot: "chain",
    componentModelId: "cm-sram-xx-chain",
    priceEur: 119,
    description: "12-fach Kette — Wechselziel 0,5 % Längung (Velopit/Park Tool)",
    affiliateUrl: "https://www.bike-components.de/de/SRAM/",
    merchantName: "bike-components (Beispielkatalog)",
    visualHint: "chain",
    sports: ["mtb", "ebike"],
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
    merchantName: "bike-components (Beispielkatalog)",
    visualHint: "pads",
    sports: ["mtb", "gravel", "ebike"],
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
    merchantName: "bike-components (Beispielkatalog)",
    visualHint: "fork",
    sports: ["mtb", "ebike"],
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
    merchantName: "bike-discount (Beispielkatalog)",
    visualHint: "tire",
    sports: ["mtb", "ebike"],
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
    merchantName: "bike-discount (Beispielkatalog)",
    visualHint: "tire",
    sports: ["mtb", "ebike"],
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
    merchantName: "CRC (Beispielkatalog)",
    visualHint: "cassette",
    sports: ["mtb", "ebike"],
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
    merchantName: "Shimano Händlernetz (Beispiel)",
    visualHint: "cassette",
    sports: ["mtb", "gravel", "ebike"],
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
    merchantName: "SRAM/RockShox Händler (Beispiel)",
    visualHint: "shock",
    sports: ["mtb", "ebike"],
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
    merchantName: "Fox Händler (Beispiel)",
    visualHint: "shock",
    sports: ["mtb", "ebike"],
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
    merchantName: "Bosch eBike Händler (Beispiel)",
    visualHint: "battery",
    sports: ["ebike"],
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
    merchantName: "OneUp (Beispiel)",
    visualHint: "dropper",
    sports: ["mtb", "gravel", "ebike"],
  },
  // —— Road / Gravel / City (Phase C Multi-Sport) ——
  {
    id: "sp-conti-gp5000",
    name: "Continental GP 5000 S TR 28-622",
    manufacturer: "Continental",
    slot: "tire_front",
    componentModelId: "cm-conti-gp5000-28",
    priceEur: 74,
    description: "Allround-Rennradreifen tubeless-ready",
    affiliateUrl: "https://www.bike-components.de/",
    merchantName: "bike-components (Beispielkatalog)",
    visualHint: "tire",
    sports: ["road", "urban"],
  },
  {
    id: "sp-schwalbe-g-one",
    name: "Schwalbe G-One R 40-622",
    manufacturer: "Schwalbe",
    slot: "tire_front",
    componentModelId: "cm-schwalbe-g-one-40",
    priceEur: 64,
    description: "Schneller Gravel-Reifen, gemischte Oberflächen",
    affiliateUrl: "https://www.bike-discount.de/",
    merchantName: "bike-discount (Beispielkatalog)",
    visualHint: "tire",
    sports: ["gravel", "urban"],
  },
  {
    id: "sp-shimano-ultegr-chain",
    name: "Shimano Ultegra CN-M8100 12s",
    manufacturer: "Shimano",
    slot: "chain",
    componentModelId: "cm-shimano-ultegra-chain",
    priceEur: 49,
    description: "12-fach Kette für Road/Gravel-Gruppen",
    affiliateUrl: "https://www.bike-components.de/de/Shimano/",
    merchantName: "bike-components (Beispielkatalog)",
    visualHint: "chain",
    sports: ["road", "gravel", "urban"],
  },
  {
    id: "sp-supacaz-tape",
    name: "Supacaz Super Sticky Kush Lenkerband",
    manufacturer: "Supacaz",
    slot: "bar_tape",
    componentModelId: "cm-supacaz-tape",
    priceEur: 39,
    description: "Lenkerband — Verschleiß und Grip erneuern",
    affiliateUrl: "https://www.bike-components.de/",
    merchantName: "bike-components (Beispielkatalog)",
    visualHint: "tape",
    sports: ["road", "gravel"],
  },
  {
    id: "sp-schwalbe-marathon",
    name: "Schwalbe Marathon 37-622",
    manufacturer: "Schwalbe",
    slot: "tire_rear",
    componentModelId: "cm-schwalbe-marathon-37",
    priceEur: 42,
    description: "Pannenresistenter City-/Touring-Reifen",
    affiliateUrl: "https://www.bike-discount.de/",
    merchantName: "bike-discount (Beispielkatalog)",
    visualHint: "tire",
    sports: ["urban", "ebike", "road"],
  },
];

export function productMatchesSport(
  product: ShopProduct,
  sport: ShopSport
): boolean {
  if (sport === "all") return true;
  return product.sports.includes(sport) || product.sports.includes("all");
}

/** Bike-Kategorie → Shop-Sport-Default */
export function shopSportFromBikeCategory(
  category: string | undefined
): ShopSport {
  switch (category) {
    case "road":
      return "road";
    case "gravel":
      return "gravel";
    case "urban":
      return "urban";
    case "emtb":
    case "etrekking":
      return "ebike";
    case "mtb_trail":
    case "mtb_am":
    case "mtb_enduro":
    case "dh":
      return "mtb";
    default:
      return "all";
  }
}

export function getShopProduct(id: string): ShopProduct | undefined {
  return SHOP_PRODUCTS.find((p) => p.id === id);
}

export function getShopProductByFocus(focus: string): ShopProduct | undefined {
  const direct = SHOP_PRODUCTS.find((p) => p.id === focus);
  if (direct) return direct;
  return SHOPIFY_FEATURED_BIKES.find(
    (p) => shopifyHandleFromProductId(p.id) === focus
  );
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
  /** Shopify product handle or catalog id */
  focus?: string;
  slot?: ComponentSlot | string;
  job?: "replace" | "browse" | "season";
  /** gravel | city | light-e | urban | road | mtb | ebike | all */
  sport?: string;
}): string {
  const params = new URLSearchParams();
  const focus = opts?.focus ?? opts?.productId;
  if (focus) params.set("focus", focus);
  if (opts?.slot) params.set("slot", opts.slot);
  if (opts?.job) params.set("job", opts.job);
  if (opts?.sport) params.set("sport", opts.sport);
  const q = params.toString();
  return q ? `/shop?${q}` : "/shop";
}

/** Map deep-link sport query (city / light-e) onto ShopSport filter chips */
export function shopSportFromQuery(
  sport: string | null | undefined
): ShopSport | null {
  if (!sport) return null;
  if (sport === "city") return "urban";
  if (sport === "light-e") return "ebike";
  if (SHOP_SPORT_FILTERS.some((s) => s.id === sport)) {
    return sport as ShopSport;
  }
  return null;
}
