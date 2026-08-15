"use client";

import { useEffect, useState } from "react";
import { Lock, Shield } from "lucide-react";
import { cn } from "@/lib/utils";

type Status = {
  storefrontApiConfigured: boolean;
  onlineStoreLocked: boolean;
  storeDomain: string;
  messageDe: string;
};

export function StoreLockedBanner({ className }: { className?: string }) {
  const [status, setStatus] = useState<Status | null>(null);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const res = await fetch("/api/shop/status", { cache: "no-store" });
        const json = (await res.json()) as Status & { ok?: boolean };
        if (!cancelled && json?.ok !== false) {
          setStatus({
            storefrontApiConfigured: Boolean(json.storefrontApiConfigured),
            onlineStoreLocked: Boolean(json.onlineStoreLocked),
            storeDomain: json.storeDomain || "",
            messageDe: json.messageDe || "",
          });
        }
      } catch {
        /* banner optional */
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  if (!status?.onlineStoreLocked) return null;

  return (
    <div
      className={cn(
        "flex gap-3 rounded-2xl border border-warning/40 bg-warning/10 px-4 py-3",
        className
      )}
      data-testid="store-locked-banner"
      role="status"
    >
      <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-warning/20 text-warning">
        <Lock className="h-5 w-5" />
      </div>
      <div className="min-w-0 flex-1">
        <p className="text-sm font-semibold text-warning">
          Inhaber-Vorschau · Online Store gesperrt
        </p>
        <p className="mt-0.5 text-xs text-text-secondary">
          {status.messageDe ||
            `${status.storeDomain} ist passwortgeschützt. Der Link führt zur Passwort-Seite — kein stiller Dead End.`}
        </p>
        <p className="mt-1 inline-flex items-center gap-1 text-[11px] text-text-secondary">
          <Shield className="h-3 w-3" />
          {status.storefrontApiConfigured
            ? "Kein In-App-Katalog. Kasse nur bei Shopify."
            : "Storefront-URL fehlt — Tür bleibt ehrlich zu."}
        </p>
      </div>
    </div>
  );
}
