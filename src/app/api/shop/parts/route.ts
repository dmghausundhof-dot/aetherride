import { NextResponse } from "next/server";
import { loadShopShelves } from "@/lib/shop/shopCatalog";
import { FEATURED_PARTS_COLLECTION } from "@/lib/shop/shopifyStorefront";

/**
 * GET /api/shop/parts
 * Werkstatt-Regal (garage-fit) + Merchandise (ungefiltert) aus Storefront.
 */
export async function GET() {
  const result = await loadShopShelves();

  if (!result.ok) {
    const status =
      result.code === "not_configured"
        ? 503
        : result.code === "collection_missing"
          ? 404
          : 502;
    return NextResponse.json(
      {
        ok: false,
        configured: result.configured,
        collectionHandle: result.collectionHandle || FEATURED_PARTS_COLLECTION,
        products: [],
        merch: [],
        error: result.error,
        code: result.code,
      },
      { status }
    );
  }

  return NextResponse.json(
    {
      ok: true,
      configured: true,
      collectionHandle: result.collectionHandle,
      collectionTitle: result.collectionTitle,
      merchCollectionHandle: result.merchCollectionHandle,
      source: result.source,
      count: result.parts.length,
      merchCount: result.merch.length,
      products: result.parts,
      merch: result.merch,
    },
    {
      headers: {
        "Cache-Control": "public, s-maxage=300, stale-while-revalidate=600",
      },
    }
  );
}
