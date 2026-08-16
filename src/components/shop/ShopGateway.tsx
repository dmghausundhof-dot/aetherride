"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { Bike, Shirt, ExternalLink } from "lucide-react";
import { HOF_COPY } from "@/lib/home/hofCopy";
import { FLOWLINE_TAGLINE_DOTS } from "@/lib/content/brand";
import { FlowLineWordmark } from "@/components/brand/FlowLineWordmark";
import { StoreLockedBanner } from "@/components/shop/StoreLockedBanner";
import { ShopifyOutboundButton } from "@/components/shop/ShopifyOutboundButton";
import { ShopCatalogPreview } from "@/components/shop/ShopCatalogPreview";
import { inAppProductHref } from "@/lib/shop/storeStatus";
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
import type { PartsProduct } from "@/lib/shop/partsCatalog";
import { useRouter, useSearchParams } from "next/navigation";

type Shelves = {
  ok: boolean;
  products: PartsProduct[];
  merch: PartsProduct[];
};

/**
 * Der Laden — FlowLine-Regal in der App, Kasse nur bei Shopify.
 */
export function ShopGateway() {
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
  const merchHref = shopifyMerchUrl();
  const highlightParts = door === "parts";
  const merch = shelves?.merch ?? [];
  const showMerch = !shelves || !shelves.ok || merch.length > 0;

  const [reload, setReload] = useState(0);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setLoading(true);
      try {
        const res = await fetch("/api/shop/parts", { cache: "no-store" });
        const json = (await res.json()) as {
          ok?: boolean;
          products?: PartsProduct[];
          merch?: PartsProduct[];
        };
        if (cancelled) return;
        setShelves({
          ok: json.ok === true,
          products: json.products ?? [],
          merch: json.merch ?? [],
        });
      } catch {
        if (!cancelled) setShelves({ ok: false, products: [], merch: [] });
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [reload]);

  return (
    <div className="mx-auto flex w-full max-w-2xl flex-col gap-5 px-5 pb-10 pt-6 lg:max-w-3xl lg:px-10 lg:pt-10">
      <header className="space-y-3">
        <div className="overflow-hidden rounded-2xl bg-white px-4 py-3">
          {/* eslint-disable-next-line @next/next/no-img-element -- brand lockup from Logo und Bilder */}
          <img
            src="/shop/banner.jpg"
            alt="FlowLine — Outdoor · Cycling · Flow"
            className="mx-auto h-16 w-auto object-contain sm:h-20"
          />
        </div>
        <FlowLineWordmark />
        <p className="text-[11px] font-bold uppercase tracking-[0.18em] text-text-secondary">
          {FLOWLINE_TAGLINE_DOTS}
        </p>
        <p className="text-[11px] font-bold tracking-wide text-chrome">
          {HOF_COPY.shopKicker}
        </p>
        <h1 className="text-2xl font-extrabold tracking-tight lg:text-3xl">
          {HOF_COPY.shopTitle}
        </h1>
        <p className="text-sm leading-relaxed text-text-secondary">
          {HOF_COPY.shopHint}{" "}
          <Link href="/guides/laden-ohne-zweite-kasse" className="font-semibold text-chrome hover:underline">
            Wie der Laden funktioniert
          </Link>
        </p>
      </header>

      <StoreLockedBanner />

      {job === "replace" ? (
        <p className="rounded-xl bg-sage/20 px-3 py-2 text-xs font-bold text-sage">
          {HOF_COPY.shopReplaceHint}
        </p>
      ) : null}

      <ShopifyOutboundButton
        href={shopifyHomeUrl()}
        label={HOF_COPY.shopGo}
        variant="primary"
      />

      {shelves && !shelves.ok && !loading ? (
        <div className="rounded-2xl border border-border bg-surface px-4 py-3">
          <p className="text-sm text-text-secondary">
            {HOF_COPY.shopCatalogFailed}
          </p>
          <button
            type="button"
            onClick={() => setReload((n) => n + 1)}
            className="mt-2 text-sm font-extrabold text-accent"
          >
            {HOF_COPY.shopRetry}
          </button>
        </div>
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

      {showMerch ? (
        <>
          {merch.length > 0 ? (
            <section className="space-y-3">
              <h2 className="text-base font-extrabold">{HOF_COPY.shopMerch}</h2>
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
                          {HOF_COPY.shopOpenProduct}
                        </p>
                      </div>
                    </Link>
                  </li>
                ))}
              </ul>
            </section>
          ) : null}
          <ShopDoor
            icon={Shirt}
            title={HOF_COPY.shopMerch}
            hint={HOF_COPY.shopMerchHint}
            href={merchHref}
            action={HOF_COPY.shopGo}
          />
        </>
      ) : null}

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
