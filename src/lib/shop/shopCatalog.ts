/**
 * Zwei Shop-Regale aus Storefront: Werkstatt-Teile + Merchandise.
 */

import {
  FEATURED_PARTS_COLLECTION,
  MERCHANDISE_COLLECTION,
  fetchCollectionProducts,
  fetchProductsByQuery,
  type ShopifyStorefrontProduct,
} from "@/lib/shop/shopifyStorefront";
import { mapStorefrontProduct, type PartsProduct } from "@/lib/shop/partsCatalog";
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
    }
  | {
      ok: false;
      configured: boolean;
      parts: [];
      merch: [];
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

export async function loadShopShelves(): Promise<ShopShelvesResult> {
  const merchHandle =
    (process.env.SHOPIFY_MERCH_COLLECTION || MERCHANDISE_COLLECTION).trim() ||
    MERCHANDISE_COLLECTION;

  const [partsCol, merchCol, merchTagged] = await Promise.all([
    fetchCollectionProducts(FEATURED_PARTS_COLLECTION),
    fetchCollectionProducts(merchHandle),
    fetchProductsByQuery("tag:merch OR tag:merchandise"),
  ]);

  if (!partsCol.ok && partsCol.code === "not_configured") {
    return {
      ok: false,
      configured: false,
      parts: [],
      merch: [],
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
    collectionHandle: partsCol.collectionHandle,
    collectionTitle: partsCol.collectionTitle,
    merchCollectionHandle: merchHandle,
    source: "storefront",
  };
}
