"use client";

import { Suspense, useEffect, useMemo } from "react";
import {
  Bookmark,
  ChevronRight,
  ExternalLink,
  ShoppingBag,
  Store,
  Wrench,
} from "lucide-react";
import { useRouter, useSearchParams } from "next/navigation";
import { useAppStore } from "@/store/useAppStore";
import { useCartStore } from "@/store/useCartStore";
import {
  SHOPIFY_STORE_BASE,
  getFeaturedShopifyProducts,
  getShopProductByFocus,
  shopCollectionHref,
} from "@/lib/shop/catalog";
import { shopPartsHref } from "@/lib/shop/partsCatalog";
import { allProductRecommendations } from "@/lib/shop/recommendations";
import { ProductVisual } from "@/components/shop/ProductVisual";
import { GaragePartsCta } from "@/components/garage/GaragePartsCta";
import Link from "next/link";
import { cn } from "@/lib/utils";

function ShopHubInner() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const bikes = useAppStore((s) => s.bikes);
  const rides = useAppStore((s) => s.rides);
  const consents = useAppStore((s) => s.consents);
  const cartItems = useCartStore((s) => s.items);
  const activeBike = bikes.find((b) => b.id === activeBikeId) || bikes[0];
  const featuredBikes = useMemo(() => getFeaturedShopifyProducts(), []);
  const cartCount = cartItems.reduce((n, i) => n + i.quantity, 0);

  const sportQuery = searchParams.get("sport");
  const collectionUrl = sportQuery
    ? shopCollectionHref(sportQuery)
    : undefined;

  // Legacy deep-links (slot/job/focus on wear parts) → /shop/parts
  useEffect(() => {
    const slot = searchParams.get("slot");
    const job = searchParams.get("job");
    const focus = searchParams.get("focus");
    const bike = searchParams.get("bike");

    const focusProduct = focus ? getShopProductByFocus(focus) : undefined;
    const isBikeFocus = focusProduct?.slot === "frame";

    if (isBikeFocus) return;

    if (slot || job === "replace" || job === "season" || (focus && !isBikeFocus)) {
      const partsSlot =
        slot === "brake_pads_front" || slot === "brake_pads_rear"
          ? "brake_pads"
          : slot === "tire_front" || slot === "tire_rear"
            ? "tire"
            : slot || undefined;
      router.replace(
        shopPartsHref({
          slot: partsSlot,
          bike: bike || activeBike?.id,
          fit: activeBike || bike ? "bike" : undefined,
          focus: focus && !focus.startsWith("sp-") ? focus : undefined,
        })
      );
    }
  }, [searchParams, router, activeBike]);

  const productConsent =
    consents.find((c) => c.purpose === "product_recommendations")?.granted ??
    false;

  const wearRecs = useMemo(() => {
    if (!activeBike || !productConsent) return [];
    const setup = activeBike.setups.find((s) => s.isCurrent);
    return allProductRecommendations({
      bike: activeBike,
      rides,
      setup,
    }).filter((r) => r.triggerKind === "wear");
  }, [activeBike, rides, productConsent]);

  return (
    <div className="mx-auto flex w-full max-w-6xl flex-col gap-5 p-4 pt-6">
      <header className="flex items-start justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Shop</h1>
          <p className="mt-1 text-sm text-text-secondary">
            Featured Bikes & Ersatzteile aus dem AetherRide Shopify-Shop
          </p>
        </div>
        <Link
          href="/checkout"
          className="relative flex h-10 w-10 items-center justify-center rounded-full border border-border bg-surface-elevated"
          aria-label={`Merkliste${cartCount ? `, ${cartCount} Artikel` : ""}`}
        >
          <Bookmark className="h-5 w-5 text-accent" />
          {cartCount > 0 && (
            <span className="absolute -right-1 -top-1 flex h-5 min-w-5 items-center justify-center rounded-full bg-accent px-1 text-[10px] font-bold text-white">
              {cartCount}
            </span>
          )}
        </Link>
      </header>

      <GaragePartsCta bikeId={activeBike?.id} bikeName={activeBike?.name} />

      <section className="rounded-2xl border border-accent/40 bg-accent/10 p-4">
        <div className="mb-3 flex items-start gap-3">
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-accent/20 text-accent">
            <Wrench className="h-5 w-5" />
          </div>
          <div className="min-w-0 flex-1">
            <h2 className="text-lg font-bold">Ersatzteile · featured-parts</h2>
            <p className="mt-0.5 text-xs text-text-secondary">
              Live Collection (~43–48 ACTIVE) mit Soft-Fit-Tags — Beläge,
              Griffe, Fluid und mehr. Kein Snapshot.
            </p>
          </div>
        </div>
        <Link
          href={shopPartsHref({
            bike: activeBike?.id,
            fit: activeBike ? "bike" : undefined,
          })}
          className="inline-flex w-full items-center justify-center gap-2 rounded-xl bg-accent py-3 text-sm font-semibold text-white"
        >
          <ShoppingBag className="h-4 w-4" />
          Ersatzteile öffnen
          <ChevronRight className="h-4 w-4" />
        </Link>
      </section>

      {wearRecs.length > 0 ? (
        <section className="rounded-2xl border border-warning/40 bg-warning/10 p-4">
          <h3 className="mb-2 font-semibold">Dein Bike braucht Aufmerksamkeit</h3>
          <ul className="flex flex-col gap-2">
            {wearRecs.slice(0, 3).map((r) => (
              <li key={r.id}>
                <Link
                  href={shopPartsHref({
                    bike: activeBike?.id,
                    fit: "bike",
                    slot:
                      r.product.slot === "brake_pads_front" ||
                      r.product.slot === "brake_pads_rear"
                        ? "brake_pads"
                        : r.product.slot === "tire_front" ||
                            r.product.slot === "tire_rear"
                          ? "tire"
                          : r.product.slot,
                  })}
                  className="flex items-center justify-between gap-2 rounded-xl border border-border bg-surface px-3 py-2.5 text-sm"
                >
                  <span>
                    <span className="font-medium">{r.product.name}</span>
                    <span className="mt-0.5 block text-xs text-warning">
                      {r.triggeringDataPoint}
                    </span>
                  </span>
                  <ChevronRight className="h-4 w-4 shrink-0 text-accent" />
                </Link>
              </li>
            ))}
          </ul>
        </section>
      ) : null}

      <section className="rounded-2xl border border-border bg-surface p-4">
        <div className="mb-3 flex items-start gap-3">
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-primary/20 text-primary">
            <Store className="h-5 w-5" />
          </div>
          <div className="min-w-0 flex-1">
            <h2 className="text-lg font-bold">Featured · Kompletträder</h2>
            <p className="mt-0.5 text-xs text-text-secondary">
              Checkout auf dem Shopify-Storefront (
              {SHOPIFY_STORE_BASE.replace("https://", "")}).
            </p>
          </div>
        </div>
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {featuredBikes.map((p) => (
            <div
              key={p.id}
              className="rounded-2xl border border-border bg-background p-4"
            >
              <div className="flex gap-3">
                <ProductVisual product={p} />
                <div className="min-w-0 flex-1">
                  <div className="text-xs uppercase tracking-wide text-accent">
                    AetherRide Shop
                  </div>
                  <div className="text-xs uppercase tracking-wide text-text-secondary">
                    {p.manufacturer}
                  </div>
                  <h3 className="mt-0.5 font-semibold leading-snug">{p.name}</h3>
                  <div className="mt-1 text-lg font-bold tabular-nums text-accent">
                    {p.priceEur.toLocaleString("de-DE")} €
                  </div>
                </div>
              </div>
              <a
                href={p.affiliateUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="mt-3 inline-flex w-full items-center justify-center gap-1 rounded-xl bg-primary py-2.5 text-sm font-semibold text-white"
              >
                Im Shopify-Shop öffnen <ExternalLink className="h-3.5 w-3.5" />
              </a>
            </div>
          ))}
        </div>
      </section>

      {collectionUrl ? (
        <div className="rounded-xl border border-primary/40 bg-primary/10 px-4 py-3 text-sm">
          <p className="font-medium text-primary">
            Collection für „{sportQuery}“
          </p>
          <a
            href={collectionUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="mt-2 inline-flex items-center gap-1 rounded-lg bg-primary px-3 py-2 text-xs font-semibold text-white"
          >
            Collection öffnen <ExternalLink className="h-3.5 w-3.5" />
          </a>
        </div>
      ) : null}

      {!activeBike ? (
        <div className="rounded-2xl border border-border bg-surface p-4 text-center">
          <p className="text-sm font-medium">Passende Teile nach deinem Bike</p>
          <p className="mt-1 text-xs text-text-secondary">
            Lege ein Bike an — Soft-Fit filtert Magura-Form, Größe und
            Schalt-Kompatibilität.
          </p>
          <Link
            href="/garage?wizard=catalog"
            className="mt-3 inline-flex rounded-xl bg-accent px-4 py-2 text-sm font-semibold text-white"
          >
            Bike anlegen
          </Link>
        </div>
      ) : null}

      <p className="text-center text-xs text-text-secondary">
        Hub: Bikes hier · Ersatzteile unter{" "}
        <Link href="/shop/parts" className={cn("text-accent")}>
          /shop/parts
        </Link>
      </p>
    </div>
  );
}

export default function ShopPage() {
  return (
    <Suspense
      fallback={
        <div className="p-6 text-center text-sm text-text-secondary">
          Shop wird geladen…
        </div>
      }
    >
      <ShopHubInner />
    </Suspense>
  );
}
