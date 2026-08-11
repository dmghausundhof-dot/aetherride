"use client";

import { ArrowLeft, ExternalLink, Trash2 } from "lucide-react";
import Link from "next/link";
import { useCartStore } from "@/store/useCartStore";
import { SHOP_PRODUCTS, getShopProduct } from "@/lib/shop/catalog";
import { merchantCtaUrl } from "@/lib/shop/merchantLinks";
import { ProductVisual } from "@/components/shop/ProductVisual";
import { VerdictPill } from "@/components/garage/VerdictPill";
import {
  aggregateVerdict,
  checkCandidateOnBike,
} from "@/lib/compatibility/engine";
import { useAppStore } from "@/store/useAppStore";

export default function CheckoutPage() {
  const items = useCartStore((s) => s.items);
  const redirects = useCartStore((s) => s.redirects);
  const removeItem = useCartStore((s) => s.removeItem);
  const recordAffiliateRedirect = useCartStore((s) => s.recordAffiliateRedirect);
  const getTotal = useCartStore((s) => s.getTotal);
  const bikes = useAppStore((s) => s.bikes);
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const activeBike = bikes.find((b) => b.id === activeBikeId) || bikes[0];

  const openPartner = (productId: string) => {
    const fromCart = items.find((i) => i.productId === productId);
    const p = getShopProduct(productId) ?? SHOP_PRODUCTS.find((x) => x.id === productId);
    if (!p) return;

    const url = merchantCtaUrl(fromCart?.affiliateUrl ?? p.affiliateUrl);
    if (!url) return; // no bare homepage / unknown — omit Zum Händler

    let verdict = fromCart?.verdict;
    if (!verdict && activeBike) {
      const results = checkCandidateOnBike(
        activeBike,
        p.slot,
        p.componentModelId
      );
      verdict = results.length
        ? aggregateVerdict(results)
        : ("INSUFFICIENT_DATA" as const);
    }
    const resolved = verdict ?? ("INSUFFICIENT_DATA" as const);

    recordAffiliateRedirect({
      id: fromCart?.id ?? p.id,
      productId: p.id,
      name: p.name,
      manufacturer: p.manufacturer,
      price: p.priceEur,
      quantity: fromCart?.quantity ?? 1,
      compatibilityMatch:
        resolved === "COMPATIBLE" || resolved === "CONDITIONAL",
      verdict: resolved,
      affiliateUrl: url,
      merchantName: fromCart?.merchantName ?? p.merchantName,
    });
    window.open(url, "_blank", "noopener,noreferrer");
  };

  const total = getTotal();

  return (
    <div className="flex flex-col gap-5 p-4 pt-6">
      <header className="flex items-center gap-3">
        <Link href="/shop" className="p-1" aria-label="Zurück zum Shop">
          <ArrowLeft className="h-6 w-6" />
        </Link>
        <div>
          <h1 className="text-xl font-bold">Merkliste</h1>
          <p className="text-xs text-text-secondary">
            Kauf und Versand laufen beim Partnerhändler
          </p>
        </div>
      </header>

      <section className="rounded-2xl border border-border bg-surface p-4 text-sm text-text-secondary">
        AetherRide prüft Kompatibilität zu deinem Bike und leitet dich zum
        Partner weiter — ohne Zahlungsverkehr in der App.
      </section>

      <section>
        <div className="mb-2 flex items-center justify-between">
          <h2 className="font-semibold">Deine Merkliste</h2>
          {items.length > 0 && (
            <span className="text-xs tabular-nums text-text-secondary">
              {total.toLocaleString("de-DE")} €
            </span>
          )}
        </div>
        {items.length === 0 ? (
          <div className="rounded-xl border border-dashed border-border p-4 text-center text-sm text-text-secondary">
            Noch nichts gemerkt.{" "}
            <Link href="/shop" className="text-accent">
              Im Shop stöbern
            </Link>
          </div>
        ) : (
          <div className="flex flex-col gap-2">
            {items.map((item) => {
              const product = getShopProduct(item.productId);
              const partnerUrl = merchantCtaUrl(
                item.affiliateUrl ?? product?.affiliateUrl
              );
              return (
                <div
                  key={item.id}
                  className="flex gap-3 rounded-xl border border-border bg-surface p-3"
                >
                  {product ? (
                    <ProductVisual product={product} compact />
                  ) : (
                    <div className="h-12 w-12 rounded-xl bg-surface-elevated" />
                  )}
                  <div className="min-w-0 flex-1">
                    <div className="text-sm font-medium leading-snug">
                      {item.name}
                    </div>
                    <div className="mt-0.5 text-xs text-text-secondary">
                      {item.manufacturer}
                      {item.quantity > 1 ? ` · ×${item.quantity}` : ""} ·{" "}
                      {(item.price * item.quantity).toLocaleString("de-DE")} €
                    </div>
                    {item.verdict && (
                      <div className="mt-1">
                        <VerdictPill verdict={item.verdict} />
                      </div>
                    )}
                    <div className="mt-2 flex gap-2">
                      {partnerUrl ? (
                        <button
                          type="button"
                          onClick={() => openPartner(item.productId)}
                          className="inline-flex flex-1 items-center justify-center gap-1 rounded-lg bg-accent py-2 text-xs font-semibold text-white"
                        >
                          Zum Händler <ExternalLink className="h-3.5 w-3.5" />
                        </button>
                      ) : null}
                      <button
                        type="button"
                        onClick={() => removeItem(item.id)}
                        className="rounded-lg border border-border px-2.5"
                        aria-label="Entfernen"
                      >
                        <Trash2 className="h-4 w-4 text-text-secondary" />
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </section>

      {items.length === 0 && (
        <section>
          <h2 className="mb-2 font-semibold">Beliebte Einstiege</h2>
          <div className="flex flex-col gap-2">
            {SHOP_PRODUCTS.filter(
              (p) =>
                ["chain", "brake_pads_front", "tire_front", "cassette"].includes(
                  p.slot
                ) && merchantCtaUrl(p.affiliateUrl)
            )
              .slice(0, 4)
              .map((p) => {
                const verdict = activeBike
                  ? aggregateVerdict(
                      checkCandidateOnBike(
                        activeBike,
                        p.slot,
                        p.componentModelId
                      )
                    )
                  : ("INSUFFICIENT_DATA" as const);
                return (
                  <button
                    key={p.id}
                    type="button"
                    onClick={() => openPartner(p.id)}
                    className="flex items-center justify-between rounded-xl border border-border bg-surface p-3 text-left"
                  >
                    <div className="flex items-center gap-3">
                      <ProductVisual product={p} compact />
                      <div>
                        <div className="text-sm font-medium">{p.name}</div>
                        <div className="mt-1">
                          <VerdictPill verdict={verdict} />
                        </div>
                      </div>
                    </div>
                    <ExternalLink className="h-4 w-4 shrink-0 text-accent" />
                  </button>
                );
              })}
          </div>
        </section>
      )}

      <section>
        <h2 className="mb-2 font-semibold">Weiterleitungen</h2>
        {redirects.length === 0 ? (
          <p className="text-sm text-text-secondary">
            Noch keine Partner-Weiterleitungen.
          </p>
        ) : (
          <div className="flex flex-col gap-2">
            {redirects.map((r) => (
              <div
                key={r.id}
                className="rounded-xl border border-border bg-surface p-3 text-sm"
              >
                <div className="font-medium">{r.items[0]?.name}</div>
                <div className="text-xs text-text-secondary">
                  {new Date(r.createdAt).toLocaleString("de-DE")} ·{" "}
                  {r.merchantName}
                </div>
                {r.items[0]?.verdict && (
                  <div className="mt-1">
                    <VerdictPill verdict={r.items[0].verdict} />
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}
