/**
 * Zwei Shop-Regale aus Storefront: Werkstatt-Teile + Merchandise.
 */

import type { ChromeLang } from "@/lib/i18n/chromeLang";
import {
  FEATURED_PARTS_COLLECTION,
  MERCHANDISE_COLLECTION,
  fetchCollectionProducts,
  fetchProductsByQuery,
  type ShopifyStorefrontProduct,
} from "@/lib/shop/shopifyStorefront";
import { mapStorefrontProduct, type PartsProduct } from "@/lib/shop/partsCatalog";
import { syncLiveFeaturedBikes, type LiveFeaturedBike } from "@/lib/shop/featuredSync";
import {
  classifyShopProduct,
  splitShopProducts,
} from "@/lib/shop/shopShelf";

export type ShopShelvesResult =
  | {
      ok: true;
      configured: true;
      parts: PartsProduct[];
      merch: PartsProduct[];
      collectionHandle: string;
      collectionTitle: string;
      merchCollectionHandle: string;
      source: "storefront";
      bikes: LiveFeaturedBike[];
    }
  | {
      ok: false;
      configured: boolean;
      parts: [];
      merch: [];
      bikes: LiveFeaturedBike[];
      collectionHandle: string;
      error: string;
      code: string;
    };

function dedupeById(
  products: ShopifyStorefrontProduct[]
): ShopifyStorefrontProduct[] {
  const seen = new Set<string>();
  const out: ShopifyStorefrontProduct[] = [];
  for (const p of products) {
    if (seen.has(p.id)) continue;
    seen.add(p.id);
    out.push(p);
  }
  return out;
}

function withCollection(
  products: ShopifyStorefrontProduct[],
  collectionHandle: string
): (ShopifyStorefrontProduct & { collectionHandle: string })[] {
  return products.map((p) => ({ ...p, collectionHandle }));
}

export async function loadShopShelves(
  lang: ChromeLang = "de"
): Promise<ShopShelvesResult> {
  const merchHandle =
    (process.env.SHOPIFY_MERCH_COLLECTION || MERCHANDISE_COLLECTION).trim() ||
    MERCHANDISE_COLLECTION;

  const [partsCol, merchCol, merchTagged, featured] = await Promise.all([
    fetchCollectionProducts(FEATURED_PARTS_COLLECTION, { lang }),
    fetchCollectionProducts(merchHandle, { lang }),
    fetchProductsByQuery("tag:merch OR tag:merchandise", { lang }),
    syncLiveFeaturedBikes(lang),
  ]);

  if (!partsCol.ok && partsCol.code === "not_configured") {
    return {
      ok: false,
      configured: false,
      parts: [],
      merch: [],
      bikes: featured.bikes,
      collectionHandle: FEATURED_PARTS_COLLECTION,
      error: partsCol.error,
      code: partsCol.code,
    };
  }

  if (!partsCol.ok) {
    return {
      ok: false,
      configured: partsCol.configured,
      parts: [],
      merch: [],
      bikes: featured.bikes,
      collectionHandle: FEATURED_PARTS_COLLECTION,
      error: partsCol.error,
      code: partsCol.code,
    };
  }

  const merchFromCollection = merchCol.ok
    ? withCollection(merchCol.products, merchHandle)
    : [];
  const merchFromTags = merchTagged.ok
    ? withCollection(merchTagged.products, merchHandle)
    : [];
  const fromParts = withCollection(partsCol.products, FEATURED_PARTS_COLLECTION);

  const classifiedParts = splitShopProducts(fromParts);
  const merchPool = dedupeById([
    ...classifiedParts.merch,
    ...merchFromCollection.filter(
      (p) => classifyShopProduct(p).shelf !== "garage_hook"
    ),
    ...merchFromTags.filter(
      (p) => classifyShopProduct(p).shelf === "merch"
    ),
  ]);

  return {
    ok: true,
    configured: true,
    parts: classifiedParts.parts.map(mapStorefrontProduct),
    merch: merchPool.map(mapStorefrontProduct),
    bikes: featured.bikes,
    collectionHandle: partsCol.collectionHandle,
    collectionTitle: partsCol.collectionTitle,
    merchCollectionHandle: merchHandle,
    source: "storefront",
  };
}
