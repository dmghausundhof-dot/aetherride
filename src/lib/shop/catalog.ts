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
}

export const SHOP_PRODUCTS: ShopProduct[] = [
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
  },
];
