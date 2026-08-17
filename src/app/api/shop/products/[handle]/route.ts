import { NextResponse } from "next/server";
import { FEATURED_PARTS_IN_APP_HREF } from "@/lib/shop/catalog";
import {
  getEditorialProductByHandle,
  mapStorefrontProduct,
} from "@/lib/shop/partsCatalog";
import { dealerCtaUrl, merchantCtaUrl } from "@/lib/shop/merchantLinks";
import { fetchProductByHandle } from "@/lib/shop/shopifyStorefront";
import { shopifyLangFromSearch } from "@/lib/shop/shopifyLocale";
import { getShopStoreStatus, inAppProductHref } from "@/lib/shop/storeStatus";
import {
  isShopEnabled,
  isShopifyCommerceEnabled,
  SHOP_DISABLED_BODY,
} from "@/lib/shop/shopEnabled";

type Params = { params: Promise<{ handle: string }> };

/**
 * GET /api/shop/products/[handle]
 * Affiliate-editorial when Shopify commerce is off.
 * Storefront when SHOPIFY_COMMERCE_ENABLED=true. Missing → redirectTo /shop.
 */
export async function GET(req: Request, { params }: Params) {
  if (!isShopEnabled()) {
    return NextResponse.json(SHOP_DISABLED_BODY, { status: 410 });
  }
  const { handle: raw } = await params;
  const handle = decodeURIComponent(raw || "").trim();
  const lang = shopifyLangFromSearch(new URL(req.url).searchParams.get("lang"));
  if (!handle) {
    return NextResponse.json(
      { ok: false, error: "handle fehlt" },
      { status: 400 }
    );
  }

  const status = getShopStoreStatus();
  const shopifyLive = isShopifyCommerceEnabled();

  if (!shopifyLive) {
    const editorial = getEditorialProductByHandle(handle);
    if (!editorial) {
      return NextResponse.json(
        {
          ok: false,
          configured: true,
          code: "not_found",
          error: `Produkt „${handle}“ nicht im Affiliate-Regal.`,
          redirectTo: FEATURED_PARTS_IN_APP_HREF,
          onlineStoreLocked: status.onlineStoreLocked,
          shopifyCommerceEnabled: false,
        },
        { status: 404 }
      );
    }
    return NextResponse.json({
      ok: true,
      source: "affiliate",
      product: editorial,
      href: inAppProductHref(editorial.handle),
      onlineStoreLocked: status.onlineStoreLocked,
      shopifyCommerceEnabled: false,
      externalUrl: dealerCtaUrl(editorial.affiliateUrl),
    });
  }

  const live = await fetchProductByHandle(handle, lang);

  if (live.ok) {
    const product = mapStorefrontProduct(live.product);
    return NextResponse.json({
      ok: true,
      source: "storefront",
      product,
      href: inAppProductHref(product.handle),
      onlineStoreLocked: status.onlineStoreLocked,
      shopifyCommerceEnabled: true,
      externalUrl: merchantCtaUrl(product.affiliateUrl),
    });
  }

  if (live.code === "not_found") {
    return NextResponse.json(
      {
        ok: false,
        configured: live.configured,
        code: "not_found",
        error: `Produkt „${handle}“ nicht in Shopify (oder nicht published).`,
        redirectTo: FEATURED_PARTS_IN_APP_HREF,
        onlineStoreLocked: status.onlineStoreLocked,
      },
      { status: 404 }
    );
  }

  const http = live.code === "not_configured" ? 503 : 502;
  return NextResponse.json(
    {
      ok: false,
      configured: live.configured,
      error: live.error,
      code: live.code,
      redirectTo: FEATURED_PARTS_IN_APP_HREF,
      onlineStoreLocked: status.onlineStoreLocked,
    },
    { status: http }
  );
}
