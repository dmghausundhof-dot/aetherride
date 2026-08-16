"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { Search } from "lucide-react";
import type { Bike } from "@/types";
import type { PartsProduct } from "@/lib/shop/partsCatalog";
import { filterAndRankParts } from "@/lib/shop/partsCatalog";
import { softFitInputsFromBikes } from "@/lib/shop/garageFit";
import { inAppProductHref } from "@/lib/shop/storeStatus";
import { PARTS_BROWSE_SLOTS, parseSoftFitTags } from "@/lib/shop/softFit";
import { HOF_COPY } from "@/lib/home/hofCopy";
import { PartsSkeleton } from "@/components/shop/PartsSkeleton";

function hydrate(p: PartsProduct): PartsProduct {
  const tags = p.tags ?? [];
  return {
    ...p,
    tags,
    softFit: p.softFit ?? parseSoftFitTags(tags),
    slotKey: p.slotKey || "other",
  };
}

function formatPrice(eur: number, currency: string): string {
  try {
    return new Intl.NumberFormat("de-DE", {
      style: "currency",
      currency: currency || "EUR",
    }).format(eur);
  } catch {
    return `${eur.toLocaleString("de-DE")} €`;
  }
}

export function ShopCatalogPreview({
  products,
  loading,
  bikes,
  initialBikeId,
  initialSlot,
  initialFit,
}: {
  products: PartsProduct[];
  loading: boolean;
  bikes: Bike[];
  initialBikeId?: string;
  initialSlot?: string;
  initialFit?: "bike" | "all";
}) {
  const [q, setQ] = useState("");
  const [slot, setSlot] = useState(
    initialSlot && initialSlot !== "all" ? initialSlot : "all"
  );
  const [bikeId, setBikeId] = useState(
    initialBikeId && initialBikeId.length > 0 ? initialBikeId : "all"
  );
  const [fitMode, setFitMode] = useState<"bike" | "all">(
    initialFit === "bike" ? "bike" : "all"
  );
  useEffect(() => {
    if (initialSlot && initialSlot !== "all") setSlot(initialSlot);
  }, [initialSlot]);
  useEffect(() => {
    if (initialFit === "bike" || initialFit === "all") setFitMode(initialFit);
  }, [initialFit]);
  useEffect(() => {
    setBikeId(initialBikeId && initialBikeId.length > 0 ? initialBikeId : "all");
  }, [initialBikeId]);
  const garage = useMemo(() => softFitInputsFromBikes(bikes), [bikes]);
  const hydrated = useMemo(() => products.map(hydrate), [products]);
  const ranked = useMemo(
    () =>
      filterAndRankParts(hydrated, {
        slot,
        bikes: garage,
        selectedBikeId: bikeId,
        fit: fitMode === "bike" && garage.length > 0 ? "bike" : "all",
      }),
    [hydrated, slot, garage, bikeId, fitMode]
  );
  const visible = ranked.filter((row) => {
    const needle = q.trim().toLowerCase();
    if (!needle) return true;
    const p = row.product;
    return (
      p.name.toLowerCase().includes(needle) ||
      p.manufacturer.toLowerCase().includes(needle) ||
      p.slotKey.toLowerCase().includes(needle)
    );
  });
  const chips = PARTS_BROWSE_SLOTS.filter(
    (c) =>
      c.slot === "all" ||
      c.slot === slot ||
      hydrated.some(
        (p) => p.slotKey === c.slot || p.tags.includes(`slot:${c.slot}`)
      )
  );
  const selectedBike = bikes.find((b) => b.id === bikeId);
  const showFit = bikes.length > 0;

  if (loading) {
    return (
      <div className="space-y-3">
        <h2 className="text-base font-extrabold">{HOF_COPY.shopFeatured}</h2>
        <PartsSkeleton count={4} />
      </div>
    );
  }

  if (products.length === 0) {
    return (
      <p
        data-testid="shop-catalog-empty"
        className="text-sm text-text-secondary"
      >
        {HOF_COPY.shopCatalogEmpty}
      </p>
    );
  }

  return (
    <section className="space-y-3">
      <label className="relative block">
        <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-text-secondary" />
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder={HOF_COPY.shopSearchHint}
          className="w-full rounded-xl border border-border bg-surface py-2.5 pl-10 pr-3 text-sm outline-none placeholder:text-text-secondary focus:border-accent"
        />
      </label>
      {chips.length > 1 ? (
        <div className="flex gap-2 overflow-x-auto pb-1">
          {chips.map((c) => {
            const selected = slot === c.slot;
            return (
              <button
                key={c.slot}
                type="button"
                onClick={() => setSlot(c.slot)}
                className={
                  selected
                    ? "shrink-0 rounded-full bg-sage/30 px-3 py-1.5 text-xs font-bold text-sage"
                    : "shrink-0 rounded-full border border-border bg-surface px-3 py-1.5 text-xs font-bold text-text-secondary"
                }
              >
                {c.slot === "all" ? HOF_COPY.shopAllParts : c.label}
              </button>
            );
          })}
        </div>
      ) : null}
      {bikes.length > 1 ? (
        <div className="flex gap-2 overflow-x-auto pb-1">
          <button
            type="button"
            data-testid="shop-bike-all"
            onClick={() => setBikeId("all")}
            className={
              bikeId === "all"
                ? "shrink-0 rounded-full bg-sage/30 px-3 py-1.5 text-xs font-bold text-sage"
                : "shrink-0 rounded-full border border-border bg-surface px-3 py-1.5 text-xs font-bold text-text-secondary"
            }
          >
            {HOF_COPY.shopFitAllBikes}
          </button>
          {bikes.map((b) => {
            const selected = bikeId === b.id;
            return (
              <button
                key={b.id}
                type="button"
                data-testid={`shop-bike-${b.id}`}
                onClick={() => setBikeId(b.id)}
                className={
                  selected
                    ? "shrink-0 rounded-full bg-sage/30 px-3 py-1.5 text-xs font-bold text-sage"
                    : "shrink-0 rounded-full border border-border bg-surface px-3 py-1.5 text-xs font-bold text-text-secondary"
                }
              >
                {b.name}
              </button>
            );
          })}
        </div>
      ) : null}
      {showFit ? (
        <div className="flex flex-wrap items-center gap-2">
          <p className="rounded-xl bg-sage/20 px-3 py-2 text-xs font-bold text-sage">
            {selectedBike
              ? HOF_COPY.shopFitBanner(selectedBike.name)
              : HOF_COPY.shopFitBannerAll}
          </p>
          <button
            type="button"
            data-testid="shop-fit-only"
            onClick={() => setFitMode((m) => (m === "bike" ? "all" : "bike"))}
            className={
              fitMode === "bike"
                ? "rounded-full bg-sage/30 px-3 py-1.5 text-xs font-bold text-sage"
                : "rounded-full border border-border bg-surface px-3 py-1.5 text-xs font-bold text-text-secondary"
            }
          >
            {HOF_COPY.shopFitOnly}
          </button>
        </div>
      ) : null}
      <div className="flex items-baseline justify-between">
        <h2 className="text-base font-extrabold">{HOF_COPY.shopFeatured}</h2>
        <p className="text-xs text-text-secondary">{visible.length}</p>
      </div>
      {visible.length === 0 ? (
        <p className="text-sm text-text-secondary">{HOF_COPY.shopShelfEmpty}</p>
      ) : (
        <ul className="space-y-3">
          {visible.slice(0, 24).map((row) => {
            const p = row.product;
            return (
              <li key={p.id}>
                <Link
                  href={inAppProductHref(p.handle)}
                  className="flex gap-3 rounded-2xl border border-border bg-surface p-3 hover:border-accent/40"
                >
                  <div className="h-[88px] w-[88px] shrink-0 overflow-hidden rounded-xl bg-surface-elevated">
                    {p.imageUrl ? (
                      // eslint-disable-next-line @next/next/no-img-element -- Shopify CDN
                      <img
                        src={p.imageUrl}
                        alt={p.imageAlt || p.name}
                        className="h-full w-full object-cover"
                      />
                    ) : (
                      <div className="flex h-[88px] w-[88px] items-center justify-center text-[11px] text-text-secondary">
                        Kein Bild
                      </div>
                    )}
                  </div>
                  <div className="min-w-0 flex-1">
                    {p.manufacturer ? (
                      <p className="text-[10px] font-bold uppercase tracking-wide text-text-secondary">
                        {p.manufacturer}
                      </p>
                    ) : null}
                    <h3 className="font-extrabold leading-snug">{p.name}</h3>
                    {row.fitLabel ? (
                      <p className="mt-1 inline-block rounded-full bg-sage/20 px-2 py-0.5 text-[11px] font-bold text-sage">
                        {row.fitLabel}
                      </p>
                    ) : null}
                    <p className="mt-1 text-base font-extrabold tabular-nums text-accent">
                      {formatPrice(p.priceEur, p.currencyCode)}
                    </p>
                    <p className="mt-1 text-xs font-extrabold text-accent">
                      {HOF_COPY.shopOpenProduct}
                    </p>
                  </div>
                </Link>
              </li>
            );
          })}
        </ul>
      )}
    </section>
  );
}
