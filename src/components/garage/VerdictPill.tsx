import { cn } from "@/lib/utils";
import { verdictColorClass } from "@/lib/compatibility/engine";
import { compatVerdictLabel } from "@/lib/i18n/compatCopy";
import { useChromeLang } from "@/hooks/useChromeLang";
import type { CompatibilityVerdict } from "@/types";

export function VerdictPill({
  verdict,
  className,
}: {
  verdict: CompatibilityVerdict;
  className?: string;
}) {
  const lang = useChromeLang();
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-md border px-2 py-0.5 text-xs font-semibold",
        verdictColorClass(verdict),
        className
      )}
    >
      {compatVerdictLabel(verdict, lang)}
    </span>
  );
}
