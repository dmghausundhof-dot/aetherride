"use client";

import { ArrowLeft, ExternalLink } from "lucide-react";
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
  const redirects = useCartStore((s) => s.redirects);
  const recordAffiliateRedirect = useCartStore((s) => s.recordAffiliateRedirect);
  const bikes = useAppStore((s) => s.bikes);
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const activeBike = bikes.find((b) => b.id === activeBikeId) || bikes[0];

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
