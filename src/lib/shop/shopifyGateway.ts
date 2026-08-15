/**
 * Shopify gateway URLs — no in-app catalog.
 * Tag filters use handleized form (`category:gravel` → `category-gravel`).
 * Merch is never fit-filtered.
 */

import type { Bike } from "@/types";
import {
  SHOPIFY_PARTS_COLLECTION,
  SHOPIFY_STORE_BASE,
  shopifyCollectionUrl,
} from "@/lib/shop/catalog";
import { profileFromBike } from "@/lib/shop/garageFit";

export const SHOPIFY_MERCH_COLLECTION = "merchandise";

/** Shopify `handleize`: lowercase, non-alnum → hyphen. */
export function shopifyHandleize(raw: string): string {
  const out = raw
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/-{2,}/g, "-");
  return out.replace(/^-+|-+$/g, "");
}

/**
 * Garage-fit tags for the parts collection.
 * Category (+ wheel or slot) only — no AND over drivetrain/e-bike.
 */
export function shopifyFitTags(bike: Bike, slot?: string): string[] {
  const profile = profileFromBike(bike);
  if (!profile) return [];
  const tags: string[] = [];
  if (profile.families.length > 0) {
    tags.push(`category:${profile.families[0]}`);
  }
  const slotKey = slot?.trim() ?? "";
  if (slotKey && slotKey !== "all") {
    tags.push(`slot:${slotKey}`);
  } else if (profile.wheelSizes.length > 0) {
    tags.push(`wheel:${profile.wheelSizes[0]}`);
  }
  return tags;
}

export function shopifyCollectionPath(
  handle: string,
  tags: string[] = []
): string {
  const h = shopifyHandleize(handle) || SHOPIFY_PARTS_COLLECTION;
  const handles = tags.map(shopifyHandleize).filter(Boolean);
  if (handles.length === 0) return `/collections/${h}`;
  return `/collections/${h}/${handles.join("+")}`;
}

export function shopifyPartsFitUrl(bike: Bike, slot?: string): string {
  return `${SHOPIFY_STORE_BASE}${shopifyCollectionPath(
    SHOPIFY_PARTS_COLLECTION,
    shopifyFitTags(bike, slot)
  )}`;
}

export function shopifyMerchUrl(): string {
  return shopifyCollectionUrl(SHOPIFY_MERCH_COLLECTION);
}

export function shopifyHomeUrl(): string {
  return `${SHOPIFY_STORE_BASE}/`;
}

export function shopifyProductPageUrl(handle: string): string {
  const h = shopifyHandleize(handle);
  return h ? `${SHOPIFY_STORE_BASE}/products/${h}` : shopifyHomeUrl();
}
