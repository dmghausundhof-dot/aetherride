"use client";

import { useEffect, useState } from "react";
import { ChromeGlyph } from "@/components/chrome/ChromeGlyph";
import { cn } from "@/lib/utils";
import { useHofCopy } from "@/hooks/useHofCopy";

type Status = {
  storefrontApiConfigured: boolean;
  onlineStoreLocked: boolean;
  shopifyCommerceEnabled?: boolean;
};

export function StoreLockedBanner({ className }: { className?: string }) {
  const copy = useHofCopy();
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
            shopifyCommerceEnabled: json.shopifyCommerceEnabled === true,
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

  if (!status?.shopifyCommerceEnabled) return null;
  if (!status.onlineStoreLocked) return null;

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
        <ChromeGlyph name="lock" size={20} current />
      </div>
      <div className="min-w-0 flex-1">
        <p className="text-sm font-semibold text-warning">
          {copy.shopLockedBanner}
        </p>
        <p className="mt-0.5 text-xs text-text-secondary">
          {copy.shopLockedBody}
        </p>
        <p className="mt-1 inline-flex items-center gap-1 text-[11px] text-text-secondary">
          <ChromeGlyph name="shield" size={12} current />
          {status.storefrontApiConfigured
            ? copy.shopLockedCatalog
            : copy.shopLockedMissingUrl}
        </p>
      </div>
    </div>
  );
}
