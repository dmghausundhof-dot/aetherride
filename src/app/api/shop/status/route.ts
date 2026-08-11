import { NextResponse } from "next/server";
import { getShopStoreStatus } from "@/lib/shop/storeStatus";

/**
 * GET /api/shop/status
 * Public booleans only — never returns storefront password or token.
 */
export async function GET() {
  const status = getShopStoreStatus();
  return NextResponse.json({
    ok: true,
    ...status,
    // Explicit: password never exposed
    storefrontPasswordInResponse: false,
  });
}
