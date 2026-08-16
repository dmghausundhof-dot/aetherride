"use client";

import { useState } from "react";
import Link from "next/link";
import { ChevronRight } from "lucide-react";
import type { LiveFeaturedBike } from "@/lib/shop/featuredSync";
import { dealerCtaUrl } from "@/lib/shop/merchantLinks";
import { ShopifyOutboundButton } from "@/components/shop/ShopifyOutboundButton";
import { useHofCopy } from "@/hooks/useHofCopy";
import { useChromeLang } from "@/hooks/useChromeLang";
import { formatShopPrice } from "@/lib/shop/shopifyLocale";

/** Live bike from Storefront sync — never render for 404 handles. */
export function FeaturedBikeCard({ bike }: { bike: LiveFeaturedBike }) {
  const copy = useHofCopy();
  const lang = useChromeLang();

  const [imgBroken, setImgBroken] = useState(false);
  const showImage = Boolean(bike.imageUrl) && !imgBroken;
  const dealerUrl = dealerCtaUrl(bike.merchantUrl);
  const price = formatShopPrice(bike.priceEur, bike.currencyCode || "EUR", lang);

  return (
    <article className="group flex flex-col overflow-hidden rounded-2xl border border-border bg-surface transition hover:border-accent/40">
      <Link
        href={bike.href}
        className="relative block aspect-[16/10] bg-surface-elevated"
      >
        {showImage ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={bike.imageUrl}
            alt={bike.name}
            className="h-full w-full object-cover transition duration-300 group-hover:scale-[1.02]"
            onError={() => setImgBroken(true)}
          />
        ) : (
          <div className="flex h-full items-center justify-center text-sm text-text-secondary">
            {copy.shopNoImage}
          </div>
        )}
      </Link>
      <div className="flex flex-1 flex-col gap-2 p-4">
        <div className="text-[11px] font-medium uppercase tracking-wide text-text-secondary">
          {bike.manufacturer}
        </div>
        <Link href={bike.href}>
          <h3 className="font-semibold leading-snug hover:text-accent">
            {bike.name}
          </h3>
        </Link>
        <div className="text-lg font-bold tabular-nums text-accent">{price}</div>
        {bike.description ? (
          <p className="line-clamp-2 text-xs text-text-secondary">
            {bike.description}
          </p>
        ) : null}
        <Link
          href={bike.href}
          className="mt-auto inline-flex w-full items-center justify-center gap-1.5 rounded-xl bg-accent py-2.5 text-sm font-semibold text-on-accent"
        >
          {copy.shopDetails} <ChevronRight className="h-4 w-4" />
        </Link>
        {dealerUrl ? (
          <ShopifyOutboundButton
            href={dealerUrl}
            label={copy.shopZumHaendler}
            variant="ghost"
            className="py-2 text-xs font-medium"
          />
        ) : null}
      </div>
    </article>
  );
}
