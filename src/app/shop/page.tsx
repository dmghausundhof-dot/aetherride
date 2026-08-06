"use client";

import { useMemo, useState } from "react";
import { ExternalLink, ShoppingBag } from "lucide-react";
import { useAppStore } from "@/store/useAppStore";
import { useCartStore } from "@/store/useCartStore";
import { SHOP_PRODUCTS } from "@/lib/shop/catalog";
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
  const addItem = useCartStore((s) => s.addItem);
  const activeBike = bikes.find((b) => b.id === activeBikeId) || bikes[0];
  const [hideIncompatible, setHideIncompatible] = useState(true);

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

  return (
    <div className="flex flex-col gap-5 p-4 pt-6">
      <header>
        <h1 className="text-2xl font-bold">Shop</h1>
        <p className="text-sm text-text-secondary">
          Affiliate-Partnerkatalog · Urteil aus Kompat-Engine (F-SHP-001)
        </p>
      </header>

      {activeBike && (
        <div className="rounded-xl border border-accent/30 bg-accent/10 px-3 py-2 text-sm">
          <span className="font-medium text-accent">Für dein Bike: </span>
          {activeBike.name}
        </div>
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
            {verdict === "INCOMPATIBLE" && (
              <p className="mt-2 text-xs text-error">
                Inkompatibel zum aktiven Bike — nicht als passend beworben
                (F-SHP-001).
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
              <a
                href={p.affiliateUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="flex flex-[2] items-center justify-center gap-2 rounded-xl bg-accent py-2.5 text-sm font-semibold text-white"
              >
                Beim Partner <ExternalLink className="h-4 w-4" />
              </a>
            </div>
            <p className="mt-1 text-center text-[10px] text-text-secondary">
              {p.merchantName} · Affiliate · kein Zahlungsverkehr in AetherRide
            </p>
          </div>
        ))}
      </div>

      <div className="rounded-xl border border-dashed border-border p-4 text-center text-sm text-text-secondary">
        <ShoppingBag className="mx-auto mb-2 h-8 w-8 opacity-40" />
        Spec 0.4.4: Affiliate weiterleiten — Checkout beim Händler (F-SHP-003)
        <div className="mt-2">
          <Link href="/checkout" className="text-accent">
            Merkliste / Weiterleitungs-Log
          </Link>
        </div>
      </div>
    </div>
  );
}
