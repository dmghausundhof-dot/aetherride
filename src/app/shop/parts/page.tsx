"use client";

import { Suspense, useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { ArrowLeft, RefreshCw } from "lucide-react";
import { useAppStore } from "@/store/useAppStore";
import { getComponentModel } from "@/lib/catalog/components";
import {
  filterAndRankParts,
  shopPartsHref,
  type PartsProduct,
  type RankedPartsProduct,
} from "@/lib/shop/partsCatalog";
import {
  PARTS_BROWSE_SLOTS,
  normalizePartsSlot,
  softFitContextFromBike,
  type SoftFitContext,
} from "@/lib/shop/softFit";
import { PartsProductCard } from "@/components/shop/PartsProductCard";
import { PartsSkeleton } from "@/components/shop/PartsSkeleton";
import { cn } from "@/lib/utils";

type LoadState =
  | { status: "loading" }
  | {
      status: "ready";
      products: PartsProduct[];
      collectionTitle: string;
      count: number;
    }
  | {
      status: "error";
      configured: boolean;
      error: string;
      code?: string;
    };

function PartsPageInner() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const bikes = useAppStore((s) => s.bikes);
  const activeBikeId = useAppStore((s) => s.activeBikeId);

  const slotParam = searchParams.get("slot");
  const bikeParam = searchParams.get("bike");
  const fitParam = searchParams.get("fit");
  const focusParam = searchParams.get("focus");

  const [slotFilter, setSlotFilter] = useState(() =>
    normalizePartsSlot(slotParam)
  );
  const [fitBike, setFitBike] = useState(
    () => fitParam === "bike" || Boolean(bikeParam)
  );
  const [load, setLoad] = useState<LoadState>({ status: "loading" });
  const [reloadKey, setReloadKey] = useState(0);

  // URL → local filter sync (same pattern as Garage deep-links)
  const paramKey = `${slotParam}|${fitParam}|${bikeParam}`;
  const [trackedParams, setTrackedParams] = useState(paramKey);
  if (paramKey !== trackedParams) {
    setTrackedParams(paramKey);
    setSlotFilter(normalizePartsSlot(slotParam));
    if (fitParam === "all") setFitBike(false);
    else if (fitParam === "bike" || bikeParam) setFitBike(true);
  }

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const res = await fetch("/api/shop/parts", { cache: "no-store" });
        const json = (await res.json()) as {
          ok?: boolean;
          configured?: boolean;
          products?: PartsProduct[];
          collectionTitle?: string;
          count?: number;
          error?: string;
          code?: string;
        };
        if (cancelled) return;
        if (!json.ok || !Array.isArray(json.products)) {
          setLoad({
            status: "error",
            configured: Boolean(json.configured),
            error: json.error || "Ersatzteile konnten nicht geladen werden.",
            code: json.code,
          });
          return;
        }
        setLoad({
          status: "ready",
          products: json.products,
          collectionTitle: json.collectionTitle || "Ersatzteile",
          count: json.count ?? json.products.length,
        });
      } catch {
        if (!cancelled) {
          setLoad({
            status: "error",
            configured: true,
            error: "Netzwerkfehler beim Laden der Collection.",
            code: "network",
          });
        }
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [reloadKey]);

  const contextBike = useMemo(() => {
    const id = bikeParam || activeBikeId;
    return bikes.find((b) => b.id === id) || bikes[0] || null;
  }, [bikeParam, activeBikeId, bikes]);

  const softCtx: SoftFitContext | null = useMemo(() => {
    if (!contextBike) return null;
    return softFitContextFromBike(contextBike, getComponentModel);
  }, [contextBike]);

  const ranked: RankedPartsProduct[] = useMemo(() => {
    if (load.status !== "ready") return [];
    return filterAndRankParts(load.products, {
      slot: slotFilter,
      fit: fitBike && softCtx ? "bike" : "all",
      ctx: softCtx,
      availableOnly: true,
    });
  }, [load, slotFilter, fitBike, softCtx]);

  useEffect(() => {
    if (!focusParam || load.status !== "ready") return;
    const el = document.getElementById(`part-${focusParam}`);
    el?.scrollIntoView({ behavior: "smooth", block: "center" });
  }, [focusParam, load.status, ranked.length]);

  const updateSlot = (slot: string) => {
    setSlotFilter(slot);
    router.replace(
      shopPartsHref({
        slot: slot === "all" ? undefined : slot,
        bike: contextBike?.id,
        fit: fitBike && contextBike ? "bike" : undefined,
      }),
      { scroll: false }
    );
  };

  const reload = () => {
    setLoad({ status: "loading" });
    setReloadKey((k) => k + 1);
  };

  return (
    <div className="mx-auto flex w-full max-w-6xl flex-col gap-5 p-4 pt-6">
      <header className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <Link
            href="/shop"
            className="mb-2 inline-flex items-center gap-1 text-xs font-medium text-text-secondary hover:text-accent"
          >
            <ArrowLeft className="h-3.5 w-3.5" /> Shop
          </Link>
          <h1 className="text-2xl font-bold tracking-tight">Ersatzteile</h1>
          <p className="mt-1 text-sm text-text-secondary">
            Collection{" "}
            <span className="font-medium text-foreground">featured-parts</span>
            {load.status === "ready"
              ? ` · ${load.count} Produkte live aus Shopify`
              : " · live aus dem AetherRide Shop"}
          </p>
        </div>
        <button
          type="button"
          onClick={reload}
          className="inline-flex items-center gap-1.5 rounded-xl border border-border px-3 py-2 text-xs font-medium text-text-secondary hover:border-accent/40 hover:text-accent"
          aria-label="Collection neu laden"
        >
          <RefreshCw className="h-3.5 w-3.5" /> Aktualisieren
        </button>
      </header>

      {contextBike ? (
        <div className="flex flex-wrap items-center justify-between gap-2 rounded-xl border border-accent/30 bg-accent/10 px-3 py-2.5 text-sm">
          <div>
            <span className="font-medium text-accent">Für dein Bike: </span>
            {contextBike.name}
            {softCtx?.maguraShape ? (
              <span className="ml-2 text-xs text-text-secondary">
                Magura-Form {softCtx.maguraShape}.P
              </span>
            ) : null}
          </div>
          <label className="flex items-center gap-2 text-xs text-text-secondary">
            <input
              type="checkbox"
              checked={fitBike}
              onChange={(e) => setFitBike(e.target.checked)}
            />
            Nur was passt (Soft-Fit)
          </label>
        </div>
      ) : (
        <div className="rounded-2xl border border-border bg-surface p-4 text-center">
          <p className="text-sm font-medium">Noch kein Bike — trotzdem stöbern</p>
          <p className="mt-1 text-xs text-text-secondary">
            Mit Bike in der Garage filtern wir Beläge, Griffe und Schaltung soft
            nach deinem Setup.
          </p>
          <Link
            href="/garage?wizard=catalog"
            className="mt-3 inline-flex rounded-xl bg-accent px-4 py-2 text-sm font-semibold text-white"
          >
            Bike anlegen
          </Link>
        </div>
      )}

      <div>
        <p className="mb-1.5 text-[10px] font-semibold uppercase tracking-wide text-text-secondary">
          Kategorie
        </p>
        <div className="flex gap-2 overflow-x-auto pb-1">
          {PARTS_BROWSE_SLOTS.map((s) => (
            <button
              key={s.slot}
              type="button"
              onClick={() => updateSlot(s.slot)}
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

      {load.status === "loading" ? <PartsSkeleton /> : null}

      {load.status === "error" ? (
        <section className="rounded-2xl border border-dashed border-border bg-surface p-8 text-center">
          <h2 className="text-lg font-semibold">
            {load.configured
              ? "Collection gerade nicht erreichbar"
              : "Shopify Storefront noch nicht verbunden"}
          </h2>
          <p className="mx-auto mt-2 max-w-md text-sm text-text-secondary">
            {load.configured
              ? load.error
              : "Sobald SHOPIFY_STOREFRONT_ACCESS_TOKEN gesetzt ist, erscheinen die ~43–48 ACTIVE Produkte aus featured-parts hier — kein Snapshot."}
          </p>
          <div className="mt-4 flex flex-wrap items-center justify-center gap-2">
            <button
              type="button"
              onClick={reload}
              className="rounded-xl bg-accent px-4 py-2 text-sm font-semibold text-white"
            >
              Erneut versuchen
            </button>
            <Link
              href="/shop"
              className="rounded-xl border border-border px-4 py-2 text-sm font-medium"
            >
              Zurück zum Shop
            </Link>
          </div>
        </section>
      ) : null}

      {load.status === "ready" && ranked.length === 0 ? (
        <section className="rounded-2xl border border-dashed border-border bg-surface p-8 text-center">
          <h2 className="text-lg font-semibold">Keine Treffer in diesem Filter</h2>
          <p className="mx-auto mt-2 max-w-md text-sm text-text-secondary">
            {load.count === 0
              ? "Die Collection featured-parts ist leer oder noch nicht befüllt."
              : fitBike
                ? "Soft-Fit hat alles ausgeblendet — Filter lockern oder „Nur was passt“ aus."
                : "Anderen Slot wählen oder Filter zurücksetzen."}
          </p>
          <button
            type="button"
            onClick={() => {
              setFitBike(false);
              updateSlot("all");
            }}
            className="mt-4 rounded-xl bg-accent px-4 py-2 text-sm font-semibold text-white"
          >
            Alle Teile zeigen
          </button>
        </section>
      ) : null}

      {load.status === "ready" && ranked.length > 0 ? (
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {ranked.map((row) => (
            <PartsProductCard
              key={row.product.id}
              row={row}
              focused={focusParam === row.product.handle}
            />
          ))}
        </div>
      ) : null}

      <p className="text-center text-xs text-text-secondary">
        Preise & Verfügbarkeit live aus Shopify · Checkout im AetherRide Shop
      </p>
    </div>
  );
}

export default function ShopPartsPage() {
  return (
    <Suspense fallback={<div className="p-6"><PartsSkeleton /></div>}>
      <PartsPageInner />
    </Suspense>
  );
}
