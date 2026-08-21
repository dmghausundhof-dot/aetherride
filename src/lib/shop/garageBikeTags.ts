/**
 * Ehrliche Bike-Felder → Shopify-Tags, die garageFit / Soft-Fit schon versteht.
 * Keine erfundenen OEM-/Bosch-SKUs, keine Preise.
 */

import type { BikeCategory } from "@/types";
import {
  familiesFromBike,
  inferDrivetrainTokens,
  isRideableGarageBike,
  normalizeWheel,
  type SportFamily,
  type WheelNorm,
} from "@/lib/shop/garageFit";
import {
  GARAGE_BIKE_HANDLE_PREFIX,
  GARAGE_BIKE_PRODUCT_TYPE,
  GARAGE_BIKE_TAG,
} from "@/lib/shop/shopShelf";

export const GARAGE_BIKE_SKU_PREFIX = "AR-GARAGE-";

export type GarageBikeTagInput = {
  bikeId: string;
  name: string;
  brand?: string;
  model?: string;
  category: BikeCategory;
  isEbike?: boolean;
  wheelSizeFront?: string | null;
  wheelSizeRear?: string | null;
  drivetrain?: string[];
  catalogBikeId?: string;
  components?: {
    slot?: string;
    manufacturer?: string;
    model?: string;
  }[];
};

export type GarageBikeShopifyMapping = {
  handle: string;
  sku: string;
  title: string;
  productType: typeof GARAGE_BIKE_PRODUCT_TYPE;
  vendor: string;
  tags: string[];
  families: SportFamily[];
  wheelSizes: WheelNorm[];
  isEbike: boolean;
  drivetrain: string[];
  descriptionHtml: string;
};

const DRIVETRAIN_SLOTS = new Set([
  "cassette",
  "chain",
  "crankset",
  "chainring",
  "rear_derailleur",
  "shifter",
  "front_derailleur",
]);

export function shopifyHandleFromBikeId(bikeId: string): string {
  const slug = bikeId
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9-]+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");
  const id = slug || "unknown";
  return `${GARAGE_BIKE_HANDLE_PREFIX}${id}`.slice(0, 100);
}

export function shopifySkuFromBikeId(bikeId: string): string {
  const slug = bikeId
    .trim()
    .toUpperCase()
    .replace(/[^A-Z0-9-]+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");
  return `${GARAGE_BIKE_SKU_PREFIX}${slug || "UNKNOWN"}`.slice(0, 64);
}

function unique(items: string[]): string[] {
  return [...new Set(items.filter(Boolean))];
}

export function drivetrainFromComponents(
  components: GarageBikeTagInput["components"]
): string[] {
  const out = new Set<string>();
  for (const c of components ?? []) {
    if (c.slot && !DRIVETRAIN_SLOTS.has(c.slot)) continue;
    for (const t of inferDrivetrainTokens(c.manufacturer ?? "", c.model ?? "")) {
      out.add(t);
    }
  }
  return [...out];
}

export function shopifyTagsFromBike(input: GarageBikeTagInput): string[] {
  if (!isRideableGarageBike(input.category)) return [];

  const isEbike =
    Boolean(input.isEbike) ||
    input.category === "emtb" ||
    input.category === "etrekking";
  const families = familiesFromBike(input.category, isEbike);
  const wheels = unique(
    [
      normalizeWheel(input.wheelSizeFront),
      normalizeWheel(input.wheelSizeRear),
    ].filter((w): w is WheelNorm => Boolean(w))
  );
  const drivetrain = unique([
    ...(input.drivetrain ?? []),
    ...drivetrainFromComponents(input.components),
  ]);

  const tags = new Set<string>([GARAGE_BIKE_TAG]);
  for (const f of families) tags.add(`category:${f}`);
  for (const w of wheels) tags.add(`wheel:${w}`);
  tags.add(isEbike ? "ebike" : "analog");
  for (const d of drivetrain) tags.add(`shift_compat:${d}`);
  return [...tags].sort();
}

export function mapGarageBikeToShopify(
  input: GarageBikeTagInput
): GarageBikeShopifyMapping | null {
  if (!isRideableGarageBike(input.category)) return null;

  const isEbike =
    Boolean(input.isEbike) ||
    input.category === "emtb" ||
    input.category === "etrekking";
  const families = familiesFromBike(input.category, isEbike);
  const wheelSizes = unique(
    [
      normalizeWheel(input.wheelSizeFront),
      normalizeWheel(input.wheelSizeRear),
    ].filter((w): w is WheelNorm => Boolean(w))
  ) as WheelNorm[];
  const drivetrain = unique([
    ...(input.drivetrain ?? []),
    ...drivetrainFromComponents(input.components),
  ]);
  const tags = shopifyTagsFromBike(input);
  const brand = input.brand?.trim();
  const model = input.model?.trim();
  const titleCore =
    brand && model ? `${brand} ${model}` : input.name.trim() || "Garage-Bike";
  const facts = [
    ...families,
    ...wheelSizes,
    isEbike ? "E-Bike" : "analog",
    ...drivetrain,
  ];

  return {
    handle: shopifyHandleFromBikeId(input.bikeId),
    sku: shopifySkuFromBikeId(input.bikeId),
    title: `${titleCore} · Garage-Fit`,
    productType: GARAGE_BIKE_PRODUCT_TYPE,
    vendor: brand || "FlowLine Garage",
    tags,
    families,
    wheelSizes,
    isEbike,
    drivetrain,
    descriptionHtml: `<p>Garage-Fit-Profil für das Rad — kein Verkaufsartikel, keine OEM-Teilenummer.</p><p>${facts.join(" · ") || "Felder folgen, sobald sie am Rad stehen."}</p>`,
  };
}
