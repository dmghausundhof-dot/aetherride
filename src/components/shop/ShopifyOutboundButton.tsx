"use client";

import { useEffect, useState } from "react";
import { ExternalLink, Lock } from "lucide-react";
import { cn } from "@/lib/utils";

/**
 * External myshopify link — never a silent password dead-end.
 * When Online Store is locked, opens an explicit Owner-Preview dialog.
 */
export function ShopifyOutboundButton({
  href,
  label = "Externer Shopify-Link",
  className,
  variant = "secondary",
}: {
  href: string;
  label?: string;
  className?: string;
  variant?: "primary" | "secondary" | "ghost";
}) {
  const [locked, setLocked] = useState(true);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const res = await fetch("/api/shop/status", { cache: "no-store" });
        const json = (await res.json()) as { onlineStoreLocked?: boolean };
        if (!cancelled) setLocked(json.onlineStoreLocked !== false);
      } catch {
        if (!cancelled) setLocked(true);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const base =
    variant === "primary"
      ? "bg-primary text-white"
      : variant === "ghost"
        ? "border border-border bg-transparent text-text-secondary"
        : "border border-border bg-surface-elevated text-foreground";

  if (!locked) {
    return (
      <a
        href={href}
        target="_blank"
        rel="noopener noreferrer"
        className={cn(
          "inline-flex w-full items-center justify-center gap-1.5 rounded-xl py-2.5 text-sm font-semibold",
          base,
          className
        )}
      >
        {label} <ExternalLink className="h-3.5 w-3.5" />
      </a>
    );
  }

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        className={cn(
          "inline-flex w-full items-center justify-center gap-1.5 rounded-xl py-2.5 text-sm font-semibold",
          base,
          className
        )}
      >
        <Lock className="h-3.5 w-3.5" />
        {label}
      </button>
      {open ? (
        <div
          className="fixed inset-0 z-50 flex items-end justify-center bg-black/60 p-4 sm:items-center"
          role="dialog"
          aria-modal="true"
          aria-labelledby="store-locked-title"
          onClick={() => setOpen(false)}
        >
          <div
            className="w-full max-w-md rounded-2xl border border-border bg-surface p-5 shadow-xl"
            onClick={(e) => e.stopPropagation()}
          >
            <h2 id="store-locked-title" className="text-lg font-bold">
              Online Store gesperrt
            </h2>
            <p className="mt-2 text-sm text-text-secondary">
              Der Shopify Online Store ist passwortgeschützt (Owner Preview).
              Der Link führt zur Passwort-Seite — kein stiller Dead End, aber
              kein öffentlicher Checkout.
            </p>
            <p className="mt-2 text-xs text-text-secondary">
              Produktkatalog nutze in AetherRide (Storefront API). Store-Passwort
              wird nicht in der App ausgeliefert.
            </p>
            <div className="mt-4 flex flex-col gap-2 sm:flex-row">
              <a
                href={href}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex flex-1 items-center justify-center gap-1.5 rounded-xl bg-warning py-2.5 text-sm font-semibold text-black"
              >
                Trotzdem öffnen (Passwort-Seite)
                <ExternalLink className="h-3.5 w-3.5" />
              </a>
              <button
                type="button"
                onClick={() => setOpen(false)}
                className="flex-1 rounded-xl border border-border py-2.5 text-sm font-medium"
              >
                Zurück
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </>
  );
}
