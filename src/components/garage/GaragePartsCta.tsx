import Link from "next/link";
import { ShoppingBag, ChevronRight } from "lucide-react";
import { shopPartsHref } from "@/lib/shop/partsCatalog";

/** Garage CTA → Parts with bike soft-fit context (skip-friendly without bike). */
export function GaragePartsCta({
  bikeId,
  bikeName,
  className,
}: {
  bikeId?: string | null;
  bikeName?: string | null;
  className?: string;
}) {
  const href = bikeId
    ? shopPartsHref({ bike: bikeId, fit: "bike" })
    : shopPartsHref();

  return (
    <Link
      href={href}
      className={
        className ??
        "group flex items-center gap-3 rounded-2xl border border-accent/40 bg-accent/10 p-4 transition hover:border-accent/70"
      }
      data-testid="garage-parts-cta"
    >
      <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-accent/20 text-accent">
        <ShoppingBag className="h-5 w-5" />
      </div>
      <div className="min-w-0 flex-1">
        <div className="font-semibold text-accent">
          {bikeId ? "Passt zu deinem Bike" : "Ersatzteile entdecken"}
        </div>
        <p className="mt-0.5 text-xs text-text-secondary">
          {bikeId
            ? `Soft-Fit für ${bikeName ?? "dein Rad"} — Beläge, Griffe, Fluid & mehr.`
            : "Collection featured-parts — ohne Bike einfach stöbern."}
        </p>
      </div>
      <ChevronRight className="h-5 w-5 shrink-0 text-accent transition group-hover:translate-x-0.5" />
    </Link>
  );
}
