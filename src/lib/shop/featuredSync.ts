/**
 * Sync live featured products from Storefront API.
 * Prefer collection featured-parts; probe bike handles — skip 404s.
 */

import type { ChromeLang } from "@/lib/i18n/chromeLang";
import {
  FEATURED_BIKE_HANDLE_CANDIDATES,
  getFeaturedBikeSnapshots,
  shopifyHandleFromProductId,
  type ShopProduct,
} from "@/lib/shop/catalog";
import {
  mapStorefrontProduct,
  type PartsProduct,
} from "@/lib/shop/partsCatalog";
import {
  FEATURED_PARTS_COLLECTION,
  fetchCollectionProducts,
  fetchProductByHandle,
  isShopifyStorefrontConfigured,
} from "@/lib/shop/shopifyStorefront";
import { getShopStoreStatus } from "@/lib/shop/storeStatus";
import { dealerCtaUrl } from "@/lib/shop/merchantLinks";
import { isPartsProduct } from "@/lib/shop/shopShelf";

export type LiveFeaturedBike = {
  id?: string;
  handle: string;
  name: string;
  manufacturer: string;
  priceEur: number;
  currencyCode: string;
  description: string;
  imageUrl?: string;
  /** In-app detail */
  href: string;
  /** External Shopify product URL only when deep/live */
  merchantUrl?: string;
  sports: string[];
};

export type FeaturedSyncResult = {
  configured: boolean;
  onlineStoreLocked: boolean;
  collectionHandle: string;
  parts: PartsProduct[];
  bikes: LiveFeaturedBike[];
  skippedHandles: string[];
  error?: string;
  code?: string;
};

function snapshotMeta(handle: string): ShopProduct | undefined {
  return getFeaturedBikeSnapshots().find(
    (p) => shopifyHandleFromProductId(p.id) === handle
  );
}

/** Storefront-confirmed bike only — Snapshots füllen Lücken, erfinden keine Karten. */
export function toLiveFeaturedBike(
  mapped: PartsProduct,
  snap?: ShopProduct
): LiveFeaturedBike {
  return {
    id: mapped.id,
    handle: mapped.handle,
    name: mapped.name,
    manufacturer: mapped.manufacturer,
    priceEur: mapped.priceEur,
    currencyCode: mapped.currencyCode,
    description: mapped.description || snap?.description || "",
    imageUrl: mapped.imageUrl || snap?.imageUrl,
    href: `/shop/p/${encodeURIComponent(mapped.handle)}`,
    merchantUrl: dealerCtaUrl(mapped.affiliateUrl),
    sports: snap?.sports ?? [],
  };
}

/** Probe candidate bike handles — only return Storefront-confirmed products */
export async function syncLiveFeaturedBikes(
  lang: ChromeLang = "de"
): Promise<{
  bikes: LiveFeaturedBike[];
  skippedHandles: string[];
}> {
  const skipped: string[] = [];
  const bikes: LiveFeaturedBike[] = [];

  if (!isShopifyStorefrontConfigured()) {
    return {
      bikes: [],
      skippedHandles: [...FEATURED_BIKE_HANDLE_CANDIDATES],
    };
  }

  await Promise.all(
    FEATURED_BIKE_HANDLE_CANDIDATES.map(async (handle) => {
      const live = await fetchProductByHandle(handle, lang);
      if (!live.ok) {
        skipped.push(handle);
        return;
      }
      const mapped = mapStorefrontProduct(live.product);
      bikes.push(toLiveFeaturedBike(mapped, snapshotMeta(handle)));
    })
  );

  const order = FEATURED_BIKE_HANDLE_CANDIDATES as readonly string[];
  bikes.sort((a, b) => order.indexOf(a.handle) - order.indexOf(b.handle));

  return { bikes, skippedHandles: skipped };
}

export async function syncFeaturedCatalog(
  lang: ChromeLang = "de"
): Promise<FeaturedSyncResult> {
  const status = getShopStoreStatus();
  const partsResult = await fetchCollectionProducts(FEATURED_PARTS_COLLECTION, {
    lang,
  });
  const { bikes, skippedHandles } = await syncLiveFeaturedBikes(lang);

  if (!partsResult.ok) {
    return {
      configured: partsResult.configured,
      onlineStoreLocked: status.onlineStoreLocked,
      collectionHandle: FEATURED_PARTS_COLLECTION,
      parts: [],
      bikes,
      skippedHandles,
      error: partsResult.error,
      code: partsResult.code,
    };
  }

  return {
    configured: true,
    onlineStoreLocked: status.onlineStoreLocked,
    collectionHandle: partsResult.collectionHandle,
    parts: partsResult.products
      .map(mapStorefrontProduct)
      .filter((p) =>
        isPartsProduct({
          tags: p.tags,
          productType: p.productType,
          handle: p.handle,
          title: p.name,
        })
      ),
    bikes,
    skippedHandles,
  };
}
