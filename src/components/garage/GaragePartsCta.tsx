"use client";

import { ShoppingBag, ChevronRight } from "lucide-react";
import {
  SHOPIFY_PARTS_COLLECTION,
  shopifyCollectionUrl,
} from "@/lib/shop/catalog";
import { shopifyPartsFitUrl } from "@/lib/shop/shopifyGateway";
import { ShopifyOutboundButton } from "@/components/shop/ShopifyOutboundButton";
import { useAppStore } from "@/store/useAppStore";
import { HOF_COPY } from "@/lib/home/hofCopy";

/** Werkstatt → Shopify-Fit-Collection, kein In-App-Katalog. */
export function GaragePartsCta({
  bikeId,
  bikeName,
  className,
}: {
  bikeId?: string | null;
  bikeName?: string | null;
  className?: string;
}) {
  const bikes = useAppStore((s) => s.bikes);
  const bike = bikeId ? bikes.find((b) => b.id === bikeId) : undefined;
  const href = bike
    ? shopifyPartsFitUrl(bike)
    : shopifyCollectionUrl(SHOPIFY_PARTS_COLLECTION);

  return (
    <div
      className={
        className ?? "rounded-2xl border border-border bg-surface p-4"
      }
      data-testid="garage-parts-cta"
    >
      <div className="mb-3 flex items-start gap-3">
        <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-chrome/15 text-chrome">
          <ShoppingBag className="h-5 w-5" />
        </div>
        <div className="min-w-0 flex-1">
          <div className="font-semibold">{HOF_COPY.shopForYourBike}</div>
          <p className="mt-0.5 text-xs text-text-secondary">
            {bikeName
              ? HOF_COPY.shopForYourBikeHint(bikeName)
              : HOF_COPY.shopHint}
          </p>
        </div>
        <ChevronRight className="mt-1 h-5 w-5 shrink-0 text-text-secondary" />
      </div>
      <ShopifyOutboundButton
        href={href}
        label={HOF_COPY.shopGo}
        variant="ghost"
      />
    </div>
  );
}
