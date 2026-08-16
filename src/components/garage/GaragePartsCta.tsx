"use client";

import Link from "next/link";
import { shopPartsHref } from "@/lib/shop/partsCatalog";
import { useAppStore } from "@/store/useAppStore";
import { useHofCopy } from "@/hooks/useHofCopy";

/** Werkstatt → Laden. Textzeile, kein zweiter Primärknopf. */
export function GaragePartsCta({
  bikeId,
  bikeName,
  className,
}: {
  bikeId?: string | null;
  bikeName?: string | null;
  className?: string;
}) {
  const copy = useHofCopy();

  const bikes = useAppStore((s) => s.bikes);
  const bike = bikeId ? bikes.find((b) => b.id === bikeId) : undefined;
  const href = shopPartsHref({
    bike: bike?.id ?? bikeId ?? undefined,
    fit: "bike",
  });

  return (
    <p
      className={className ?? "text-xs text-text-secondary"}
      data-testid="garage-parts-cta"
    >
      <Link
        href={href}
        className="font-semibold text-chrome hover:underline"
        data-testid="garage-parts-open-laden"
      >
        {copy.shopForYourBike}
      </Link>
      {bikeName ? ` · ${bikeName}` : ""}
    </p>
  );
}
