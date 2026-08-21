"use client";

import { useState } from "react";
import { RadGlyph } from "@/components/garage/RadGlyph";
import { RadNavMark } from "@/components/garage/RadNavMark";
import type { ShopProduct } from "@/lib/shop/catalog";
import type { RadMarkName } from "@/lib/garage/radMark";
import { cn } from "@/lib/utils";

const HINT_STYLES: Record<string, string> = {
  chain: "from-amber-900/50 to-amber-700/20 text-amber-200",
  pads: "from-rose-900/50 to-rose-700/20 text-rose-200",
  fork: "from-sky-900/50 to-sky-700/20 text-sky-200",
  tire: "from-stone-800/60 to-stone-600/20 text-stone-200",
  cassette: "from-zinc-800/60 to-zinc-600/20 text-zinc-200",
  shock: "from-stone-800/50 to-stone-700/20 text-stone-200",
  battery: "from-emerald-900/50 to-emerald-700/20 text-emerald-200",
  dropper: "from-teal-900/50 to-teal-700/20 text-teal-200",
  bike: "from-indigo-900/50 to-indigo-700/20 text-indigo-200",
  tape: "from-violet-900/50 to-violet-700/20 text-violet-200",
};

const HINT_MARK: Record<string, RadMarkName> = {
  chain: "chain",
  pads: "brakes",
  fork: "travel",
  tire: "pressure",
  cassette: "parts",
  shock: "sag",
  battery: "battery",
  dropper: "travel",
  tape: "cockpit",
};

function HintIcon({ hint }: { hint: string }) {
  if (hint === "bike") return <RadNavMark className="h-7 w-7" />;
  const name = HINT_MARK[hint] ?? "parts";
  return <RadGlyph name={name} size={28} />;
}

export function ProductVisual({
  product,
  className,
  compact,
}: {
  product: ShopProduct;
  className?: string;
  compact?: boolean;
}) {
  const sizeCls = compact ? "h-12 w-12" : "h-16 w-16";
  const [imgBroken, setImgBroken] = useState(false);

  const style =
    HINT_STYLES[product.visualHint] ??
    "from-surface-elevated to-surface text-text-secondary";

  const fallback = (
    <div
      className={cn(
        "flex shrink-0 items-center justify-center rounded-xl bg-gradient-to-br",
        style,
        sizeCls,
        className
      )}
      aria-hidden
    >
      <HintIcon hint={product.visualHint} />
    </div>
  );

  // Audit: skip broken CDN URLs — fall back to visualHint icon
  if (product.imageUrl && !imgBroken) {
    return (
      // eslint-disable-next-line @next/next/no-img-element -- Shopify CDN; no next/image domain allowlist in Phase A
      <img
        src={product.imageUrl}
        alt=""
        className={cn(
          "shrink-0 rounded-xl object-cover",
          sizeCls,
          className
        )}
        aria-hidden
        onError={() => setImgBroken(true)}
      />
    );
  }

  return fallback;
}
