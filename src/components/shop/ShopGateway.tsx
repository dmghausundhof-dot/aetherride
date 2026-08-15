"use client";

import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { Bike, Shirt, ExternalLink } from "lucide-react";
import { HOF_COPY } from "@/lib/home/hofCopy";
import { StoreLockedBanner } from "@/components/shop/StoreLockedBanner";
import { ShopifyOutboundButton } from "@/components/shop/ShopifyOutboundButton";
import { isRideableGarageBike } from "@/lib/shop/garageFit";
import {
  shopifyHomeUrl,
  shopifyMerchUrl,
  shopifyPartsFitUrl,
} from "@/lib/shop/shopifyGateway";
import {
  SHOPIFY_PARTS_COLLECTION,
  shopifyCollectionUrl,
} from "@/lib/shop/catalog";
import { useAppStore } from "@/store/useAppStore";

/**
 * Der Laden — two doors, Shopify only. No rebuilt catalog.
 */
export function ShopGateway() {
  const searchParams = useSearchParams();
  const bikes = useAppStore((s) => s.bikes);
  const activeBikeId = useAppStore((s) => s.activeBikeId);

  const bikeParam = searchParams.get("bike");
  const slot = searchParams.get("slot") ?? undefined;
  const door = searchParams.get("door");

  const rideable = bikes.filter((b) => isRideableGarageBike(b.category));
  const bike =
    rideable.find((b) => b.id === bikeParam) ||
    rideable.find((b) => b.id === activeBikeId) ||
    rideable[0] ||
    null;

  const partsHref = bike
    ? shopifyPartsFitUrl(bike, slot)
    : shopifyCollectionUrl(SHOPIFY_PARTS_COLLECTION);
  const merchHref = shopifyMerchUrl();
  const highlightParts = door === "parts";

  return (
    <div className="mx-auto flex w-full max-w-2xl flex-col gap-5 px-5 pb-10 pt-6 lg:max-w-3xl lg:px-10 lg:pt-10">
      <header>
        <p className="text-[11px] font-bold tracking-wide text-chrome">
          {HOF_COPY.shopKicker}
        </p>
        <h1 className="mt-1 text-2xl font-extrabold tracking-tight lg:text-3xl">
          {HOF_COPY.shopTitle}
        </h1>
        <p className="mt-2 text-sm leading-relaxed text-text-secondary">
          {HOF_COPY.shopHint}
        </p>
      </header>

      <StoreLockedBanner />

      <ShopifyOutboundButton
        href={shopifyHomeUrl()}
        label={HOF_COPY.shopGo}
        variant="primary"
      />

      {bike ? (
        <ShopDoor
          highlighted={highlightParts}
          icon={Bike}
          title={HOF_COPY.shopForYourBike}
          hint={HOF_COPY.shopForYourBikeHint(bike.name)}
          href={partsHref}
          action={HOF_COPY.shopGo}
        />
      ) : (
        <Link
          href="/garage?wizard=basic"
          className="block rounded-2xl border border-border bg-surface p-5 hover:border-chrome/40"
        >
          <div className="flex items-start gap-3">
            <Bike className="mt-0.5 h-5 w-5 shrink-0 text-chrome" />
            <div>
              <h2 className="text-base font-extrabold">
                {HOF_COPY.shopForYourBike}
              </h2>
              <p className="mt-1 text-sm text-text-secondary">
                {HOF_COPY.shopForYourBikeEmpty}
              </p>
              <p className="mt-3 text-sm font-semibold text-chrome">
                {HOF_COPY.parkBike}
              </p>
            </div>
          </div>
        </Link>
      )}

      <ShopDoor
        icon={Shirt}
        title={HOF_COPY.shopMerch}
        hint={HOF_COPY.shopMerchHint}
        href={merchHref}
        action={HOF_COPY.shopGo}
      />

      <p className="flex items-center gap-1 text-xs text-text-secondary">
        <ExternalLink className="h-3 w-3" />
        {HOF_COPY.shopCheckoutElsewhere}
      </p>
    </div>
  );
}

function ShopDoor({
  icon: Icon,
  title,
  hint,
  href,
  action,
  highlighted,
}: {
  icon: typeof Bike;
  title: string;
  hint: string;
  href: string;
  action: string;
  highlighted?: boolean;
}) {
  return (
    <section
      className={
        highlighted
          ? "rounded-2xl border border-chrome/50 bg-surface p-5"
          : "rounded-2xl border border-border bg-surface p-5"
      }
    >
      <div className="flex items-start gap-3">
        <Icon className="mt-0.5 h-5 w-5 shrink-0 text-chrome" />
        <div className="min-w-0 flex-1">
          <h2 className="text-base font-extrabold">{title}</h2>
          <p className="mt-1 text-sm text-text-secondary">{hint}</p>
          <div className="mt-4">
            <ShopifyOutboundButton href={href} label={action} variant="ghost" />
          </div>
        </div>
      </div>
    </section>
  );
}
