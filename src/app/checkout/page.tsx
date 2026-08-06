"use client";

import { ArrowLeft, ExternalLink, Minus, Plus, Trash2 } from "lucide-react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { Suspense, useEffect, useMemo, useState } from "react";
import { useCartStore } from "@/store/useCartStore";
import { SHOP_PRODUCTS } from "@/lib/shop/catalog";
import { VerdictPill } from "@/components/garage/VerdictPill";
import {
  aggregateVerdict,
  checkCandidateOnBike,
} from "@/lib/compatibility/engine";
import { useAppStore } from "@/store/useAppStore";
import {
  buildMarketplaceDraft,
  MARKETPLACE_LEGAL,
} from "@/lib/shop/marketplace";
import { planStripeCheckout } from "@/lib/shop/stripeCheckout";

function CheckoutInner() {
  const params = useSearchParams();
  const items = useCartStore((s) => s.items);
  const removeItem = useCartStore((s) => s.removeItem);
  const updateQuantity = useCartStore((s) => s.updateQuantity);
  const getTotal = useCartStore((s) => s.getTotal);
  const redirects = useCartStore((s) => s.redirects);
  const recordAffiliateRedirect = useCartStore((s) => s.recordAffiliateRedirect);
  const clearCart = useCartStore((s) => s.clearCart);
  const bikes = useAppStore((s) => s.bikes);
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const commerceMode = useAppStore((s) => s.commerceMode);
  const activeBike = bikes.find((b) => b.id === activeBikeId) || bikes[0];
  const [legalOk, setLegalOk] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [demandDocumented, setDemandDocumented] = useState(false);
  const [secretConfigured, setSecretConfigured] = useState(false);
  const [stripeReturn, setStripeReturn] = useState<string | null>(null);

  useEffect(() => {
    void fetch("/api/stripe/checkout", { cache: "no-store" })
      .then((r) => r.json())
      .then((d: { demandDocumented?: boolean; secretConfigured?: boolean }) => {
        setDemandDocumented(!!d.demandDocumented);
        setSecretConfigured(!!d.secretConfigured);
      })
      .catch(() => undefined);
  }, []);

  useEffect(() => {
    const flag = params.get("stripe");
    const sessionId = params.get("session_id");
    if (flag === "cancel") {
      setStripeReturn("Checkout abgebrochen — kein Payment.");
      return;
    }
    if (flag === "success" && sessionId) {
      void fetch(`/api/stripe/session?session_id=${encodeURIComponent(sessionId)}`)
        .then((r) => r.json())
        .then(
          (d: {
            payment_status?: string;
            error?: string;
          }) => {
            if (d.payment_status === "paid") {
              setStripeReturn("Zahlung bestätigt (Stripe).");
              clearCart();
            } else if (d.payment_status) {
              setStripeReturn(
                `Stripe-Status: ${d.payment_status} — Webhook ggf. noch ausstehend.`
              );
            } else {
              setStripeReturn(
                d.error ||
                  "Zurück von Stripe — Status konnte nicht verifiziert werden."
              );
            }
          }
        )
        .catch(() =>
          setStripeReturn("Zurück von Stripe — Netzwerkfehler bei Status-Abruf.")
        );
    } else if (flag === "success") {
      setStripeReturn(
        "Zurück von Stripe — session_id fehlt (kein Fake-Success)."
      );
    }
  }, [params, clearCart]);

  const draft = useMemo(
    () =>
      buildMarketplaceDraft(
        items.map((i) => ({
          name: i.name,
          priceEur: i.price,
          qty: i.quantity,
        }))
      ),
    [items]
  );
  const stripePlan = useMemo(
    () =>
      planStripeCheckout(draft, {
        demandDocumented,
      }),
    [draft, demandDocumented]
  );

  const canStartStripe =
    commerceMode === "marketplace" &&
    legalOk &&
    items.length > 0 &&
    stripePlan.status === "session_ready" &&
    secretConfigured;

  const startStripe = async () => {
    setError(null);
    setBusy(true);
    try {
      const res = await fetch("/api/stripe/checkout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "same-origin",
        body: JSON.stringify({
          legalAccepted: legalOk,
          items: items.map((i) => ({
            name: i.name,
            priceEur: i.price,
            qty: i.quantity,
          })),
        }),
      });
      const data = (await res.json()) as { url?: string; error?: string };
      if (!res.ok || !data.url) {
        setError(data.error || `Checkout HTTP ${res.status}`);
        return;
      }
      window.location.href = data.url;
    } catch {
      setError("Netzwerkfehler beim Stripe-Checkout.");
    } finally {
      setBusy(false);
    }
  };

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
          <h1 className="text-xl font-bold">Checkout</h1>
          <p className="text-xs text-text-secondary">
            Affiliate default · Stripe Marketplace bei Nachfrage + Keys
          </p>
        </div>
      </header>

      {stripeReturn && (
        <section className="rounded-2xl border border-accent/40 bg-accent/10 p-4 text-sm">
          {stripeReturn}
        </section>
      )}

      <section className="rounded-2xl border border-border bg-surface p-4 text-sm text-text-secondary">
        Modus: <strong>{commerceMode}</strong>. Affiliate: Kauf beim Partner.
        Marketplace: Stripe Checkout nur mit{" "}
        <code className="text-[10px]">STRIPE_DEMAND_DOCUMENTED</code> +{" "}
        <code className="text-[10px]">STRIPE_SECRET_KEY</code>.
      </section>

      {commerceMode === "marketplace" && (
        <section className="rounded-2xl border border-warning/40 bg-warning/10 p-4 text-sm">
          <h2 className="font-semibold text-foreground">Stripe Marketplace</h2>
          <p className="mt-1 text-xs text-warning">{stripePlan.messageDe}</p>
          <p className="mt-2 text-xs tabular-nums">
            Waren {getTotal().toFixed(2)} € + Versand {draft.shippingEur.toFixed(2)}{" "}
            € = <strong>{draft.totalEur.toFixed(2)} €</strong>
          </p>
          <ul className="mt-2 list-inside list-disc text-[11px] text-text-secondary">
            <li>{MARKETPLACE_LEGAL.withdrawal}</li>
            <li>{MARKETPLACE_LEGAL.shipping}</li>
            <li>{MARKETPLACE_LEGAL.gpsr}</li>
          </ul>
          <label className="mt-2 flex items-center gap-2 text-xs">
            <input
              type="checkbox"
              checked={legalOk}
              onChange={(e) => setLegalOk(e.target.checked)}
            />
            EU-Pflichtangaben gelesen
          </label>
          {error && <p className="mt-2 text-xs text-error">{error}</p>}
          <button
            type="button"
            disabled={!canStartStripe || busy}
            onClick={() => void startStripe()}
            className="mt-2 w-full rounded-xl bg-accent py-2 text-xs font-semibold text-white disabled:bg-muted disabled:opacity-60"
          >
            {busy
              ? "…"
              : canStartStripe
                ? "Mit Stripe bezahlen"
                : `Stripe nicht verfügbar (${stripePlan.status})`}
          </button>
        </section>
      )}

      <section>
        <h2 className="mb-2 font-semibold">Merkliste / Warenkorb</h2>
        {items.length === 0 ? (
          <p className="text-sm text-text-secondary">
            Leer — im Shop „Merken“, dann hier zum Partner oder Stripe.
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
              Summe: {getTotal().toFixed(0)} €
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

export default function CheckoutPage() {
  return (
    <Suspense fallback={<div className="p-6 text-center">Lade…</div>}>
      <CheckoutInner />
    </Suspense>
  );
}
