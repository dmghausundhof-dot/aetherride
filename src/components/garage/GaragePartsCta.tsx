"use client";

import Link from "next/link";
import { RadGlyph } from "@/components/garage/RadGlyph";
import { shopPartsHref } from "@/lib/shop/partsCatalog";
import { isShopEnabled } from "@/lib/shop/shopEnabled";
import { useAppStore } from "@/store/useAppStore";
import { useHofCopy } from "@/hooks/useHofCopy";
import { cn } from "@/lib/utils";

/** Rad → Laden. Ruhige Zeile, kein Banner, kein Grid, kein Preis. */
export function GaragePartsCta({
  bikeId,
  bikeName,
  slot,
  lookupOnly = false,
  className,
}: {
  bikeId?: string | null;
  bikeName?: string | null;
  slot?: string | null;
  lookupOnly?: boolean;
  className?: string;
}) {
  const copy = useHofCopy();
  const bikes = useAppStore((s) => s.bikes);
  if (!isShopEnabled()) return null;

  const bike = bikeId ? bikes.find((b) => b.id === bikeId) : undefined;
  const href = shopPartsHref({
    bike: bike?.id ?? bikeId ?? undefined,
    fit: "bike",
    slot: slot ?? undefined,
  });
  const title = lookupOnly ? copy.shopLookupInShop : copy.shopPartsForBike;

  return (
    <Link
      href={href}
      className={cn(
        "flex items-center gap-3 rounded-xl border border-border px-3 py-2 text-xs hover:border-chrome/40",
        className,
      )}
      data-testid={lookupOnly ? "garage-parts-lookup" : "garage-parts-cta"}
    >
      <RadGlyph name="parts" size={16} className="shrink-0" />
      <span className="min-w-0 flex-1">
        <span className="font-semibold text-chrome">{title}</span>
        {!lookupOnly && bikeName ? (
          <span className="font-semibold text-text-secondary">
            {" "}
            · {bikeName}
          </span>
        ) : null}
      </span>
      <RadGlyph name="stand" size={16} className="shrink-0 opacity-70" />
    </Link>
  );
}
