import { NextResponse } from "next/server";
import { mapStorefrontProduct } from "@/lib/shop/partsCatalog";
import { fetchProductByHandle } from "@/lib/shop/shopifyStorefront";
import {
  getFeaturedShopifyProducts,
  shopifyHandleFromProductId,
} from "@/lib/shop/catalog";
import { getShopStoreStatus, inAppProductHref } from "@/lib/shop/storeStatus";

type Params = { params: Promise<{ handle: string }> };

/**
 * GET /api/shop/products/[handle]
 * Prefers Storefront API; falls back to featured-bike snapshot metadata
 * (still no myshopify checkout when store locked).
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

  // Featured bikes snapshot (Phase A) — display only
  const featured = getFeaturedShopifyProducts().find(
    (p) =>
      shopifyHandleFromProductId(p.id) === handle ||
      p.id === handle ||
      p.id === `sp-shopify-${handle}`
  );
  if (featured) {
    return NextResponse.json({
      ok: true,
      source: "featured_snapshot",
      product: {
        id: featured.id,
        handle: shopifyHandleFromProductId(featured.id) || handle,
        name: featured.name,
        manufacturer: featured.manufacturer,
        productType: "Bike",
        description: featured.description,
        priceEur: featured.priceEur,
        currencyCode: "EUR",
        imageUrl: featured.imageUrl,
        availableForSale: true,
        affiliateUrl: featured.affiliateUrl,
        tags: ["slot:frame", ...(featured.sports || []).map((s) => `sport:${s}`)],
        softFit: { slots: ["frame"], calipers: [], shiftCompat: [], raw: [] },
        slotKey: "frame",
      },
      href: inAppProductHref(shopifyHandleFromProductId(featured.id) || handle),
      onlineStoreLocked: status.onlineStoreLocked,
      externalUrl: featured.affiliateUrl,
      warning:
        live.code === "not_configured"
          ? "Storefront API nicht konfiguriert — Snapshot-Metadaten."
          : live.error,
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
      onlineStoreLocked: status.onlineStoreLocked,
    },
    { status: http }
  );
}
