import { cn } from "@/lib/utils";
import {
  verdictColorClass,
  verdictLabel,
} from "@/lib/compatibility/engine";
import type { CompatibilityVerdict } from "@/types";

export function VerdictPill({
  verdict,
  className,
}: {
  verdict: CompatibilityVerdict;
  className?: string;
}) {
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-md border px-2 py-0.5 text-xs font-semibold",
        verdictColorClass(verdict),
        className
      )}
    >
      {verdictLabel(verdict)}
    </span>
  );
}
