"use client";

import Link from "next/link";
import { shopPartsHref } from "@/lib/shop/partsCatalog";
import { useAppStore } from "@/store/useAppStore";
import { useHofCopy } from "@/hooks/useHofCopy";

/** Werkstatt → Laden. Ruhige Zeile, kein Hero, kein Grid, kein €. */
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
  const bike = bikeId ? bikes.find((b) => b.id === bikeId) : undefined;
  const href = shopPartsHref({
    bike: bike?.id ?? bikeId ?? undefined,
    fit: "bike",
    slot: slot ?? undefined,
  });

  return (
    <p
      className={
        className ??
        "rounded-xl border border-border px-3 py-2 text-xs text-text-secondary"
      }
      data-testid="garage-parts-cta"
    >
      {!lookupOnly ? (
        <>
          <span className="font-semibold text-chrome">{copy.shopPartsForBike}</span>
          {bikeName ? ` · ${bikeName}` : ""}
          {" · "}
        </>
      ) : null}
      <Link
        href={href}
        className="font-semibold text-chrome hover:underline"
        data-testid="garage-parts-open-laden"
      >
        {copy.shopLookupInShop}
      </Link>
    </p>
  );
}
