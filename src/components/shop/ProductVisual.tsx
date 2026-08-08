import {
  Battery,
  CircleDot,
  Disc,
  Link2,
  Mountain,
  MoveVertical,
  Cog,
} from "lucide-react";
import type { ShopProduct } from "@/lib/shop/catalog";
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
};

function HintIcon({ hint }: { hint: string }) {
  const cls = "h-7 w-7";
  switch (hint) {
    case "chain":
      return <Link2 className={cls} />;
    case "pads":
      return <Disc className={cls} />;
    case "fork":
      return <Mountain className={cls} />;
    case "tire":
      return <CircleDot className={cls} />;
    case "cassette":
      return <Cog className={cls} />;
    case "shock":
      return <MoveVertical className={cls} />;
    case "battery":
      return <Battery className={cls} />;
    case "dropper":
      return <MoveVertical className={cls} />;
    default:
      return <CircleDot className={cls} />;
  }
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
  const style =
    HINT_STYLES[product.visualHint] ??
    "from-surface-elevated to-surface text-text-secondary";

  return (
    <div
      className={cn(
        "flex shrink-0 items-center justify-center rounded-xl bg-gradient-to-br",
        style,
        compact ? "h-12 w-12" : "h-16 w-16",
        className
      )}
      aria-hidden
    >
      <HintIcon hint={product.visualHint} />
    </div>
  );
}
