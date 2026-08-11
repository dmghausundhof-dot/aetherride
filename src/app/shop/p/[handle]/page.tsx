"use client";

import { Suspense, useEffect, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { ArrowLeft } from "lucide-react";
import { ShopifyOutboundButton } from "@/components/shop/ShopifyOutboundButton";
import { StoreLockedBanner } from "@/components/shop/StoreLockedBanner";
import { PartsSkeleton } from "@/components/shop/PartsSkeleton";
import type { PartsProduct } from "@/lib/shop/partsCatalog";

type LoadState =
  | { status: "loading" }
  | {
      status: "ready";
      product: PartsProduct;
      onlineStoreLocked: boolean;
      externalUrl: string;
      source: string;
      warning?: string;
    }
  | { status: "error"; error: string };

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

function ProductPageInner() {
  const params = useParams<{ handle: string }>();
  const handle = decodeURIComponent(params.handle || "");
  const [load, setLoad] = useState<LoadState>({ status: "loading" });

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const res = await fetch(
          `/api/shop/products/${encodeURIComponent(handle)}`,
          { cache: "no-store" }
        );
        const json = (await res.json()) as {
          ok?: boolean;
          product?: PartsProduct;
          onlineStoreLocked?: boolean;
          externalUrl?: string;
          source?: string;
          warning?: string;
          error?: string;
        };
        if (cancelled) return;
        if (!json.ok || !json.product) {
          setLoad({
            status: "error",
            error: json.error || "Produkt nicht gefunden.",
          });
          return;
        }
        setLoad({
          status: "ready",
          product: json.product,
          onlineStoreLocked: Boolean(json.onlineStoreLocked),
          externalUrl: json.externalUrl || json.product.affiliateUrl,
          source: json.source || "storefront",
          warning: json.warning,
        });
      } catch {
        if (!cancelled) {
          setLoad({ status: "error", error: "Netzwerkfehler." });
        }
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [handle]);

  if (load.status === "loading") {
    return (
      <div className="mx-auto max-w-3xl p-4 pt-6">
        <PartsSkeleton count={1} />
      </div>
    );
  }

  if (load.status === "error") {
    return (
      <div className="mx-auto max-w-3xl space-y-4 p-4 pt-6">
        <Link
          href="/shop/parts"
          className="inline-flex items-center gap-1 text-xs text-text-secondary hover:text-accent"
        >
          <ArrowLeft className="h-3.5 w-3.5" /> Ersatzteile
        </Link>
        <section className="rounded-2xl border border-dashed border-border bg-surface p-8 text-center">
          <h1 className="text-lg font-semibold">Produkt nicht verfügbar</h1>
          <p className="mt-2 text-sm text-text-secondary">{load.error}</p>
          <Link
            href="/shop/parts"
            className="mt-4 inline-flex rounded-xl bg-accent px-4 py-2 text-sm font-semibold text-white"
          >
            Zurück zur Collection
          </Link>
        </section>
      </div>
    );
  }

  const p = load.product;

  return (
    <div className="mx-auto flex w-full max-w-3xl flex-col gap-5 p-4 pt-6">
      <Link
        href="/shop/parts"
        className="inline-flex items-center gap-1 text-xs font-medium text-text-secondary hover:text-accent"
      >
        <ArrowLeft className="h-3.5 w-3.5" /> Ersatzteile
      </Link>

      <StoreLockedBanner />

      <article className="overflow-hidden rounded-2xl border border-border bg-surface">
        <div className="aspect-[16/10] bg-surface-elevated">
          {p.imageUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={p.imageUrl}
              alt={p.imageAlt || p.name}
              className="h-full w-full object-cover"
            />
          ) : (
            <div className="flex h-full items-center justify-center text-text-secondary">
              Kein Bild
            </div>
          )}
        </div>
        <div className="space-y-3 p-5">
          <div className="text-xs font-medium uppercase tracking-wide text-text-secondary">
            {p.manufacturer}
            {p.productType ? ` · ${p.productType}` : ""}
          </div>
          <h1 className="text-2xl font-bold tracking-tight">{p.name}</h1>
          <div className="text-2xl font-bold tabular-nums text-accent">
            {formatPrice(p.priceEur, p.currencyCode)}
          </div>
          {p.description ? (
            <p className="text-sm leading-relaxed text-text-secondary">
              {p.description}
            </p>
          ) : null}
          {p.softFit?.slots?.length || p.tags?.length ? (
            <div className="flex flex-wrap gap-1.5">
              {(p.softFit?.slots?.length
                ? p.softFit.slots.map((s) => `slot:${s}`)
                : p.tags.slice(0, 8)
              ).map((t) => (
                <span
                  key={t}
                  className="rounded-full border border-border bg-surface-elevated px-2 py-0.5 text-[11px] text-text-secondary"
                >
                  {t}
                </span>
              ))}
            </div>
          ) : null}
          {load.warning ? (
            <p className="text-xs text-warning">{load.warning}</p>
          ) : null}
          <div className="pt-2">
            <ShopifyOutboundButton
              href={load.externalUrl}
              label={
                load.onlineStoreLocked
                  ? "Shopify Checkout (gesperrt)"
                  : "Zum Shopify-Checkout"
              }
              variant="primary"
            />
            <p className="mt-2 text-center text-[11px] text-text-secondary">
              Quelle: {load.source === "storefront" ? "Storefront API" : "Featured Snapshot"} ·
              In-App-Katalog ohne Passwort-Wall
            </p>
          </div>
        </div>
      </article>
    </div>
  );
}

export default function ShopProductPage() {
  return (
    <Suspense
      fallback={
        <div className="p-6">
          <PartsSkeleton count={1} />
        </div>
      }
    >
      <ProductPageInner />
    </Suspense>
  );
}
