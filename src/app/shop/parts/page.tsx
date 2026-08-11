"use client";

import Link from "next/link";
import { ArrowLeft, ExternalLink, Package, Store } from "lucide-react";
import {
  getFeaturedPartsProducts,
  isProductAffiliateUrl,
  shopifyCollectionUrl,
  type ShopProduct,
} from "@/lib/shop/catalog";
import { ProductVisual } from "@/components/shop/ProductVisual";
import { slotLabel } from "@/lib/catalog/slots";

const FEATURED_PARTS_COLLECTION = shopifyCollectionUrl("featured-parts");

function PartsCard({ product }: { product: ShopProduct }) {
  const productUrl = isProductAffiliateUrl(product.affiliateUrl)
    ? product.affiliateUrl
    : null;

  return (
    <article className="rounded-2xl border border-border bg-surface p-4">
      <div className="flex gap-3">
        <ProductVisual product={product} />
        <div className="min-w-0 flex-1">
          <div className="mb-1 flex items-start justify-between gap-2">
            <span className="text-xs uppercase tracking-wide text-text-secondary">
              {product.manufacturer}
            </span>
            <span className="text-xs text-text-secondary">
              {slotLabel(product.slot)}
            </span>
          </div>
          <h2 className="font-semibold leading-snug">{product.name}</h2>
          <div className="mt-1 text-lg font-bold tabular-nums text-accent">
            {product.priceEur.toLocaleString("de-DE")} €
          </div>
        </div>
      </div>
      <p className="mt-3 text-xs text-text-secondary">{product.description}</p>
      {productUrl ? (
        <a
          href={productUrl}
          target="_blank"
          rel="noopener noreferrer"
          className="mt-3 inline-flex w-full items-center justify-center gap-2 rounded-xl bg-accent py-2.5 text-sm font-semibold text-white"
        >
          Zum Produkt <ExternalLink className="h-4 w-4" />
        </a>
      ) : (
        <p className="mt-3 rounded-xl border border-dashed border-border px-3 py-2 text-center text-xs text-text-secondary">
          Produkt-URL folgt, sobald der Store gekoppelt ist
        </p>
      )}
    </article>
  );
}

export default function ShopPartsPage() {
  const parts = getFeaturedPartsProducts();
  const hasLiveProductUrls = parts.some((p) =>
    isProductAffiliateUrl(p.affiliateUrl)
  );

  return (
    <div className="mx-auto flex w-full max-w-6xl flex-col gap-5 p-4 pt-6">
      <header className="flex items-start gap-3">
        <Link
          href="/shop"
          className="mt-0.5 rounded-lg p-1 hover:bg-surface-elevated"
          aria-label="Zurück zum Shop"
        >
          <ArrowLeft className="h-6 w-6" />
        </Link>
        <div className="min-w-0 flex-1">
          <h1 className="text-2xl font-bold">Ersatzteile</h1>
          <p className="text-sm text-text-secondary">
            Featured Parts · /shop/parts · Collection{" "}
            <span className="font-medium text-text-primary">featured-parts</span>
          </p>
        </div>
      </header>

      <section className="rounded-2xl border border-accent/40 bg-accent/10 p-4">
        <div className="flex items-start gap-3">
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-accent/20 text-accent">
            <Store className="h-5 w-5" />
          </div>
          <div className="min-w-0 flex-1">
            <h2 className="text-base font-bold">AetherRide Parts</h2>
            <p className="mt-0.5 text-xs text-text-secondary">
              {hasLiveProductUrls
                ? "Live-Produktlinks aus dem gekoppelten Katalog."
                : "Catalog wird geladen / Store gekoppelt — In-App-Vorschau aus dem Phase-A-Katalog. Checkout-URLs erscheinen, sobald featured-parts Produkt-Deep-Links verfügbar sind."}
            </p>
            <p className="mt-2 text-[11px] text-text-secondary">
              Externe Collection (Owner):{" "}
              <span className="break-all">{FEATURED_PARTS_COLLECTION}</span>
            </p>
          </div>
        </div>
      </section>

      {parts.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-border bg-surface p-8 text-center">
          <Package className="mx-auto mb-3 h-8 w-8 text-text-secondary" />
          <p className="font-medium">Catalog wird geladen / Store gekoppelt</p>
          <p className="mt-1 text-sm text-text-secondary">
            Sobald die Shopify Collection featured-parts angebunden ist, erscheinen
            hier die Ersatzteile.
          </p>
          <Link
            href="/shop"
            className="mt-4 inline-flex rounded-xl bg-accent px-4 py-2 text-sm font-semibold text-white"
          >
            Zum Shop-Hub
          </Link>
        </div>
      ) : (
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {parts.map((product) => (
            <PartsCard key={product.id} product={product} />
          ))}
        </div>
      )}

      <p className="text-center text-xs text-text-secondary">
        Nur Produkt-URLs als Outbound · keine Händler-Homepages ·{" "}
        <Link href="/shop" className="text-accent">
          Alle Shop-Bereiche
        </Link>
      </p>
    </div>
  );
}
