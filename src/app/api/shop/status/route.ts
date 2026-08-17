import { NextResponse } from "next/server";
import { getShopStoreStatus } from "@/lib/shop/storeStatus";
import {
  isShopEnabled,
  isShopifyCommerceEnabled,
  SHOP_DISABLED_BODY,
} from "@/lib/shop/shopEnabled";

/**
 * GET /api/shop/status
 * Public booleans only — never returns storefront password or token.
 */
export async function GET() {
  if (!isShopEnabled()) {
    return NextResponse.json(SHOP_DISABLED_BODY, { status: 410 });
  }
  const status = getShopStoreStatus();
  return NextResponse.json({
    ok: true,
    ...status,
    shopifyCommerceEnabled: isShopifyCommerceEnabled(),
    // Explicit: password never exposed
    storefrontPasswordInResponse: false,
  });
}
