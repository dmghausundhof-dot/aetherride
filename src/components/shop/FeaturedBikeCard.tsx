import Link from "next/link";
import { ChevronRight } from "lucide-react";
import type { ShopProduct } from "@/lib/shop/catalog";
import {
  FEATURED_PARTS_IN_APP_HREF,
  isShopifyProductHandleLive,
  shopifyHandleFromProductId,
} from "@/lib/shop/catalog";
import { inAppProductHref } from "@/lib/shop/storeStatus";
import { ProductVisual } from "@/components/shop/ProductVisual";
import { ShopifyOutboundButton } from "@/components/shop/ShopifyOutboundButton";

/**
 * Only render for live Shopify handles.
 * Unpublished Phase-A bikes must not be shown as product CTAs (404).
 */
export function FeaturedBikeCard({ product }: { product: ShopProduct }) {
  const handle =
    shopifyHandleFromProductId(product.id) ||
    product.id.replace(/^sp-shopify-/, "");
  const live = isShopifyProductHandleLive(handle);

  if (!live) {
    // Defensive: never link dead handles — send riders to collection
    return (
      <article className="flex flex-col overflow-hidden rounded-2xl border border-dashed border-border bg-surface opacity-90">
        <div className="relative aspect-[16/10] bg-surface-elevated">
          {product.imageUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={product.imageUrl}
              alt=""
              className="h-full w-full object-cover opacity-60"
            />
          ) : (
            <div className="flex h-full items-center justify-center p-6">
              <ProductVisual product={product} className="h-20 w-20" />
            </div>
          )}
          <span className="absolute left-2 top-2 rounded-full border border-border bg-surface/90 px-2 py-0.5 text-[11px] font-semibold text-text-secondary">
            Noch nicht live
          </span>
        </div>
        <div className="flex flex-1 flex-col gap-2 p-4">
          <div className="text-[11px] font-medium uppercase tracking-wide text-text-secondary">
            {product.manufacturer}
          </div>
          <h3 className="font-semibold leading-snug text-text-secondary">
            {product.name}
          </h3>
          <p className="text-xs text-text-secondary">
            Produkt-Handle auf Shopify unveröffentlicht (404). Statt Dead-Link:
            Ersatzteile-Collection.
          </p>
          <Link
            href={FEATURED_PARTS_IN_APP_HREF}
            className="mt-auto inline-flex w-full items-center justify-center gap-1.5 rounded-xl bg-accent py-2.5 text-sm font-semibold text-white"
          >
            Zu featured-parts <ChevronRight className="h-4 w-4" />
          </Link>
        </div>
      </article>
    );
  }

  const detailHref = inAppProductHref(handle);
  const externalIsProduct =
    product.affiliateUrl.includes("/products/") &&
    !product.affiliateUrl.endsWith("/products/");

  return (
    <article className="group flex flex-col overflow-hidden rounded-2xl border border-border bg-background transition hover:border-accent/40">
      <Link
        href={detailHref}
        className="relative block aspect-[16/10] bg-surface-elevated"
      >
        {product.imageUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={product.imageUrl}
            alt={product.name}
            className="h-full w-full object-cover transition duration-300 group-hover:scale-[1.02]"
          />
        ) : (
          <div className="flex h-full items-center justify-center p-6">
            <ProductVisual product={product} className="h-20 w-20" />
          </div>
        )}
        <span className="absolute left-2 top-2 rounded-full border border-accent/30 bg-accent/90 px-2 py-0.5 text-[11px] font-semibold text-white backdrop-blur-sm">
          Featured
        </span>
      </Link>
      <div className="flex flex-1 flex-col gap-2 p-4">
        <div className="text-[11px] font-medium uppercase tracking-wide text-text-secondary">
          {product.manufacturer}
        </div>
        <Link href={detailHref}>
          <h3 className="font-semibold leading-snug hover:text-accent">
            {product.name}
          </h3>
        </Link>
        <div className="text-lg font-bold tabular-nums text-accent">
          {product.priceEur.toLocaleString("de-DE")} €
        </div>
        <p className="line-clamp-2 text-xs text-text-secondary">
          {product.description}
        </p>
        <Link
          href={detailHref}
          className="mt-auto inline-flex w-full items-center justify-center gap-1.5 rounded-xl bg-primary py-2.5 text-sm font-semibold text-white"
        >
          Details <ChevronRight className="h-4 w-4" />
        </Link>
        {externalIsProduct ? (
          <ShopifyOutboundButton
            href={product.affiliateUrl}
            label="Shopify Produkt (extern)"
            variant="ghost"
            className="py-2 text-xs font-medium"
          />
        ) : null}
      </div>
    </article>
  );
}
