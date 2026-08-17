import { NextResponse } from "next/server";
import { loadShopShelves } from "@/lib/shop/shopCatalog";
import { FEATURED_PARTS_COLLECTION } from "@/lib/shop/shopifyStorefront";
import { shopifyLangFromSearch } from "@/lib/shop/shopifyLocale";
import { isShopEnabled, isShopifyCommerceEnabled, SHOP_DISABLED_BODY } from "@/lib/shop/shopEnabled";

/**
 * GET /api/shop/parts?lang=
 * Werkstatt-Regal (garage-fit) + Merchandise (ungefiltert) aus Storefront.
 * lang: Chrome-Sprache (de/en/fr/it). Default de — kein Accept-Language.
 */
export async function GET(req: Request) {
  if (!isShopEnabled()) {
    return NextResponse.json(SHOP_DISABLED_BODY, { status: 410 });
  }
  const lang = shopifyLangFromSearch(new URL(req.url).searchParams.get("lang"));
  const result = await loadShopShelves(lang);

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
        bikes: result.bikes,
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
      shopifyCommerceEnabled: isShopifyCommerceEnabled(),
      count: result.parts.length,
      merchCount: result.merch.length,
      bikeCount: result.bikes.length,
      products: result.parts,
      merch: result.merch,
      bikes: result.bikes,
    },
    {
      headers: {
        "Cache-Control": "public, s-maxage=300, stale-while-revalidate=600",
      },
    }
  );
}
