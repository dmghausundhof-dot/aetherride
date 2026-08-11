import { NextResponse } from "next/server";
import { syncFeaturedCatalog } from "@/lib/shop/featuredSync";

/**
 * GET /api/shop/featured
 * Live featured-parts + Storefront-confirmed bike handles (404s omitted).
 */
export async function GET() {
  const result = await syncFeaturedCatalog();
  const status = result.error ? (result.configured ? 502 : 503) : 200;

  return NextResponse.json(
    {
      ok: !result.error || result.parts.length > 0 || result.bikes.length > 0,
      configured: result.configured,
      onlineStoreLocked: result.onlineStoreLocked,
      collectionHandle: result.collectionHandle,
      parts: result.parts,
      bikes: result.bikes,
      skippedHandles: result.skippedHandles,
      counts: {
        parts: result.parts.length,
        bikes: result.bikes.length,
        skipped: result.skippedHandles.length,
      },
      error: result.error,
      code: result.code,
    },
    {
      status: result.parts.length || result.bikes.length ? 200 : status,
      headers: {
        "Cache-Control": "public, s-maxage=120, stale-while-revalidate=300",
      },
    }
  );
}
