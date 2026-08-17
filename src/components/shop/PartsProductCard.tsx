"use client";

import { useState } from "react";
import Link from "next/link";
import { ChevronRight } from "lucide-react";
import { cn } from "@/lib/utils";
import type { RankedPartsProduct } from "@/lib/shop/partsCatalog";
import { dealerCtaUrl } from "@/lib/shop/merchantLinks";
import { inAppProductHref } from "@/lib/shop/storeStatus";
import { ShopifyOutboundButton } from "@/components/shop/ShopifyOutboundButton";
import { useHofCopy } from "@/hooks/useHofCopy";
import { useChromeLang } from "@/hooks/useChromeLang";
import { formatShopPrice } from "@/lib/shop/shopifyLocale";

export function PartsProductCard({
  row,
  focused,
  hideFit,
}: {
  row: RankedPartsProduct;
  focused?: boolean;
  hideFit?: boolean;
}) {
  const copy = useHofCopy();
  const lang = useChromeLang();

  const { product: p, verdict, chip } = row;
  const chipTone =
    verdict === "passt"
      ? "bg-success/15 text-success border-success/30"
      : verdict === "pruefen"
        ? "bg-warning/15 text-warning border-warning/30"
        : "bg-surface-elevated text-text-secondary border-border";
  const detailHref = inAppProductHref(p.handle);
  const dealerUrl = dealerCtaUrl(p.affiliateUrl);
  const [imgBroken, setImgBroken] = useState(false);
  const showImage = Boolean(p.imageUrl) && !imgBroken;

  return (
    <article
      id={`part-${p.handle}`}
      className={cn(
        "group flex flex-col overflow-hidden rounded-2xl border bg-surface transition hover:border-accent/40",
        focused ? "border-accent ring-1 ring-accent/40" : "border-border"
      )}
    >
      <Link href={detailHref} className="relative block aspect-[4/3] bg-surface-elevated">
        {showImage ? (
          // eslint-disable-next-line @next/next/no-img-element -- Shopify CDN
          <img
            src={p.imageUrl}
            alt={p.imageAlt || p.name}
            className="h-full w-full object-cover transition duration-300 group-hover:scale-[1.02]"
            loading="lazy"
            onError={() => setImgBroken(true)}
          />
        ) : (
          <div className="flex h-full w-full items-center justify-center text-sm text-text-secondary">
            {copy.shopNoImage}
          </div>
        )}
        {!hideFit ? (
        <span
          className={cn(
            "absolute left-2 top-2 rounded-full border px-2 py-0.5 text-[11px] font-semibold capitalize backdrop-blur-sm",
            chipTone
          )}
        >
          {chip}
        </span>
        ) : null}
      </Link>
      <div className="flex flex-1 flex-col gap-2 p-4">
        <div className="text-[11px] font-medium uppercase tracking-wide text-text-secondary">
          {p.manufacturer}
        </div>
        <Link href={detailHref}>
          <h3 className="font-semibold leading-snug hover:text-accent">{p.name}</h3>
        </Link>
        <div className="text-lg font-bold tabular-nums text-accent">
          {formatShopPrice(p.priceEur, p.currencyCode, lang)}
        </div>
        {!hideFit && row.fitLabel ? (
          <p className="text-xs font-medium text-success">{row.fitLabel}</p>
        ) : null}
        {p.description ? (
          <p className="line-clamp-2 text-xs text-text-secondary">
            {p.description}
          </p>
        ) : null}
        <Link
          href={detailHref}
          className="mt-auto inline-flex w-full items-center justify-center gap-1.5 rounded-xl bg-accent py-2.5 text-sm font-semibold text-on-accent"
        >
          {copy.shopDetails} <ChevronRight className="h-4 w-4" />
        </Link>
        {dealerUrl ? (
          <>
            <ShopifyOutboundButton
              href={dealerUrl}
              label={copy.shopZumHaendler}
              variant="ghost"
              className="py-2 text-xs font-medium"
            />
            <p className="text-center text-[11px] text-text-secondary">
              {copy.shopMerchantDisclosure}
            </p>
          </>
        ) : null}
      </div>
    </article>
  );
}
