import Link from "next/link";
import { ChevronRight } from "lucide-react";
import { cn } from "@/lib/utils";
import type { RankedPartsProduct } from "@/lib/shop/partsCatalog";
import { inAppProductHref } from "@/lib/shop/storeStatus";
import { ShopifyOutboundButton } from "@/components/shop/ShopifyOutboundButton";

function formatPrice(eur: number, currency: string): string {
  try {
    return new Intl.NumberFormat("de-DE", {
      style: "currency",
      currency: currency || "EUR",
    }).format(eur);
  } catch {
    return `${eur.toLocaleString("de-DE")} €`;
  }
}

export function PartsProductCard({
  row,
  focused,
}: {
  row: RankedPartsProduct;
  focused?: boolean;
}) {
  const { product: p, verdict, chip } = row;
  const chipTone =
    verdict === "passt"
      ? "bg-success/15 text-success border-success/30"
      : verdict === "pruefen"
        ? "bg-warning/15 text-warning border-warning/30"
        : "bg-surface-elevated text-text-secondary border-border";
  const detailHref = inAppProductHref(p.handle);

  return (
    <article
      id={`part-${p.handle}`}
      className={cn(
        "group flex flex-col overflow-hidden rounded-2xl border bg-surface transition hover:border-accent/40",
        focused ? "border-accent ring-1 ring-accent/40" : "border-border"
      )}
    >
      <Link href={detailHref} className="relative block aspect-[4/3] bg-surface-elevated">
        {p.imageUrl ? (
          // eslint-disable-next-line @next/next/no-img-element -- Shopify CDN
          <img
            src={p.imageUrl}
            alt={p.imageAlt || p.name}
            className="h-full w-full object-cover transition duration-300 group-hover:scale-[1.02]"
            loading="lazy"
          />
        ) : (
          <div className="flex h-full w-full items-center justify-center text-sm text-text-secondary">
            Kein Bild
          </div>
        )}
        <span
          className={cn(
            "absolute left-2 top-2 rounded-full border px-2 py-0.5 text-[11px] font-semibold capitalize backdrop-blur-sm",
            chipTone
          )}
        >
          {chip}
        </span>
      </Link>
      <div className="flex flex-1 flex-col gap-2 p-4">
        <div className="text-[11px] font-medium uppercase tracking-wide text-text-secondary">
          {p.manufacturer}
        </div>
        <Link href={detailHref}>
          <h3 className="font-semibold leading-snug hover:text-accent">{p.name}</h3>
        </Link>
        <div className="text-lg font-bold tabular-nums text-accent">
          {formatPrice(p.priceEur, p.currencyCode)}
        </div>
        {p.description ? (
          <p className="line-clamp-2 text-xs text-text-secondary">
            {p.description}
          </p>
        ) : null}
        <Link
          href={detailHref}
          className="mt-auto inline-flex w-full items-center justify-center gap-1.5 rounded-xl bg-accent py-2.5 text-sm font-semibold text-white"
        >
          Details <ChevronRight className="h-4 w-4" />
        </Link>
        <ShopifyOutboundButton
          href={p.affiliateUrl}
          label="Shopify (extern)"
          variant="ghost"
          className="py-2 text-xs font-medium"
        />
      </div>
    </article>
  );
}
