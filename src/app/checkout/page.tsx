"use client";

import { ArrowLeft, ExternalLink, Minus, Plus, Trash2 } from "lucide-react";
import Link from "next/link";
import { useCartStore } from "@/store/useCartStore";
import { SHOP_PRODUCTS } from "@/lib/shop/catalog";
import { VerdictPill } from "@/components/garage/VerdictPill";
import {
  aggregateVerdict,
  checkCandidateOnBike,
} from "@/lib/compatibility/engine";
import { useAppStore } from "@/store/useAppStore";

export default function CheckoutPage() {
  const items = useCartStore((s) => s.items);
  const removeItem = useCartStore((s) => s.removeItem);
  const updateQuantity = useCartStore((s) => s.updateQuantity);
  const getTotal = useCartStore((s) => s.getTotal);
  const redirects = useCartStore((s) => s.redirects);
  const recordAffiliateRedirect = useCartStore((s) => s.recordAffiliateRedirect);
  const bikes = useAppStore((s) => s.bikes);
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const activeBike = bikes.find((b) => b.id === activeBikeId) || bikes[0];

  const openPartnerFromCart = (itemId: string) => {
    const item = items.find((i) => i.id === itemId);
    if (!item?.affiliateUrl) return;
    recordAffiliateRedirect(item);
    window.open(item.affiliateUrl, "_blank", "noopener,noreferrer");
  };

  const openPartner = (productId: string) => {
    const p = SHOP_PRODUCTS.find((x) => x.id === productId);
    if (!p || !activeBike) return;
    const results = checkCandidateOnBike(
      activeBike,
      p.slot,
      p.componentModelId
    );
    const verdict = results.length
      ? aggregateVerdict(results)
      : ("INSUFFICIENT_DATA" as const);
    recordAffiliateRedirect({
      id: p.id,
      productId: p.id,
      name: p.name,
      manufacturer: p.manufacturer,
      price: p.priceEur,
      quantity: 1,
      compatibilityMatch: verdict === "COMPATIBLE" || verdict === "CONDITIONAL",
      verdict,
      affiliateUrl: p.affiliateUrl,
      merchantName: p.merchantName,
    });
    window.open(p.affiliateUrl, "_blank", "noopener,noreferrer");
  };

  return (
    <div className="flex flex-col gap-5 p-4 pt-6">
      <header className="flex items-center gap-3">
        <Link href="/shop" className="p-1">
          <ArrowLeft className="h-6 w-6" />
        </Link>
        <div>
          <h1 className="text-xl font-bold">Partner-Checkout</h1>
          <p className="text-xs text-text-secondary">
            F-SHP-003 Affiliate — kein Zahlungsverkehr in der App
          </p>
        </div>
      </header>

      <section className="rounded-2xl border border-border bg-surface p-4 text-sm text-text-secondary">
        Kauf und Versand laufen beim Partnerhändler. AetherRide prüft nur
        Kompatibilität und leitet weiter (Spec 0.4.4).
      </section>

      <section>
        <h2 className="mb-2 font-semibold">Merkliste / Warenkorb</h2>
        {items.length === 0 ? (
          <p className="text-sm text-text-secondary">
            Leer — im Shop „Merken“, dann hier zum Partner weiterleiten.
          </p>
        ) : (
          <div className="flex flex-col gap-2">
            {items.map((item) => (
              <div
                key={item.id}
                className="rounded-xl border border-border bg-surface p-3"
              >
                <div className="flex items-start justify-between gap-2">
                  <div>
                    <div className="text-sm font-medium">{item.name}</div>
                    <div className="text-xs text-text-secondary">
                      {item.manufacturer} · {item.price.toFixed(0)} €
                      {item.merchantName ? ` · ${item.merchantName}` : ""}
                    </div>
                    {item.verdict && (
                      <div className="mt-1">
                        <VerdictPill verdict={item.verdict} />
                      </div>
                    )}
                  </div>
                  <button
                    type="button"
                    onClick={() => removeItem(item.id)}
                    className="p-1 text-text-secondary"
                    aria-label="Entfernen"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
                <div className="mt-2 flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <button
                      type="button"
                      onClick={() =>
                        updateQuantity(item.id, item.quantity - 1)
                      }
                      className="rounded bg-surface-elevated p-1"
                    >
                      <Minus className="h-3 w-3" />
                    </button>
                    <span className="tabular-nums text-sm">{item.quantity}</span>
                    <button
                      type="button"
                      onClick={() =>
                        updateQuantity(item.id, item.quantity + 1)
                      }
                      className="rounded bg-surface-elevated p-1"
                    >
                      <Plus className="h-3 w-3" />
                    </button>
                  </div>
                  <button
                    type="button"
                    disabled={!item.affiliateUrl}
                    onClick={() => openPartnerFromCart(item.id)}
                    className="flex items-center gap-1 rounded-lg bg-accent px-3 py-1.5 text-xs font-semibold text-white disabled:opacity-40"
                  >
                    Zum Partner <ExternalLink className="h-3 w-3" />
                  </button>
                </div>
              </div>
            ))}
            <p className="text-right text-sm font-medium tabular-nums">
              Summe (Partner): {getTotal().toFixed(0)} €
            </p>
          </div>
        )}
      </section>

      <section>
        <h2 className="mb-2 font-semibold">Schnell zum Partner</h2>
        <div className="flex flex-col gap-2">
          {SHOP_PRODUCTS.slice(0, 4).map((p) => {
            const verdict = activeBike
              ? aggregateVerdict(
                  checkCandidateOnBike(activeBike, p.slot, p.componentModelId)
                )
              : ("INSUFFICIENT_DATA" as const);
            return (
              <button
                key={p.id}
                type="button"
                onClick={() => openPartner(p.id)}
                className="flex items-center justify-between rounded-xl border border-border bg-surface p-3 text-left"
              >
                <div>
                  <div className="text-sm font-medium">{p.name}</div>
                  <div className="mt-1">
                    <VerdictPill verdict={verdict} />
                  </div>
                </div>
                <ExternalLink className="h-4 w-4 text-accent" />
              </button>
            );
          })}
        </div>
      </section>

      <section>
        <h2 className="mb-2 font-semibold">Weiterleitungs-Log</h2>
        {redirects.length === 0 ? (
          <p className="text-sm text-text-secondary">Noch keine Weiterleitungen.</p>
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
