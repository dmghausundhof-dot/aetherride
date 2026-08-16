"use client";

import { useEffect, useState } from "react";
import { ExternalLink, Lock } from "lucide-react";
import { cn } from "@/lib/utils";
import { useChromeLang } from "@/hooks/useChromeLang";
import { useHofCopy } from "@/hooks/useHofCopy";
import { withShopifyLocale } from "@/lib/shop/shopifyLocale";
import { isShopifyOnlineStoreUrl } from "@/lib/shop/storeStatus";

/**
 * External myshopify link — never a silent password dead-end.
 * When Online Store is locked, opens an explicit Owner-Preview dialog.
 */
export function ShopifyOutboundButton({
  href,
  label,
  className,
  variant = "secondary",
}: {
  href: string;
  label?: string;
  className?: string;
  variant?: "primary" | "secondary" | "ghost";
}) {
  const copy = useHofCopy();
  const lang = useChromeLang();
  const hrefOut = withShopifyLocale(href, lang);
  const shown = label ?? copy.shopExternalLink;
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

  const needsOwnerPreview = locked && isShopifyOnlineStoreUrl(hrefOut);

  const base =
    variant === "primary"
      ? "bg-chrome text-on-accent"
      : variant === "ghost"
        ? "border border-border bg-transparent text-text-secondary"
        : "border border-border bg-surface-elevated text-foreground";

  if (!needsOwnerPreview) {
    return (
      <a
        href={hrefOut}
        target="_blank"
        rel="noopener noreferrer"
        className={cn(
          "inline-flex w-full items-center justify-center gap-1.5 rounded-xl py-2.5 text-sm font-semibold",
          base,
          className
        )}
      >
        {shown} <ExternalLink className="h-3.5 w-3.5" />
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
        {shown}
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
              {copy.shopLockedTitle}
            </h2>
            <p className="mt-2 text-sm text-text-secondary">
              {copy.shopLockedBody}
            </p>
            <p className="mt-2 text-xs text-text-secondary">
              {copy.shopLockedPasswordNote}
            </p>
            <div className="mt-4 flex flex-col gap-2 sm:flex-row">
              <a
                href={hrefOut}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex flex-1 items-center justify-center gap-1.5 rounded-xl bg-warning py-2.5 text-sm font-semibold text-black"
              >
                {copy.shopLockedOpen}
                <ExternalLink className="h-3.5 w-3.5" />
              </a>
              <button
                type="button"
                onClick={() => setOpen(false)}
                className="flex-1 rounded-xl border border-border py-2.5 text-sm font-medium"
              >
                {copy.shopCancel}
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </>
  );
}
