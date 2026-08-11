import { NextResponse } from "next/server";
import { loadFeaturedParts } from "@/lib/shop/partsCatalog";
import { FEATURED_PARTS_COLLECTION } from "@/lib/shop/shopifyStorefront";

/**
 * GET /api/shop/parts
 * Live featured-parts Collection via Storefront API.
 * No demo snapshot — Production zeigt Produkte sobald Credentials gesetzt sind.
 */
export async function GET() {
  const result = await loadFeaturedParts();

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
      source: result.source,
      count: result.products.length,
      products: result.products,
    },
    {
      headers: {
        "Cache-Control": "public, s-maxage=300, stale-while-revalidate=600",
      },
    }
  );
}
