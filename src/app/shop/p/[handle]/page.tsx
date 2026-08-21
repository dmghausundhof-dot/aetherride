"use client";

import { Suspense, useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { ArrowLeft } from "lucide-react";
import { ShopifyOutboundButton } from "@/components/shop/ShopifyOutboundButton";
import { ShopImageFallback } from "@/components/shop/ShopImageFallback";
import { StoreLockedBanner } from "@/components/shop/StoreLockedBanner";
import { PartsSkeleton } from "@/components/shop/PartsSkeleton";
import type { PartsProduct } from "@/lib/shop/partsCatalog";
import { FEATURED_PARTS_IN_APP_HREF } from "@/lib/shop/catalog";
import { useHofCopy } from "@/hooks/useHofCopy";
import { useChromeLang } from "@/hooks/useChromeLang";
import { FlowLineWordmark } from "@/components/brand/FlowLineWordmark";
import { useAppStore } from "@/store/useAppStore";
import {
  evaluatePartAgainstGarage,
  isRideableGarageBike,
  softFitInputsFromBikes,
} from "@/lib/shop/garageFit";
import { isPartsProduct } from "@/lib/shop/shopShelf";
import { isShopifyOnlineStoreUrl } from "@/lib/shop/storeStatus";
import { formatShopPrice } from "@/lib/shop/shopifyLocale";

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
  | { status: "error"; kind: "missing" | "network"; redirectTo?: string };

function ProductPageInner() {
  const copy = useHofCopy();
  const lang = useChromeLang();

  const router = useRouter();
  const params = useParams<{ handle: string }>();
  const handle = decodeURIComponent(params.handle || "");
  const [load, setLoad] = useState<LoadState>({ status: "loading" });

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const res = await fetch(
          `/api/shop/products/${encodeURIComponent(handle)}?lang=${lang}`,
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
            kind: "missing",
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
            kind: "network",
            redirectTo: FEATURED_PARTS_IN_APP_HREF,
          });
        }
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [handle, router, lang]);

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
          <ArrowLeft className="h-3.5 w-3.5" /> {copy.shopBack}
        </Link>
        <section className="rounded-2xl border border-dashed border-border bg-surface p-8 text-center">
          <h1 className="text-lg font-semibold">{copy.shopProductUnavailable}</h1>
          <p className="mt-2 text-sm text-text-secondary">
            {load.kind === "network"
              ? copy.shopNetworkError
              : copy.shopProductMissing}
          </p>
          <Link
            href={load.redirectTo || FEATURED_PARTS_IN_APP_HREF}
            className="mt-4 inline-flex rounded-xl bg-chrome px-4 py-2 text-sm font-semibold text-on-accent"
          >
            {copy.shopTitle}
          </Link>
        </section>
      </div>
    );
  }

  const p = load.product;
  const shopifyCta = Boolean(
    load.externalUrl && isShopifyOnlineStoreUrl(load.externalUrl)
  );

  return (
    <div className="mx-auto flex w-full max-w-3xl flex-col gap-5 p-4 pt-6">
      <FlowLineWordmark
        className="text-base font-bold tracking-tight text-foreground"
        markClassName="h-5 w-auto"
      />
      <Link
        href="/shop"
        className="inline-flex items-center gap-1 text-xs font-medium text-text-secondary hover:text-chrome"
      >
        <ArrowLeft className="h-3.5 w-3.5" /> {copy.shopBack}
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
            <ShopImageFallback label={copy.shopNoImage} />
          )}
        </div>
        <div className="space-y-3 p-5">
      <p className="text-[11px] font-bold tracking-wide text-text-secondary">
        {copy.shopCyclingParts}
      </p>
      <h1 className="mt-1 text-2xl font-extrabold tracking-tight">{p.name}</h1>
      {p.manufacturer ? (
        <p className="mt-1 text-sm text-text-secondary">{p.manufacturer}</p>
      ) : null}
      <ProductGarageFit product={p} />
      <p className="text-lg font-extrabold tabular-nums text-accent">
        {formatShopPrice(p.priceEur, p.currencyCode || "EUR", lang)}
      </p>
      {p.description ? (
        <p className="text-sm leading-relaxed text-text-secondary">
          {p.description}
        </p>
      ) : null}
      <p className="text-sm leading-relaxed text-text-secondary">
        {copy.shopCheckoutElsewhere}
      </p>
      {load.warning ? (
        <p className="text-xs text-warning">{load.warning}</p>
      ) : null}
      <div className="pt-2">
        {load.externalUrl ? (
          <>
            <ShopifyOutboundButton
              href={load.externalUrl}
              label={
                shopifyCta ? copy.shopOpenProduct : copy.shopZumHaendler
              }
              variant="primary"
            />
            <p className="mt-2 text-center text-[11px] text-text-secondary">
              {load.onlineStoreLocked && shopifyCta
                ? copy.shopLockedTitle
                : shopifyCta
                  ? copy.shopCheckoutElsewhere
                  : copy.shopMerchantDisclosure}
            </p>
          </>
        ) : (
          <Link
            href="/shop"
            className="inline-flex w-full items-center justify-center rounded-xl bg-chrome py-2.5 text-sm font-semibold text-on-accent"
          >
            {copy.shopBack}
          </Link>
        )}
      </div>
        </div>
      </article>
    </div>
  );
}

function ProductGarageFit({ product }: { product: PartsProduct }) {
  const bikes = useAppStore((s) => s.bikes);
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const label = useMemo(() => {
    if (!isPartsProduct({ ...product, title: product.name })) return null;
    const rideable = bikes.filter((b) => isRideableGarageBike(b.category));
    const garage = softFitInputsFromBikes(rideable);
    if (garage.length === 0) return null;
    const ev = evaluatePartAgainstGarage({
      tags: product.tags ?? [],
      title: product.name,
      productType: product.productType ?? "",
      slotKey: product.slotKey,
      description: product.description,
      bikes: garage,
      selectedBikeId: activeBikeId,
      fitMode: "all",
    });
    if (ev.garage.kind !== "match" || !ev.garage.label) return null;
    return ev.garage.label;
  }, [product, bikes, activeBikeId]);
  if (!label) return null;
  return (
    <p className="inline-block rounded-full bg-sage/20 px-2 py-0.5 text-[11px] font-bold text-sage">
      {label}
    </p>
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
