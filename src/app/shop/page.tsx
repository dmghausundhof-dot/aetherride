"use client";

import { useMemo, useState } from "react";
import { ExternalLink, ShoppingBag, Sparkles } from "lucide-react";
import { useAppStore } from "@/store/useAppStore";
import { useCartStore } from "@/store/useCartStore";
import { SHOP_PRODUCTS } from "@/lib/shop/catalog";
import { allProductRecommendations } from "@/lib/shop/recommendations";
import {
  MARKETPLACE_LEGAL,
  buildMarketplaceDraft,
} from "@/lib/shop/marketplace";
import {
  aggregateVerdict,
  checkCandidateOnBike,
} from "@/lib/compatibility/engine";
import { VerdictPill } from "@/components/garage/VerdictPill";
import { slotLabel } from "@/lib/catalog/slots";
import type { CompatibilityVerdict } from "@/types";
import Link from "next/link";

export default function ShopPage() {
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const bikes = useAppStore((s) => s.bikes);
  const rides = useAppStore((s) => s.rides);
  const consents = useAppStore((s) => s.consents);
  const commerceMode = useAppStore((s) => s.commerceMode);
  const setCommerceMode = useAppStore((s) => s.setCommerceMode);
  const addItem = useCartStore((s) => s.addItem);
  const cartItems = useCartStore((s) => s.items);
  const activeBike = bikes.find((b) => b.id === activeBikeId) || bikes[0];
  const [hideIncompatible, setHideIncompatible] = useState(true);
  const [legalOk, setLegalOk] = useState(false);

  const productConsent =
    consents.find((c) => c.purpose === "product_recommendations")?.granted ??
    false;

  const triggered = useMemo(() => {
    if (!activeBike || !productConsent) return [];
    const setup = activeBike.setups.find((s) => s.isCurrent);
    return allProductRecommendations({
      bike: activeBike,
      rides,
      setup,
    });
  }, [activeBike, rides, productConsent]);

  const ranked = useMemo(() => {
    if (!activeBike) return [];
    return SHOP_PRODUCTS.map((p) => {
      const results = checkCandidateOnBike(
        activeBike,
        p.slot,
        p.componentModelId
      );
      const verdict: CompatibilityVerdict = results.length
        ? aggregateVerdict(results)
        : "INSUFFICIENT_DATA";
      return { product: p, verdict, results };
    }).filter((row) =>
      hideIncompatible ? row.verdict !== "INCOMPATIBLE" : true
    );
  }, [activeBike, hideIncompatible]);

  const draft = buildMarketplaceDraft(
    cartItems.map((i) => ({
      name: i.name,
      priceEur: i.price,
      qty: i.quantity,
    }))
  );

  return (
    <div className="flex flex-col gap-5 p-4 pt-6">
      <header>
        <h1 className="text-2xl font-bold">Shop</h1>
        <p className="text-sm text-text-secondary">
          F-SHP-001/002/003 · Kompat · Anlass · Affiliate/Marketplace
        </p>
      </header>

      <div className="grid grid-cols-2 gap-2">
        <button
          type="button"
          onClick={() => setCommerceMode("affiliate")}
          className={`rounded-xl py-2 text-sm font-medium ${
            commerceMode === "affiliate"
              ? "bg-accent text-white"
              : "bg-surface-elevated"
          }`}
        >
          Affiliate (MVP+1)
        </button>
        <button
          type="button"
          onClick={() => setCommerceMode("marketplace")}
          className={`rounded-xl py-2 text-sm font-medium ${
            commerceMode === "marketplace"
              ? "bg-accent text-white"
              : "bg-surface-elevated"
          }`}
        >
          Marketplace (P3)
        </button>
      </div>

      {activeBike && (
        <div className="rounded-xl border border-accent/30 bg-accent/10 px-3 py-2 text-sm">
          <span className="font-medium text-accent">Für dein Bike: </span>
          {activeBike.name}
        </div>
      )}

      {productConsent && triggered.length > 0 && (
        <section className="rounded-2xl border border-warning/40 bg-warning/10 p-4">
          <h3 className="mb-2 flex items-center gap-2 font-semibold">
            <Sparkles className="h-4 w-4" /> Anlassbezogene Empfehlungen
          </h3>
          <p className="mb-2 text-[11px] text-text-secondary">
            Nur mit Datenpunkt (F-SHP-002) · Velopit / BIKE Magazin
          </p>
          {triggered.map((r) => (
            <div
              key={r.id}
              className="mb-2 rounded-xl border border-border bg-surface p-3 text-sm"
            >
              <div className="font-medium">{r.title}</div>
              <p className="mt-1 text-xs text-warning">
                Auslöser: {r.triggeringDataPoint}
              </p>
              <p className="mt-1 text-xs text-text-secondary">{r.reason}</p>
              <a
                href={r.product.affiliateUrl}
                target="_blank"
                rel="noreferrer"
                className="mt-2 inline-flex items-center gap-1 text-xs text-accent"
              >
                Beim Partner · {r.product.priceEur} €{" "}
                <ExternalLink className="h-3 w-3" />
              </a>
            </div>
          ))}
        </section>
      )}

      {!productConsent && (
        <p className="text-xs text-text-secondary">
          Produktempfehlungen Opt-in unter{" "}
          <Link href="/privacy" className="text-accent">
            Privatsphäre
          </Link>
          .
        </p>
      )}

      <label className="flex items-center gap-2 text-sm text-text-secondary">
        <input
          type="checkbox"
          checked={hideIncompatible}
          onChange={(e) => setHideIncompatible(e.target.checked)}
        />
        Inkompatible ausblenden
      </label>

      <div className="flex flex-col gap-3">
        {ranked.map(({ product: p, verdict, results }) => (
          <div
            key={p.id}
            className="rounded-2xl border border-border bg-surface p-4"
          >
            <div className="mb-2 flex items-start justify-between gap-2">
              <VerdictPill verdict={verdict} />
              <span className="text-xs text-text-secondary">
                {slotLabel(p.slot)}
              </span>
            </div>
            <div className="text-xs uppercase tracking-wide text-text-secondary">
              {p.manufacturer}
            </div>
            <h3 className="mt-0.5 font-semibold">{p.name}</h3>
            <div className="mt-1 text-lg font-bold tabular-nums text-accent">
              {p.priceEur.toLocaleString("de-DE")} €
            </div>
            <p className="mt-2 text-xs text-text-secondary">{p.description}</p>
            {results[0] && (
              <details className="mt-2 text-xs text-text-secondary">
                <summary className="cursor-pointer text-accent">
                  Begründungskette
                </summary>
                <ul className="mt-1 list-disc pl-4">
                  {results.slice(0, 4).map((r) => (
                    <li key={r.ruleCode}>
                      {r.ruleCode}: {r.explainDe}
                    </li>
                  ))}
                </ul>
              </details>
            )}
            {verdict === "INSUFFICIENT_DATA" && (
              <p className="mt-2 text-xs text-warning">
                Nicht als „passend“ beworben — Attribute fehlen.
              </p>
            )}
            <div className="mt-3 flex gap-2">
              <button
                type="button"
                disabled={verdict === "INCOMPATIBLE"}
                onClick={() =>
                  addItem({
                    productId: p.id,
                    name: p.name,
                    manufacturer: p.manufacturer,
                    price: p.priceEur,
                    quantity: 1,
                    compatibilityMatch: verdict === "COMPATIBLE",
                    verdict,
                    affiliateUrl: p.affiliateUrl,
                    merchantName: p.merchantName,
                  })
                }
                className="flex-1 rounded-xl border border-border py-2.5 text-sm font-medium disabled:opacity-40"
              >
                Merken
              </button>
              {commerceMode === "affiliate" ? (
                <a
                  href={p.affiliateUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex flex-[2] items-center justify-center gap-2 rounded-xl bg-accent py-2.5 text-sm font-semibold text-white"
                >
                  Beim Partner <ExternalLink className="h-4 w-4" />
                </a>
              ) : (
                <Link
                  href="/checkout"
                  className="flex flex-[2] items-center justify-center rounded-xl bg-accent py-2.5 text-sm font-semibold text-white"
                >
                  Marketplace-Checkout
                </Link>
              )}
            </div>
          </div>
        ))}
      </div>

      {commerceMode === "marketplace" && (
        <section className="rounded-2xl border border-border bg-surface p-4 text-xs text-text-secondary">
          <h3 className="mb-2 text-sm font-semibold text-foreground">
            Phase-3-Pflichten (Demo)
          </h3>
          <p>{MARKETPLACE_LEGAL.imprint}</p>
          <p className="mt-1">{MARKETPLACE_LEGAL.withdrawal}</p>
          <p className="mt-1">
            {MARKETPLACE_LEGAL.shipping} · Warenkorb{" "}
            {draft.totalEur.toFixed(2)} € inkl. Versand{" "}
            {draft.shippingEur.toFixed(2)} €
          </p>
          <p className="mt-1">{MARKETPLACE_LEGAL.warranty}</p>
          <p className="mt-1">{MARKETPLACE_LEGAL.gpsr}</p>
          <p className="mt-1">{MARKETPLACE_LEGAL.batteryNote}</p>
          <p className="mt-1">{draft.stripeNote}</p>
          <label className="mt-3 flex items-start gap-2 text-sm text-foreground">
            <input
              type="checkbox"
              checked={legalOk}
              onChange={(e) => setLegalOk(e.target.checked)}
              className="mt-1"
            />
            Pflichtangaben gelesen (Widerruf, Versand, GPSR)
          </label>
          <Link
            href="/checkout"
            className={`mt-3 block rounded-xl py-2.5 text-center text-sm font-semibold text-white ${
              legalOk
                ? "bg-accent"
                : "pointer-events-none bg-surface-elevated opacity-40"
            }`}
          >
            Weiter zur Demo-Kasse (kein echtes Stripe)
          </Link>
        </section>
      )}

      <div className="rounded-xl border border-dashed border-border p-4 text-center text-sm text-text-secondary">
        <ShoppingBag className="mx-auto mb-2 h-8 w-8 opacity-40" />
        Spec 8.5: Affiliate zuerst · Marketplace nur bei Nachfragebeleg
        <div className="mt-2">
          <Link href="/checkout" className="text-accent">
            Merkliste / Checkout
          </Link>
        </div>
      </div>
    </div>
  );
}
