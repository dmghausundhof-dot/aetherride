/**
 * Sync live featured products from Storefront API.
 * Prefer collection featured-parts; probe bike handles — skip 404s.
 */

import {
  FEATURED_BIKE_HANDLE_CANDIDATES,
  getFeaturedBikeSnapshots,
  shopifyHandleFromProductId,
  shopifyProductUrl,
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
import { merchantCtaUrl } from "@/lib/shop/merchantLinks";

export type LiveFeaturedBike = {
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

/** Probe candidate bike handles — only return Storefront-confirmed products */
export async function syncLiveFeaturedBikes(): Promise<{
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
      const live = await fetchProductByHandle(handle);
      if (!live.ok) {
        skipped.push(handle);
        return;
      }
      const mapped = mapStorefrontProduct(live.product);
      const snap = snapshotMeta(handle);
      const merchantUrl = merchantCtaUrl(
        mapped.affiliateUrl || shopifyProductUrl(handle)
      );
      bikes.push({
        handle: mapped.handle,
        name: mapped.name,
        manufacturer: mapped.manufacturer,
        priceEur: mapped.priceEur,
        currencyCode: mapped.currencyCode,
        description: mapped.description || snap?.description || "",
        imageUrl: mapped.imageUrl || snap?.imageUrl,
        href: `/shop/p/${encodeURIComponent(mapped.handle)}`,
        merchantUrl,
        sports: snap?.sports ?? [],
      });
    })
  );

  const order = FEATURED_BIKE_HANDLE_CANDIDATES as readonly string[];
  bikes.sort((a, b) => order.indexOf(a.handle) - order.indexOf(b.handle));

  return { bikes, skippedHandles: skipped };
}

export async function syncFeaturedCatalog(): Promise<FeaturedSyncResult> {
  const status = getShopStoreStatus();
  const partsResult = await fetchCollectionProducts(FEATURED_PARTS_COLLECTION);
  const { bikes, skippedHandles } = await syncLiveFeaturedBikes();

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
    parts: partsResult.products.map(mapStorefrontProduct),
    bikes,
    skippedHandles,
  };
}
