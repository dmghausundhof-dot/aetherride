"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { ChevronRight, ShoppingBag } from "lucide-react";
import {
  filterAndRankParts,
  shopPartsHref,
  type PartsProduct,
} from "@/lib/shop/partsCatalog";
import { PartsProductCard } from "@/components/shop/PartsProductCard";
import { PartsSkeleton } from "@/components/shop/PartsSkeleton";

type LoadState =
  | { status: "loading" }
  | { status: "ready"; products: PartsProduct[]; count: number }
  | { status: "error"; configured: boolean; error: string };

/** Hub preview — Collection-driven featured-parts (never dead bike handles). */
export function FeaturedPartsPreview({
  bikeId,
}: {
  bikeId?: string;
}) {
  const [load, setLoad] = useState<LoadState>({ status: "loading" });

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const res = await fetch("/api/shop/parts", { cache: "no-store" });
        const json = (await res.json()) as {
          ok?: boolean;
          configured?: boolean;
          products?: PartsProduct[];
          count?: number;
          error?: string;
        };
        if (cancelled) return;
        if (!json.ok || !Array.isArray(json.products)) {
          setLoad({
            status: "error",
            configured: Boolean(json.configured),
            error: json.error || "Collection konnte nicht geladen werden.",
          });
          return;
        }
        setLoad({
          status: "ready",
          products: json.products,
          count: json.count ?? json.products.length,
        });
      } catch {
        if (!cancelled) {
          setLoad({
            status: "error",
            configured: true,
            error: "Netzwerkfehler beim Laden von featured-parts.",
          });
        }
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const partsHref = shopPartsHref({
    bike: bikeId,
    fit: bikeId ? "bike" : undefined,
  });

  if (load.status === "loading") {
    return (
      <section className="space-y-3">
        <Header count={null} href={partsHref} />
        <PartsSkeleton count={3} />
      </section>
    );
  }

  if (load.status === "error") {
    return (
      <section className="space-y-3">
        <Header count={null} href={partsHref} />
        <div className="rounded-2xl border border-dashed border-border bg-surface p-8 text-center">
          <ShoppingBag className="mx-auto h-8 w-8 text-text-secondary" />
          <h3 className="mt-3 text-base font-semibold">
            {load.configured
              ? "featured-parts gerade nicht erreichbar"
              : "Storefront API noch nicht verbunden"}
          </h3>
          <p className="mx-auto mt-2 max-w-md text-sm text-text-secondary">
            {load.configured
              ? load.error
              : "Mit SHOPIFY_STOREFRONT_ACCESS_TOKEN erscheinen ~43–48 ACTIVE Produkte aus der Collection — kein Snapshot, keine 404-Handles."}
          </p>
          <Link
            href={partsHref}
            className="mt-4 inline-flex rounded-xl bg-accent px-4 py-2 text-sm font-semibold text-white"
          >
            Zur Ersatzteile-Seite
          </Link>
        </div>
      </section>
    );
  }

  const preview = filterAndRankParts(load.products, {
    slot: "all",
    fit: "all",
    availableOnly: true,
  }).slice(0, 6);

  if (preview.length === 0) {
    return (
      <section className="space-y-3">
        <Header count={load.count} href={partsHref} />
        <div className="rounded-2xl border border-dashed border-border bg-surface p-8 text-center">
          <h3 className="text-base font-semibold">Collection noch leer</h3>
          <p className="mt-2 text-sm text-text-secondary">
            featured-parts hat derzeit keine verfügbaren Produkte. Keine toten
            Bike-Handles als Ersatz.
          </p>
          <Link
            href={partsHref}
            className="mt-4 inline-flex rounded-xl border border-border px-4 py-2 text-sm font-medium"
          >
            Collection öffnen
          </Link>
        </div>
      </section>
    );
  }

  return (
    <section className="space-y-3">
      <Header count={load.count} href={partsHref} />
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {preview.map((row) => (
          <PartsProductCard key={row.product.id} row={row} />
        ))}
      </div>
      <Link
        href={partsHref}
        className="inline-flex w-full items-center justify-center gap-2 rounded-xl border border-accent/40 bg-accent/10 py-3 text-sm font-semibold text-accent"
      >
        Alle Ersatzteile anzeigen <ChevronRight className="h-4 w-4" />
      </Link>
    </section>
  );
}

function Header({
  count,
  href,
}: {
  count: number | null;
  href: string;
}) {
  return (
    <div className="flex items-start justify-between gap-3 px-0.5">
      <div className="flex items-start gap-3">
        <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-accent/20 text-accent">
          <ShoppingBag className="h-5 w-5" />
        </div>
        <div>
          <h2 className="text-lg font-bold">Featured · Ersatzteile</h2>
          <p className="mt-0.5 text-xs text-text-secondary">
            Collection{" "}
            <span className="font-medium text-foreground">featured-parts</span>
            {count != null ? ` · ${count} live` : " · Storefront API"}
          </p>
        </div>
      </div>
      <Link
        href={href}
        className="shrink-0 text-xs font-medium text-accent hover:underline"
      >
        Alle
      </Link>
    </div>
  );
}
