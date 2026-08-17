"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { Bike, ExternalLink } from "lucide-react";
import { useHofCopy } from "@/hooks/useHofCopy";
import { useChromeLang } from "@/hooks/useChromeLang";
import { FLOWLINE_TAGLINE_DOTS } from "@/lib/content/brand";
import { StoreLockedBanner } from "@/components/shop/StoreLockedBanner";
import { ShopifyOutboundButton } from "@/components/shop/ShopifyOutboundButton";
import { ShopCatalogPreview } from "@/components/shop/ShopCatalogPreview";
import { FeaturedBikeCard } from "@/components/shop/FeaturedBikeCard";
import { inAppProductHref } from "@/lib/shop/storeStatus";
import { isRideableGarageBike } from "@/lib/shop/garageFit";
import { shopifyHomeUrl, shopifyPartsFitUrl } from "@/lib/shop/shopifyGateway";
import {
  SHOPIFY_PARTS_COLLECTION,
  shopifyCollectionUrl,
} from "@/lib/shop/catalog";
import { useAppStore } from "@/store/useAppStore";
import type { PartsProduct } from "@/lib/shop/partsCatalog";
import type { LiveFeaturedBike } from "@/lib/shop/featuredSync";
import { useRouter, useSearchParams } from "next/navigation";

type Shelves = {
  ok: boolean;
  products: PartsProduct[];
  merch: PartsProduct[];
  bikes: LiveFeaturedBike[];
  shopifyCommerceEnabled: boolean;
};

/**
 * Der Laden — FlowLine-Regal in der App, Kasse nur bei Shopify.
 */
export function ShopGateway() {
  const copy = useHofCopy();
  const lang = useChromeLang();

  const searchParams = useSearchParams();
  const router = useRouter();
  const bikes = useAppStore((s) => s.bikes);
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const [shelves, setShelves] = useState<Shelves | null>(null);
  const [loading, setLoading] = useState(true);

  const bikeParam = searchParams.get("bike");
  const slot = searchParams.get("slot") ?? undefined;
  const door = searchParams.get("door");
  const job = searchParams.get("job");
  const focus = searchParams.get("focus")?.trim() || searchParams.get("handle")?.trim();
  const fitParam = searchParams.get("fit");
  const initialFit: "bike" | "all" =
    fitParam === "bike" || job === "replace" ? "bike" : "all";

  useEffect(() => {
    if (!focus || focus.startsWith("sp-")) return;
    router.replace(inAppProductHref(focus));
  }, [focus, router]);

  const rideable = bikes.filter((b) => isRideableGarageBike(b.category));
  const bike =
    rideable.find((b) => b.id === bikeParam) ||
    rideable.find((b) => b.id === activeBikeId) ||
    rideable[0] ||
    null;

  const partsHref = bike
    ? shopifyPartsFitUrl(bike, slot)
    : shopifyCollectionUrl(SHOPIFY_PARTS_COLLECTION);
  const merch = shelves?.merch ?? [];
  const bikesLive = shelves?.bikes ?? [];
  const catalogReady = Boolean(shelves?.ok && shelves.products.length > 0);
  const highlightParts = door === "parts";
  const shopifyLive = shelves?.shopifyCommerceEnabled === true;
  const showPartsFallback =
    Boolean(bike) && !loading && !catalogReady && shopifyLive;

  const [reload, setReload] = useState(0);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setLoading(true);
      try {
        const res = await fetch(`/api/shop/parts?lang=${lang}`, {
          cache: "no-store",
        });
        const json = (await res.json()) as {
          ok?: boolean;
          products?: PartsProduct[];
          merch?: PartsProduct[];
          bikes?: LiveFeaturedBike[];
          shopifyCommerceEnabled?: boolean;
        };
        if (cancelled) return;
        setShelves({
          ok: json.ok === true,
          products: json.products ?? [],
          merch: json.merch ?? [],
          bikes: json.bikes ?? [],
          shopifyCommerceEnabled: json.shopifyCommerceEnabled === true,
        });
      } catch {
        if (!cancelled) {
          setShelves({
            ok: false,
            products: [],
            merch: [],
            bikes: [],
            shopifyCommerceEnabled: false,
          });
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [reload, lang]);

  return (
    <div className="mx-auto flex w-full max-w-2xl flex-col gap-5 px-5 pb-10 pt-6 lg:max-w-3xl lg:px-10 lg:pt-10">
      <header className="space-y-3">
        <div className="overflow-hidden rounded-2xl bg-white px-4 py-5">
          {/* eslint-disable-next-line @next/next/no-img-element -- official lockup SVG */}
          <img
            src="/brand/logo.svg"
            alt="FlowLine — Outdoor · Cycling · Flow"
            className="mx-auto h-20 w-auto object-contain sm:h-24"
          />
        </div>
        <p className="text-[11px] font-bold tracking-[0.18em] text-text-secondary">
          {FLOWLINE_TAGLINE_DOTS}
        </p>
        <p className="text-[11px] font-bold tracking-wide text-text-secondary">
          {copy.shopKicker}
        </p>
        <h1 className="text-2xl font-extrabold tracking-tight lg:text-3xl">
          {copy.shopTitle}
        </h1>
        <p className="text-sm leading-relaxed text-text-secondary">
          {copy.shopHint}{" "}
          <Link href="/guides/laden-ohne-zweite-kasse" className="font-semibold text-chrome hover:underline">
            {copy.shopGuideHow}
          </Link>
        </p>
      </header>

      <StoreLockedBanner />

      {job === "replace" ? (
        <p className="rounded-xl bg-sage/20 px-3 py-2 text-xs font-bold text-sage">
          {copy.shopReplaceHint}
        </p>
      ) : null}

      {shopifyLive ? (
        <ShopifyOutboundButton
          href={shopifyHomeUrl()}
          label={copy.shopGo}
          variant="primary"
        />
      ) : null}

      {shelves && !shelves.ok && !loading ? (
        <div className="rounded-2xl border border-border bg-surface px-4 py-3">
          <p className="text-sm text-text-secondary">
            {copy.shopCatalogFailed}
          </p>
          <button
            type="button"
            onClick={() => setReload((n) => n + 1)}
            className="mt-2 text-sm font-extrabold text-accent"
          >
            {copy.shopRetry}
          </button>
        </div>
      ) : null}

      {bikesLive.length > 0 ? (
        <section className="space-y-3" data-testid="shop-featured-bikes">
          <h2 className="text-base font-extrabold">{copy.shopFeaturedBikes}</h2>
          <div className="grid gap-4 sm:grid-cols-2">
            {bikesLive.map((bikeCard) => (
              <FeaturedBikeCard key={bikeCard.handle} bike={bikeCard} />
            ))}
          </div>
        </section>
      ) : null}

      <ShopCatalogPreview
        products={shelves?.products ?? []}
        loading={loading}
        bikes={rideable}
        initialBikeId={bikeParam ?? undefined}
        initialSlot={slot}
        initialFit={initialFit}
      />

      {bike ? (
        showPartsFallback ? (
          <ShopDoor
            highlighted={highlightParts}
            icon={Bike}
            title={copy.shopForYourBike}
            hint={copy.shopForYourBikeHint(bike.name)}
            href={partsHref}
            action={copy.shopGo}
          />
        ) : null
      ) : (
        <Link
          href="/garage?wizard=basic"
          className="block rounded-2xl border border-border bg-surface p-5 hover:border-chrome/40"
        >
          <div className="flex items-start gap-3">
            <Bike className="mt-0.5 h-5 w-5 shrink-0 text-chrome" />
            <div>
              <h2 className="text-base font-extrabold">
                {copy.shopForYourBike}
              </h2>
              <p className="mt-1 text-sm text-text-secondary">
                {copy.shopForYourBikeEmpty}
              </p>
              <p className="mt-3 text-sm font-semibold text-chrome">
                {copy.workshopAdd}
              </p>
            </div>
          </div>
        </Link>
      )}

      {merch.length > 0 ? (
        <section className="space-y-3">
          <h2 className="text-base font-extrabold">{copy.shopMerch}</h2>
          <ul className="space-y-3">
            {merch.slice(0, 8).map((p) => (
              <li key={p.id}>
                <Link
                  href={inAppProductHref(p.handle)}
                  className="flex gap-3 rounded-2xl border border-border bg-surface p-3 hover:border-accent/40"
                >
                  <div className="h-[72px] w-[72px] shrink-0 overflow-hidden rounded-xl bg-surface-elevated">
                    {p.imageUrl ? (
                      // eslint-disable-next-line @next/next/no-img-element -- Shopify CDN
                      <img
                        src={p.imageUrl}
                        alt={p.imageAlt || p.name}
                        className="h-full w-full object-cover"
                      />
                    ) : null}
                  </div>
                  <div className="min-w-0 flex-1">
                    <h3 className="font-extrabold leading-snug">{p.name}</h3>
                    <p className="mt-1 text-sm font-extrabold text-accent">
                      {copy.shopDetails}
                    </p>
                  </div>
                </Link>
              </li>
            ))}
          </ul>
        </section>
      ) : null}

      <p className="flex items-center gap-1 text-xs text-text-secondary">
        <ExternalLink className="h-3 w-3" />
        {copy.shopCheckoutElsewhere}
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
