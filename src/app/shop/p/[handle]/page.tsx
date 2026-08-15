"use client";

import { Suspense, useEffect, useState } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { ArrowLeft } from "lucide-react";
import { ShopifyOutboundButton } from "@/components/shop/ShopifyOutboundButton";
import { StoreLockedBanner } from "@/components/shop/StoreLockedBanner";
import { PartsSkeleton } from "@/components/shop/PartsSkeleton";
import type { PartsProduct } from "@/lib/shop/partsCatalog";
import { FEATURED_PARTS_IN_APP_HREF } from "@/lib/shop/catalog";
import { HOF_COPY } from "@/lib/home/hofCopy";

type LoadState =
  | { status: "loading" }
  | {
      status: "ready";
      product: PartsProduct;
      onlineStoreLocked: boolean;
      externalUrl?: string;
      source: string;
      warning?: string;
    }
  | { status: "error"; error: string; redirectTo?: string };

function ProductPageInner() {
  const router = useRouter();
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
          redirectTo?: string;
          code?: string;
        };
        if (cancelled) return;
        if (!json.ok || !json.product) {
          // Unpublished / missing → collection (never leave user on blank 404)
          if (json.redirectTo || json.code === "unpublished_handle") {
            router.replace(json.redirectTo || FEATURED_PARTS_IN_APP_HREF);
            return;
          }
          setLoad({
            status: "error",
            error: json.error || "Produkt nicht gefunden.",
            redirectTo: json.redirectTo || FEATURED_PARTS_IN_APP_HREF,
          });
          return;
        }
        setLoad({
          status: "ready",
          product: json.product,
          onlineStoreLocked: Boolean(json.onlineStoreLocked),
          externalUrl: json.externalUrl || undefined,
          source: json.source || "storefront",
          warning: json.warning,
        });
      } catch {
        if (!cancelled) {
          setLoad({
            status: "error",
            error: "Netzwerkfehler.",
            redirectTo: FEATURED_PARTS_IN_APP_HREF,
          });
        }
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [handle, router]);

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
          href="/shop"
          className="inline-flex items-center gap-1 text-xs text-text-secondary hover:text-chrome"
        >
          <ArrowLeft className="h-3.5 w-3.5" /> {HOF_COPY.shopBack}
        </Link>
        <section className="rounded-2xl border border-dashed border-border bg-surface p-8 text-center">
          <h1 className="text-lg font-semibold">Produkt nicht verfügbar</h1>
          <p className="mt-2 text-sm text-text-secondary">{load.error}</p>
          <Link
            href={load.redirectTo || FEATURED_PARTS_IN_APP_HREF}
            className="mt-4 inline-flex rounded-xl bg-chrome px-4 py-2 text-sm font-semibold text-background"
          >
            {HOF_COPY.shopTitle}
          </Link>
        </section>
      </div>
    );
  }

  const p = load.product;

  return (
    <div className="mx-auto flex w-full max-w-3xl flex-col gap-5 p-4 pt-6">
      <Link
        href="/shop"
        className="inline-flex items-center gap-1 text-xs font-medium text-text-secondary hover:text-chrome"
      >
        <ArrowLeft className="h-3.5 w-3.5" /> {HOF_COPY.shopBack}
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
      <p className="text-[11px] font-bold tracking-wide text-chrome">
        {HOF_COPY.shopKicker}
      </p>
      <h1 className="mt-1 text-2xl font-extrabold tracking-tight">{p.name}</h1>
      {p.manufacturer ? (
        <p className="mt-1 text-sm text-text-secondary">{p.manufacturer}</p>
      ) : null}
      <p className="mt-3 text-sm leading-relaxed text-text-secondary">
        {HOF_COPY.shopCheckoutElsewhere}
      </p>
      {load.warning ? (
        <p className="text-xs text-warning">{load.warning}</p>
      ) : null}
      <div className="pt-2">
        {load.externalUrl ? (
          <ShopifyOutboundButton
            href={load.externalUrl}
            label={HOF_COPY.shopGo}
            variant="primary"
          />
        ) : (
          <Link
            href="/shop"
            className="inline-flex w-full items-center justify-center rounded-xl bg-chrome py-2.5 text-sm font-semibold text-background"
          >
            {HOF_COPY.shopBack}
          </Link>
        )}
        <p className="mt-2 text-center text-[11px] text-text-secondary">
          {load.onlineStoreLocked
            ? HOF_COPY.shopLockedTitle
            : HOF_COPY.shopCheckoutElsewhere}
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
