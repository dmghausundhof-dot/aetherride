"use client";

import { Suspense, useEffect, useMemo, useState } from "react";
import {
  Bookmark,
  ExternalLink,
  ShoppingBag,
  Sparkles,
  Wrench,
} from "lucide-react";
import { useSearchParams } from "next/navigation";
import { useAppStore } from "@/store/useAppStore";
import { useCartStore } from "@/store/useCartStore";
import {
  SHOP_BROWSE_SLOTS,
  SHOP_PRODUCTS,
  getShopProduct,
  type ShopProduct,
} from "@/lib/shop/catalog";
import { allProductRecommendations } from "@/lib/shop/recommendations";
import {
  getMarketplaceLegal,
  buildMarketplaceDraft,
} from "@/lib/shop/marketplace";
import {
  aggregateVerdict,
  checkCandidateOnBike,
} from "@/lib/compatibility/engine";
import { VerdictPill } from "@/components/garage/VerdictPill";
import { ProductVisual } from "@/components/shop/ProductVisual";
import { slotLabel } from "@/lib/catalog/slots";
import type { CompatibilityVerdict, ComponentSlot } from "@/types";
import Link from "next/link";
import { cn } from "@/lib/utils";

type JobId = "replace" | "browse" | "season";
type SlotFilter = ComponentSlot | "all";

type RankedProduct = {
  product: ShopProduct;
  verdict: CompatibilityVerdict;
  results: ReturnType<typeof checkCandidateOnBike>;
};

function isBrowseSlot(value: string | null): value is SlotFilter {
  if (!value) return false;
  return SHOP_BROWSE_SLOTS.some((s) => s.slot === value);
}

function matchesSlotFilter(product: ShopProduct, filter: SlotFilter): boolean {
  if (filter === "all") return true;
  if (filter === "brake_pads_front") {
    return (
      product.slot === "brake_pads_front" || product.slot === "brake_pads_rear"
    );
  }
  if (filter === "tire_front") {
    return product.slot === "tire_front" || product.slot === "tire_rear";
  }
  return product.slot === filter;
}

function ShopPageInner() {
  const searchParams = useSearchParams();
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
  const [slotFilter, setSlotFilter] = useState<SlotFilter>("all");
  const [job, setJob] = useState<JobId>("browse");
  const [focusId, setFocusId] = useState<string | null>(null);
  const legal = getMarketplaceLegal();
  const marketplaceEnabled =
    process.env.NEXT_PUBLIC_MARKETPLACE_ENABLED === "true";

  const productConsent =
    consents.find((c) => c.purpose === "product_recommendations")?.granted ??
    false;

  useEffect(() => {
    const focus = searchParams.get("focus");
    const slot = searchParams.get("slot");
    const jobParam = searchParams.get("job");

    if (focus && getShopProduct(focus)) {
      setFocusId(focus);
      const p = getShopProduct(focus)!;
      const browseMatch = SHOP_BROWSE_SLOTS.find(
        (s) =>
          s.slot === p.slot ||
          (s.slot === "brake_pads_front" &&
            (p.slot === "brake_pads_front" || p.slot === "brake_pads_rear")) ||
          (s.slot === "tire_front" &&
            (p.slot === "tire_front" || p.slot === "tire_rear"))
      );
      if (browseMatch && browseMatch.slot !== "all") {
        setSlotFilter(browseMatch.slot);
      }
    }
    if (isBrowseSlot(slot)) {
      setSlotFilter(slot);
    }
    if (jobParam === "replace" || jobParam === "browse" || jobParam === "season") {
      setJob(jobParam);
    } else if (focus || slot) {
      setJob(slot || focus ? "replace" : "browse");
    }
  }, [searchParams]);

  const triggered = useMemo(() => {
    if (!activeBike || !productConsent) return [];
    const setup = activeBike.setups.find((s) => s.isCurrent);
    return allProductRecommendations({
      bike: activeBike,
      rides,
      setup,
    });
  }, [activeBike, rides, productConsent]);

  const wearRecs = useMemo(
    () => triggered.filter((r) => r.triggerKind === "wear"),
    [triggered]
  );
  const seasonRecs = useMemo(
    () => triggered.filter((r) => r.triggerKind === "season"),
    [triggered]
  );

  const rankedAll = useMemo((): RankedProduct[] => {
    if (!activeBike) {
      return SHOP_PRODUCTS.map((product) => ({
        product,
        verdict: "INSUFFICIENT_DATA" as const,
        results: [],
      }));
    }
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
    });
  }, [activeBike]);

  const ranked = useMemo(() => {
    let list = rankedAll.filter((row) =>
      matchesSlotFilter(row.product, slotFilter)
    );
    if (hideIncompatible) {
      list = list.filter((row) => row.verdict !== "INCOMPATIBLE");
    }
    if (job === "replace") {
      const wearIds = new Set(wearRecs.map((r) => r.product.id));
      const wearSlots = new Set(wearRecs.map((r) => r.product.slot));
      list = list.filter(
        (row) =>
          wearIds.has(row.product.id) ||
          wearSlots.has(row.product.slot) ||
          row.product.slot === "chain" ||
          row.product.slot === "brake_pads_front" ||
          row.product.slot === "cassette" ||
          row.product.slot === "tire_front" ||
          row.product.slot === "tire_rear"
      );
    }
    if (job === "season") {
      const seasonIds = new Set(seasonRecs.map((r) => r.product.id));
      list = list.filter(
        (row) =>
          seasonIds.has(row.product.id) ||
          row.product.slot === "tire_front" ||
          row.product.slot === "tire_rear"
      );
    }
    if (focusId) {
      list = [...list].sort((a, b) => {
        if (a.product.id === focusId) return -1;
        if (b.product.id === focusId) return 1;
        return 0;
      });
    }
    return list;
  }, [
    rankedAll,
    slotFilter,
    hideIncompatible,
    job,
    wearRecs,
    seasonRecs,
    focusId,
  ]);

  const alternativesFor = (row: RankedProduct): RankedProduct[] => {
    if (row.verdict === "COMPATIBLE") return [];
    return rankedAll
      .filter(
        (alt) =>
          alt.product.id !== row.product.id &&
          alt.product.slot === row.product.slot &&
          alt.verdict === "COMPATIBLE"
      )
      .slice(0, 2);
  };

  const draft = buildMarketplaceDraft(
    cartItems.map((i) => ({
      name: i.name,
      priceEur: i.price,
      qty: i.quantity,
    }))
  );

  const cartCount = cartItems.reduce((n, i) => n + i.quantity, 0);

  const addToList = (p: ShopProduct, verdict: CompatibilityVerdict) => {
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
    });
  };

  return (
    <div className="flex flex-col gap-5 p-4 pt-6">
      <header className="flex items-start justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold">Shop</h1>
          <p className="text-sm text-text-secondary">
            Passende Teile für dein Bike — Beispielkatalog (kein Live-Partner)
          </p>
        </div>
        <Link
          href="/checkout"
          className="relative flex h-10 w-10 items-center justify-center rounded-full border border-border bg-surface-elevated"
          aria-label={`Merkliste${cartCount ? `, ${cartCount} Artikel` : ""}`}
        >
          <Bookmark className="h-5 w-5 text-accent" />
          {cartCount > 0 && (
            <span className="absolute -right-1 -top-1 flex h-5 min-w-5 items-center justify-center rounded-full bg-accent px-1 text-[10px] font-bold text-white">
              {cartCount}
            </span>
          )}
        </Link>
      </header>

      {activeBike ? (
        <div className="flex items-center justify-between gap-2 rounded-xl border border-accent/30 bg-accent/10 px-3 py-2 text-sm">
          <div>
            <span className="font-medium text-accent">Für dein Bike: </span>
            {activeBike.name}
          </div>
          <Link href="/garage" className="shrink-0 text-xs text-accent">
            Wechseln
          </Link>
        </div>
      ) : (
        <div className="rounded-2xl border border-border bg-surface p-4 text-center">
          <p className="text-sm font-medium">Passende Teile nach deinem Bike</p>
          <p className="mt-1 text-xs text-text-secondary">
            Lege ein Bike an — dann filtern wir nach Kompatibilität statt nach
            Rätselraten.
          </p>
          <Link
            href="/garage?wizard=catalog"
            className="mt-3 inline-flex rounded-xl bg-accent px-4 py-2 text-sm font-semibold text-white"
          >
            Bike anlegen
          </Link>
        </div>
      )}

      {!activeBike ? (
        <section className="space-y-3">
          <p className="text-xs text-text-secondary">
            Beispiele aus dem Beispielkatalog (ohne Kompat-Prüfung):
          </p>
          {SHOP_PRODUCTS.slice(0, 4).map((p) => (
            <div
              key={p.id}
              className="rounded-2xl border border-border bg-surface p-4"
            >
              <div className="flex gap-3">
                <ProductVisual product={p} />
                <div className="min-w-0 flex-1">
                  <div className="text-xs uppercase tracking-wide text-text-secondary">
                    {p.manufacturer}
                  </div>
                  <h3 className="mt-0.5 font-semibold leading-snug">{p.name}</h3>
                  <div className="mt-1 text-lg font-bold tabular-nums text-accent">
                    {p.priceEur.toLocaleString("de-DE")} €
                  </div>
                </div>
              </div>
              <a
                href={p.affiliateUrl}
                target="_blank"
                rel="noreferrer"
                className="mt-3 inline-flex w-full items-center justify-center gap-1 rounded-xl bg-accent py-2.5 text-sm font-semibold text-white"
              >
                Beim Beispiel-Händler ansehen{" "}
                <ExternalLink className="h-3.5 w-3.5" />
              </a>
            </div>
          ))}
          <p className="pb-2 text-center text-[11px] text-text-secondary">
            Beispielkatalog — keine Live-Partner; Preise nur zur Orientierung
          </p>
        </section>
      ) : null}

      {activeBike ? (
      <>
      <div className="grid grid-cols-3 gap-2">
        {(
          [
            ["replace", "Jetzt ersetzen", Wrench],
            ["browse", "Alle Teile", ShoppingBag],
            ["season", "Saison", Sparkles],
          ] as const
        ).map(([id, label, Icon]) => (
          <button
            key={id}
            type="button"
            onClick={() => setJob(id)}
            className={cn(
              "flex flex-col items-center gap-1 rounded-xl py-2.5 text-xs font-medium",
              job === id
                ? "bg-accent text-white"
                : "bg-surface-elevated text-text-secondary"
            )}
          >
            <Icon className="h-4 w-4" />
            {label}
          </button>
        ))}
      </div>

      {job === "replace" && productConsent && wearRecs.length > 0 && (
        <section className="rounded-2xl border border-warning/40 bg-warning/10 p-4">
          <h3 className="mb-2 flex items-center gap-2 font-semibold">
            <Sparkles className="h-4 w-4" /> Dein Bike braucht Aufmerksamkeit
          </h3>
          {wearRecs.map((r) => (
            <div
              key={r.id}
              className="mb-2 flex gap-3 rounded-xl border border-border bg-surface p-3 text-sm"
            >
              <ProductVisual product={r.product} compact />
              <div className="min-w-0 flex-1">
                <div className="font-medium">{r.product.name}</div>
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
                  Beim Beispiel-Händler · {r.product.priceEur} €{" "}
                  <ExternalLink className="h-3 w-3" />
                </a>
              </div>
            </div>
          ))}
        </section>
      )}

      {job === "replace" && !productConsent && (
        <p className="text-xs text-text-secondary">
          Anlassbezogene Tipps aktivierst du unter{" "}
          <Link href="/privacy" className="text-accent">
            Privatsphäre
          </Link>
          .
        </p>
      )}

      {job === "season" && seasonRecs.length === 0 && (
        <p className="text-sm text-text-secondary">
          Aktuell keine Saison-Empfehlung — Reifen und Grip-Optionen siehst du
          unten.
        </p>
      )}

      <div className="-mx-4 flex gap-2 overflow-x-auto px-4 pb-1">
        {SHOP_BROWSE_SLOTS.map((s) => (
          <button
            key={s.slot}
            type="button"
            onClick={() => setSlotFilter(s.slot)}
            className={cn(
              "shrink-0 rounded-full px-3 py-1.5 text-xs font-medium",
              slotFilter === s.slot
                ? "bg-accent text-white"
                : "bg-surface-elevated text-text-secondary"
            )}
          >
            {s.label}
          </button>
        ))}
      </div>

      <label className="flex items-center gap-2 text-sm text-text-secondary">
        <input
          type="checkbox"
          checked={hideIncompatible}
          onChange={(e) => setHideIncompatible(e.target.checked)}
        />
        Inkompatible ausblenden
      </label>

      <div className="flex flex-col gap-3">
        {ranked.length === 0 ? (
          <p className="rounded-xl border border-dashed border-border p-4 text-center text-sm text-text-secondary">
            Keine Teile in diesem Filter — Slot wechseln oder Inkompatible
            einblenden.
          </p>
        ) : (
          ranked.map((row) => {
            const { product: p, verdict, results } = row;
            const alts = alternativesFor(row);
            const focused = focusId === p.id;
            return (
              <div
                key={p.id}
                id={`product-${p.id}`}
                className={cn(
                  "rounded-2xl border bg-surface p-4",
                  focused ? "border-accent ring-1 ring-accent/40" : "border-border"
                )}
              >
                <div className="flex gap-3">
                  <ProductVisual product={p} />
                  <div className="min-w-0 flex-1">
                    <div className="mb-1 flex items-start justify-between gap-2">
                      <VerdictPill verdict={verdict} />
                      <span className="text-xs text-text-secondary">
                        {slotLabel(p.slot)}
                      </span>
                    </div>
                    <div className="text-xs uppercase tracking-wide text-text-secondary">
                      {p.manufacturer}
                    </div>
                    <h3 className="mt-0.5 font-semibold leading-snug">{p.name}</h3>
                    <div className="mt-1 text-lg font-bold tabular-nums text-accent">
                      {p.priceEur.toLocaleString("de-DE")} €
                    </div>
                    <p className="mt-1 text-[11px] text-text-secondary">
                      {p.merchantName}
                    </p>
                  </div>
                </div>
                <p className="mt-3 text-xs text-text-secondary">{p.description}</p>
                {results[0] && (
                  <details className="mt-2 text-xs text-text-secondary">
                    <summary className="cursor-pointer text-accent">
                      Warum dieses Urteil?
                    </summary>
                    <ul className="mt-1 list-disc pl-4">
                      {results.slice(0, 4).map((r) => (
                        <li key={r.ruleCode}>{r.explainDe}</li>
                      ))}
                    </ul>
                  </details>
                )}
                {verdict === "INSUFFICIENT_DATA" && activeBike && (
                  <p className="mt-2 text-xs text-text-secondary">
                    Für ein klares Urteil fehlende Attribute in der Garage
                    ergänzen.
                  </p>
                )}
                {alts.length > 0 && (
                  <div className="mt-2 rounded-xl bg-surface-elevated px-3 py-2 text-xs">
                    <div className="font-medium text-foreground">
                      Passendere Alternativen
                    </div>
                    <ul className="mt-1 space-y-1 text-text-secondary">
                      {alts.map((a) => (
                        <li key={a.product.id}>
                          <button
                            type="button"
                            className="text-left text-accent"
                            onClick={() => {
                              setFocusId(a.product.id);
                              setSlotFilter(
                                SHOP_BROWSE_SLOTS.find(
                                  (s) => s.slot === a.product.slot
                                )?.slot ?? "all"
                              );
                              document
                                .getElementById(`product-${a.product.id}`)
                                ?.scrollIntoView({
                                  behavior: "smooth",
                                  block: "nearest",
                                });
                            }}
                          >
                            {a.product.name} · {a.product.priceEur} €
                          </button>
                        </li>
                      ))}
                    </ul>
                  </div>
                )}
                <div className="mt-3 flex gap-2">
                  <button
                    type="button"
                    disabled={verdict === "INCOMPATIBLE"}
                    onClick={() => addToList(p, verdict)}
                    className="flex-1 rounded-xl border border-border py-2.5 text-sm font-medium disabled:opacity-40"
                  >
                    Merken
                  </button>
                  {commerceMode === "affiliate" || !marketplaceEnabled ? (
                    <a
                      href={p.affiliateUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex flex-[2] items-center justify-center gap-2 rounded-xl bg-accent py-2.5 text-sm font-semibold text-white"
                    >
                      Beispiel-Link <ExternalLink className="h-4 w-4" />
                    </a>
                  ) : (
                    <Link
                      href="/checkout"
                      className="flex flex-[2] items-center justify-center rounded-xl bg-accent py-2.5 text-sm font-semibold text-white"
                    >
                      Zur Merkliste
                    </Link>
                  )}
                </div>
              </div>
            );
          })
        )}
      </div>

      {marketplaceEnabled && (
        <details className="rounded-2xl border border-border bg-surface p-4 text-sm">
          <summary className="cursor-pointer font-medium">
            Erweitert: Marketplace
          </summary>
          <div className="mt-3 grid grid-cols-2 gap-2">
            <button
              type="button"
              onClick={() => setCommerceMode("affiliate")}
              className={cn(
                "rounded-xl py-2 text-sm font-medium",
                commerceMode === "affiliate"
                  ? "bg-accent text-white"
                  : "bg-surface-elevated"
              )}
            >
              Beispiel-Links
            </button>
            <button
              type="button"
              onClick={() => setCommerceMode("marketplace")}
              className={cn(
                "rounded-xl py-2 text-sm font-medium",
                commerceMode === "marketplace"
                  ? "bg-accent text-white"
                  : "bg-surface-elevated"
              )}
            >
              Marketplace
            </button>
          </div>
          {commerceMode === "marketplace" && (
            <section className="mt-3 text-xs text-text-secondary">
              <h3 className="mb-2 text-sm font-semibold text-foreground">
                Pflichtangaben
              </h3>
              {!legal.configured ? (
                <p className="rounded-lg border border-warning/40 bg-warning/10 p-2 text-warning">
                  Rechtstexte nicht konfiguriert — Checkout gesperrt.
                </p>
              ) : (
                <>
                  <p>{legal.imprint}</p>
                  <p className="mt-1">
                    {legal.withdrawal}{" "}
                    <Link href="/legal/widerruf" className="text-accent">
                      Details
                    </Link>
                  </p>
                  <p className="mt-1">
                    {legal.shipping} · Warenkorb {draft.totalEur.toFixed(2)} €
                    inkl. Versand {draft.shippingEur.toFixed(2)} €
                  </p>
                  <p className="mt-1">{legal.warranty}</p>
                  <p className="mt-1">{legal.gpsr}</p>
                  <p className="mt-1">{legal.batteryNote}</p>
                  <p className="mt-1">{legal.dispute}</p>
                  <p className="mt-1">
                    <Link href="/legal/impressum" className="text-accent">
                      Impressum
                    </Link>
                    {" · "}
                    {draft.stripeNote}
                  </p>
                </>
              )}
              <label className="mt-3 flex items-start gap-2 text-sm text-foreground">
                <input
                  type="checkbox"
                  checked={legalOk}
                  onChange={(e) => setLegalOk(e.target.checked)}
                  disabled={!legal.configured}
                  className="mt-1"
                />
                Pflichtangaben gelesen (
                <Link href="/legal/widerruf" className="text-accent">
                  Widerruf
                </Link>
                , Versand, GPSR)
              </label>
              <button
                type="button"
                disabled={!legalOk || !legal.configured}
                onClick={async () => {
                  if (!legalOk || !legal.configured) return;
                  const res = await fetch("/api/checkout", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({
                      items: draft.items,
                      shippingEur: draft.shippingEur,
                      legalAccepted: legalOk,
                    }),
                  });
                  const data = await res.json();
                  if (data.url) {
                    window.location.href = data.url;
                    return;
                  }
                  alert(
                    data.error ||
                      "Checkout fehlgeschlagen (Login + Stripe Env?)"
                  );
                }}
                className={cn(
                  "mt-3 block w-full rounded-xl py-2.5 text-center text-sm font-semibold text-white",
                  legalOk && legal.configured
                    ? "bg-accent"
                    : "pointer-events-none bg-surface-elevated opacity-40"
                )}
              >
                Stripe-Checkout
              </button>
            </section>
          )}
        </details>
      )}

      </>
      ) : null}

      <p className="text-center text-xs text-text-secondary">
        Beispielkatalog — keine Live-Käufe ·{" "}
        <Link href="/checkout" className="text-accent">
          Merkliste öffnen
        </Link>
      </p>
    </div>
  );
}

export default function ShopPage() {
  return (
    <Suspense
      fallback={
        <div className="p-6 text-center text-sm text-text-secondary">
          Shop wird geladen…
        </div>
      }
    >
      <ShopPageInner />
    </Suspense>
  );
}
