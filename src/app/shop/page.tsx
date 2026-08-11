"use client";

import { Suspense, useEffect, useMemo, useState } from "react";
import {
  Bookmark,
  ExternalLink,
  ShoppingBag,
  Sparkles,
  Store,
  Wrench,
} from "lucide-react";
import { useSearchParams } from "next/navigation";
import { useAppStore } from "@/store/useAppStore";
import { useCartStore } from "@/store/useCartStore";
import {
  SHOP_BROWSE_SLOTS,
  SHOP_PRODUCTS,
  SHOP_SPORT_FILTERS,
  SHOPIFY_STORE_BASE,
  getFeaturedShopifyProducts,
  getShopProductByFocus,
  isProductAffiliateUrl,
  productMatchesSport,
  shopCollectionHref,
  shopSportFromBikeCategory,
  shopSportFromQuery,
  type ShopProduct,
  type ShopSport,
} from "@/lib/shop/catalog";
import { allProductRecommendations } from "@/lib/shop/recommendations";
import {
  getMarketplaceLegal,
  buildMarketplaceDraft,
} from "@/lib/shop/marketplace";
import {
  aggregateVerdict,
  checkCandidateOnBike,
} from "@/lib/compatibility/engine";
import { VerdictPill } from "@/components/garage/VerdictPill";
import { ProductVisual } from "@/components/shop/ProductVisual";
import { slotLabel } from "@/lib/catalog/slots";
import type { CompatibilityVerdict, ComponentSlot } from "@/types";
import Link from "next/link";
import { cn } from "@/lib/utils";

type JobId = "replace" | "browse" | "season";
type SlotFilter = ComponentSlot | "all";

type RankedProduct = {
  product: ShopProduct;
  verdict: CompatibilityVerdict;
  results: ReturnType<typeof checkCandidateOnBike>;
};

function isBrowseSlot(value: string | null): value is SlotFilter {
  if (!value) return false;
  return SHOP_BROWSE_SLOTS.some((s) => s.slot === value);
}

function matchesSlotFilter(product: ShopProduct, filter: SlotFilter): boolean {
  if (filter === "all") return true;
  if (filter === "brake_pads_front") {
    return (
      product.slot === "brake_pads_front" || product.slot === "brake_pads_rear"
    );
  }
  if (filter === "tire_front") {
    return product.slot === "tire_front" || product.slot === "tire_rear";
  }
  return product.slot === filter;
}

function ShopPageInner() {
  const searchParams = useSearchParams();
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const bikes = useAppStore((s) => s.bikes);
  const rides = useAppStore((s) => s.rides);
  const consents = useAppStore((s) => s.consents);
  const commerceMode = useAppStore((s) => s.commerceMode);
  const setCommerceMode = useAppStore((s) => s.setCommerceMode);
  const addItem = useCartStore((s) => s.addItem);
  const cartItems = useCartStore((s) => s.items);
  const activeBike = bikes.find((b) => b.id === activeBikeId) || bikes[0];
  const [hideIncompatible, setHideIncompatible] = useState(true);
  const [legalOk, setLegalOk] = useState(false);
  const [slotFilter, setSlotFilter] = useState<SlotFilter>("all");
  const [sportFilter, setSportFilter] = useState<ShopSport>("all");
  const [job, setJob] = useState<JobId>("browse");
  const [focusId, setFocusId] = useState<string | null>(null);
  const legal = getMarketplaceLegal();
  const marketplaceEnabled =
    process.env.NEXT_PUBLIC_MARKETPLACE_ENABLED === "true";

  const productConsent =
    consents.find((c) => c.purpose === "product_recommendations")?.granted ??
    false;

  const sportQuery = searchParams.get("sport");
  const collectionUrl = sportQuery
    ? shopCollectionHref(sportQuery)
    : undefined;
  const featuredBikes = useMemo(() => getFeaturedShopifyProducts(), []);

  useEffect(() => {
    const focus = searchParams.get("focus");
    const slot = searchParams.get("slot");
    const jobParam = searchParams.get("job");
    const mappedSport = shopSportFromQuery(searchParams.get("sport"));

    if (focus) {
      const p = getShopProductByFocus(focus);
      if (p) {
        setFocusId(p.id);
        const browseMatch = SHOP_BROWSE_SLOTS.find(
          (s) =>
            s.slot === p.slot ||
            (s.slot === "brake_pads_front" &&
              (p.slot === "brake_pads_front" || p.slot === "brake_pads_rear")) ||
            (s.slot === "tire_front" &&
              (p.slot === "tire_front" || p.slot === "tire_rear"))
        );
        // Kompletträder (frame) bleiben bei "Alle" — Featured-Sektion highlightet
        if (browseMatch && browseMatch.slot !== "all" && p.slot !== "frame") {
          setSlotFilter(browseMatch.slot);
        }
      }
    }
    if (isBrowseSlot(slot)) {
      setSlotFilter(slot);
    }
    if (mappedSport) {
      setSportFilter(mappedSport);
    } else if (!searchParams.get("sport") && activeBike) {
      setSportFilter(shopSportFromBikeCategory(activeBike.category));
    }
    if (jobParam === "replace" || jobParam === "browse" || jobParam === "season") {
      setJob(jobParam);
    } else if (focus || slot) {
      const focused = focus ? getShopProductByFocus(focus) : undefined;
      // Shopify-Bikes → browse; Verschleiß-Teile → replace
      setJob(focused?.slot === "frame" ? "browse" : slot || focus ? "replace" : "browse");
    }
  }, [searchParams, activeBike]);

  useEffect(() => {
    if (!focusId) return;
    const el = document.getElementById(`product-${focusId}`);
    const featuredEl = document.getElementById(`featured-${focusId}`);
    (featuredEl ?? el)?.scrollIntoView({ behavior: "smooth", block: "center" });
  }, [focusId]);

  const triggered = useMemo(() => {
    if (!activeBike || !productConsent) return [];
    const setup = activeBike.setups.find((s) => s.isCurrent);
    return allProductRecommendations({
      bike: activeBike,
      rides,
      setup,
    });
  }, [activeBike, rides, productConsent]);

  const wearRecs = useMemo(
    () => triggered.filter((r) => r.triggerKind === "wear"),
    [triggered]
  );
  const seasonRecs = useMemo(
    () => triggered.filter((r) => r.triggerKind === "season"),
    [triggered]
  );

  const rankedAll = useMemo((): RankedProduct[] => {
    if (!activeBike) {
      return SHOP_PRODUCTS.map((product) => ({
        product,
        verdict: "INSUFFICIENT_DATA" as const,
        results: [],
      }));
    }
    return SHOP_PRODUCTS.map((p) => {
      const results = checkCandidateOnBike(
        activeBike,
        p.slot,
        p.componentModelId
      );
      const verdict: CompatibilityVerdict = results.length
        ? aggregateVerdict(results)
        : "INSUFFICIENT_DATA";
      return { product: p, verdict, results };
    });
  }, [activeBike]);

  const featuredIds = useMemo(
    () => new Set(featuredBikes.map((p) => p.id)),
    [featuredBikes]
  );

  const ranked = useMemo(() => {
    let list = rankedAll.filter(
      (row) =>
        !featuredIds.has(row.product.id) &&
        matchesSlotFilter(row.product, slotFilter) &&
        productMatchesSport(row.product, sportFilter)
    );
    if (hideIncompatible) {
      list = list.filter((row) => row.verdict !== "INCOMPATIBLE");
    }
    if (job === "replace") {
      const wearIds = new Set(wearRecs.map((r) => r.product.id));
      const wearSlots = new Set(wearRecs.map((r) => r.product.slot));
      list = list.filter(
        (row) =>
          wearIds.has(row.product.id) ||
          wearSlots.has(row.product.slot) ||
          row.product.slot === "chain" ||
          row.product.slot === "brake_pads_front" ||
          row.product.slot === "cassette" ||
          row.product.slot === "tire_front" ||
          row.product.slot === "tire_rear"
      );
    }
    if (job === "season") {
      const seasonIds = new Set(seasonRecs.map((r) => r.product.id));
      list = list.filter(
        (row) =>
          seasonIds.has(row.product.id) ||
          row.product.slot === "tire_front" ||
          row.product.slot === "tire_rear"
      );
    }
    if (focusId) {
      list = [...list].sort((a, b) => {
        if (a.product.id === focusId) return -1;
        if (b.product.id === focusId) return 1;
        return 0;
      });
    }
    return list;
  }, [
    rankedAll,
    featuredIds,
    slotFilter,
    sportFilter,
    hideIncompatible,
    job,
    wearRecs,
    seasonRecs,
    focusId,
  ]);

  const alternativesFor = (row: RankedProduct): RankedProduct[] => {
    if (row.verdict === "COMPATIBLE") return [];
    return rankedAll
      .filter(
        (alt) =>
          alt.product.id !== row.product.id &&
          alt.product.slot === row.product.slot &&
          alt.verdict === "COMPATIBLE"
      )
      .slice(0, 2);
  };

  const draft = buildMarketplaceDraft(
    cartItems.map((i) => ({
      name: i.name,
      priceEur: i.price,
      qty: i.quantity,
    }))
  );

  const cartCount = cartItems.reduce((n, i) => n + i.quantity, 0);

  const addToList = (p: ShopProduct, verdict: CompatibilityVerdict) => {
    addItem({
      productId: p.id,
      name: p.name,
      manufacturer: p.manufacturer,
      price: p.priceEur,
      quantity: 1,
      compatibilityMatch: verdict === "COMPATIBLE",
      verdict,
      affiliateUrl: p.affiliateUrl,
      merchantName: p.merchantName,
    });
  };

  return (
    <div className="flex flex-col gap-5 p-4 pt-6 max-w-6xl mx-auto w-full">
      <header className="flex items-start justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold">Shop</h1>
          <p className="text-sm text-text-secondary">
            Featured Bikes im AetherRide Shopify-Shop ·{" "}
            <Link href="/shop/parts" className="text-accent">
              Ersatzteile
            </Link>
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

      <section className="rounded-2xl border border-accent/40 bg-accent/10 p-4">
        <div className="mb-3 flex items-start gap-3">
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-accent/20 text-accent">
            <Store className="h-5 w-5" />
          </div>
          <div className="min-w-0 flex-1">
            <h2 className="text-lg font-bold">Featured · AetherRide Shop</h2>
            <p className="mt-0.5 text-xs text-text-secondary">
              Kompletträder mit Testpreisen. Checkout erfolgt auf dem Shopify-
              Storefront ({SHOPIFY_STORE_BASE.replace("https://", "")}) —
              der Store kann passwortgeschützt sein (Shopify Admin →
              Online Store → Preferences).
            </p>
          </div>
        </div>
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {featuredBikes.map((p) => {
            const focused = focusId === p.id;
            return (
              <div
                key={p.id}
                id={`featured-${p.id}`}
                className={cn(
                  "rounded-2xl border bg-surface p-4",
                  focused
                    ? "border-accent ring-1 ring-accent/40"
                    : "border-border"
                )}
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
                <p className="mt-2 text-xs text-text-secondary">{p.description}</p>
                <a
                  href={p.affiliateUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="mt-3 inline-flex w-full items-center justify-center gap-1 rounded-xl bg-accent py-2.5 text-sm font-semibold text-white"
                >
                  Im Shopify-Shop öffnen{" "}
                  <ExternalLink className="h-3.5 w-3.5" />
                </a>
              </div>
            );
          })}
        </div>
      </section>

      {collectionUrl || sportQuery === "parts" ? (
        <div className="rounded-xl border border-primary/40 bg-primary/10 px-4 py-3 text-sm">
          <p className="font-medium text-primary">
            {sportQuery === "parts"
              ? "Ersatzteile · featured-parts"
              : `Collection für „${sportQuery}“`}
          </p>
          <p className="mt-1 text-xs text-text-secondary">
            In-App stöbern — externe Storefront-Homepages entfallen.
          </p>
          <Link
            href="/shop/parts"
            className="mt-2 inline-flex items-center gap-1 rounded-lg bg-primary px-3 py-2 text-xs font-semibold text-white"
          >
            Ersatzteile öffnen
          </Link>
        </div>
      ) : null}

      {activeBike ? (
        <div className="flex items-center justify-between gap-2 rounded-xl border border-accent/30 bg-accent/10 px-3 py-2 text-sm">
          <div>
            <span className="font-medium text-accent">Für dein Bike: </span>
            {activeBike.name}
          </div>
          <Link href="/garage" className="shrink-0 text-xs text-accent">
            Wechseln
          </Link>
        </div>
      ) : (
        <div className="rounded-2xl border border-border bg-surface p-4 text-center">
          <p className="text-sm font-medium">Passende Teile nach deinem Bike</p>
          <p className="mt-1 text-xs text-text-secondary">
            Lege ein Bike an — dann filtern wir nach Kompatibilität statt nach
            Rätselraten.
          </p>
          <Link
            href="/garage?wizard=catalog"
            className="mt-3 inline-flex rounded-xl bg-accent px-4 py-2 text-sm font-semibold text-white"
          >
            Bike anlegen
          </Link>
        </div>
      )}

      {!activeBike ? (
        <section className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          <p className="text-xs text-text-secondary sm:col-span-2 lg:col-span-3">
            Beispiele aus dem Beispielkatalog (ohne Kompat-Prüfung):
          </p>
          {SHOP_PRODUCTS.slice(0, 4).map((p) => (
            <div
              key={p.id}
              className="rounded-2xl border border-border bg-surface p-4"
            >
              <div className="flex gap-3">
                <ProductVisual product={p} />
                <div className="min-w-0 flex-1">
                  <div className="text-xs uppercase tracking-wide text-text-secondary">
                    {p.manufacturer}
                  </div>
                  <h3 className="mt-0.5 font-semibold leading-snug">{p.name}</h3>
                  <div className="mt-1 text-lg font-bold tabular-nums text-accent">
                    {p.priceEur.toLocaleString("de-DE")} €
                  </div>
                </div>
              </div>
              {isProductAffiliateUrl(p.affiliateUrl) ? (
                <a
                  href={p.affiliateUrl}
                  target="_blank"
                  rel="noreferrer"
                  className="mt-3 inline-flex w-full items-center justify-center gap-1 rounded-xl bg-accent py-2.5 text-sm font-semibold text-white"
                >
                  Zum Produkt <ExternalLink className="h-3.5 w-3.5" />
                </a>
              ) : (
                <p className="mt-3 rounded-xl border border-dashed border-border px-3 py-2 text-center text-xs text-text-secondary">
                  Kein Produkt-Link (Händler-Homepage entfernt)
                </p>
              )}
            </div>
          ))}
        </section>
      ) : null}

      {activeBike ? (
      <>
      <div className="grid grid-cols-3 gap-2">
        {(
          [
            ["replace", "Jetzt ersetzen", Wrench],
            ["browse", "Alle Teile", ShoppingBag],
            ["season", "Saison", Sparkles],
          ] as const
        ).map(([id, label, Icon]) => (
          <button
            key={id}
            type="button"
            onClick={() => setJob(id)}
            className={cn(
              "flex flex-col items-center gap-1 rounded-xl py-2.5 text-xs font-medium",
              job === id
                ? "bg-accent text-white"
                : "bg-surface-elevated text-text-secondary"
            )}
          >
            <Icon className="h-4 w-4" />
            {label}
          </button>
        ))}
      </div>

      {job === "replace" && productConsent && wearRecs.length > 0 && (
        <section className="rounded-2xl border border-warning/40 bg-warning/10 p-4">
          <h3 className="mb-2 flex items-center gap-2 font-semibold">
            <Sparkles className="h-4 w-4" /> Dein Bike braucht Aufmerksamkeit
          </h3>
          {wearRecs.map((r) => (
            <div
              key={r.id}
              className="mb-2 flex gap-3 rounded-xl border border-border bg-surface p-3 text-sm"
            >
              <ProductVisual product={r.product} compact />
              <div className="min-w-0 flex-1">
                <div className="font-medium">{r.product.name}</div>
                <p className="mt-1 text-xs text-warning">
                  Auslöser: {r.triggeringDataPoint}
                </p>
                <p className="mt-1 text-xs text-text-secondary">{r.reason}</p>
              </div>
            </div>
          ))}
        </section>
      )}

      <div>
        <p className="mb-1.5 text-[10px] font-semibold uppercase tracking-wide text-text-secondary">
          Disziplin
        </p>
        <div className="flex gap-2 overflow-x-auto pb-1">
          {SHOP_SPORT_FILTERS.map((s) => (
            <button
              key={s.id}
              type="button"
              onClick={() => setSportFilter(s.id)}
              className={cn(
                "shrink-0 rounded-full px-3 py-1.5 text-xs font-medium",
                sportFilter === s.id
                  ? "bg-primary text-white"
                  : "bg-surface-elevated text-text-secondary"
              )}
            >
              {s.label}
            </button>
          ))}
        </div>
      </div>

      <div>
        <p className="mb-1.5 text-[10px] font-semibold uppercase tracking-wide text-text-secondary">
          Kategorie
        </p>
        <div className="flex gap-2 overflow-x-auto pb-1">
          {SHOP_BROWSE_SLOTS.map((s) => (
            <button
              key={s.slot}
              type="button"
              onClick={() => setSlotFilter(s.slot)}
              className={cn(
                "shrink-0 rounded-full px-3 py-1.5 text-xs font-medium",
                slotFilter === s.slot
                  ? "bg-accent text-white"
                  : "bg-surface-elevated text-text-secondary"
              )}
            >
              {s.label}
            </button>
          ))}
        </div>
      </div>

      <label className="flex items-center gap-2 text-sm text-text-secondary">
        <input
          type="checkbox"
          checked={hideIncompatible}
          onChange={(e) => setHideIncompatible(e.target.checked)}
        />
        Inkompatible ausblenden (Kompat-Engine)
      </label>

      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {ranked.length === 0 ? (
          <p className="rounded-xl border border-dashed border-border p-4 text-center text-sm text-text-secondary sm:col-span-2 lg:col-span-3">
            Keine Teile in diesem Filter — Slot wechseln oder Inkompatible
            einblenden.
          </p>
        ) : (
          ranked.map((row) => {
            const { product: p, verdict, results } = row;
            const alts = alternativesFor(row);
            const focused = focusId === p.id;
            return (
              <div
                key={p.id}
                id={`product-${p.id}`}
                className={cn(
                  "rounded-2xl border bg-surface p-4",
                  focused ? "border-accent ring-1 ring-accent/40" : "border-border"
                )}
              >
                <div className="flex gap-3">
                  <ProductVisual product={p} />
                  <div className="min-w-0 flex-1">
                    <div className="mb-1 flex items-start justify-between gap-2">
                      <VerdictPill verdict={verdict} />
                      <span className="text-xs text-text-secondary">
                        {slotLabel(p.slot)}
                      </span>
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
                <p className="mt-3 text-xs text-text-secondary">{p.description}</p>
                <div className="mt-3 flex gap-2">
                  <button
                    type="button"
                    disabled={verdict === "INCOMPATIBLE"}
                    onClick={() => addToList(p, verdict)}
                    className="flex-1 rounded-xl border border-border py-2.5 text-sm font-medium disabled:opacity-40"
                  >
                    Merken
                  </button>
                  {isProductAffiliateUrl(p.affiliateUrl) ? (
                    <a
                      href={p.affiliateUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex flex-[2] items-center justify-center gap-2 rounded-xl bg-accent py-2.5 text-sm font-semibold text-white"
                    >
                      Zum Produkt <ExternalLink className="h-4 w-4" />
                    </a>
                  ) : (
                    <span className="flex flex-[2] items-center justify-center rounded-xl border border-dashed border-border px-2 text-center text-xs text-text-secondary">
                      Produkt-URL folgt
                    </span>
                  )}
                </div>
              </div>
            );
          })
        )}
      </div>

      </>
      ) : null}

      <p className="text-center text-xs text-text-secondary">
        Featured-Bikes: Checkout auf Shopify ·{" "}
        <Link href="/shop/parts" className="text-accent">
          /shop/parts
        </Link>{" "}
        ·{" "}
        <Link href="/checkout" className="text-accent">
          Merkliste öffnen
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
      <ShopPageInner />
    </Suspense>
  );
}
