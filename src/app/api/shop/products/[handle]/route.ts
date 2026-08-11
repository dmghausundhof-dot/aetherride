import { NextResponse } from "next/server";
import { mapStorefrontProduct } from "@/lib/shop/partsCatalog";
import { fetchProductByHandle } from "@/lib/shop/shopifyStorefront";
import {
  FEATURED_PARTS_IN_APP_HREF,
  isShopifyProductHandleLive,
} from "@/lib/shop/catalog";
import { getShopStoreStatus, inAppProductHref } from "@/lib/shop/storeStatus";

type Params = { params: Promise<{ handle: string }> };

/**
 * GET /api/shop/products/[handle]
 * Live Storefront only. Unpublished Phase-A bike handles → redirect to parts.
 * Never returns a dead myshopify product URL as a success CTA.
 */
export async function GET(_req: Request, { params }: Params) {
  const { handle: raw } = await params;
  const handle = decodeURIComponent(raw || "").trim();
  if (!handle) {
    return NextResponse.json(
      { ok: false, error: "handle fehlt" },
      { status: 400 }
    );
  }

  const status = getShopStoreStatus();

  // Known unpublished editorial handles — do not 404 the page; send to collection
  if (!isShopifyProductHandleLive(handle)) {
    return NextResponse.json(
      {
        ok: false,
        configured: status.storefrontApiConfigured,
        code: "unpublished_handle",
        error:
          "Dieses Produkt ist auf Shopify noch nicht veröffentlicht. Bitte featured-parts nutzen.",
        redirectTo: FEATURED_PARTS_IN_APP_HREF,
        onlineStoreLocked: status.onlineStoreLocked,
      },
      { status: 409 }
    );
  }

  const live = await fetchProductByHandle(handle);
  if (live.ok) {
    const product = mapStorefrontProduct(live.product);
    return NextResponse.json({
      ok: true,
      source: "storefront",
      product,
      href: inAppProductHref(product.handle),
      onlineStoreLocked: status.onlineStoreLocked,
      externalUrl: product.affiliateUrl,
    });
  }

  const http =
    live.code === "not_configured" ? 503 : live.code === "not_found" ? 404 : 502;
  return NextResponse.json(
    {
      ok: false,
      configured: live.configured,
      error: live.error,
      code: live.code,
      redirectTo:
        live.code === "not_found" ? FEATURED_PARTS_IN_APP_HREF : undefined,
      onlineStoreLocked: status.onlineStoreLocked,
    },
    { status: http }
  );
}
