import { cn } from "@/lib/utils";

type Confidence = "low" | "medium" | "high";

const LABEL: Record<Confidence, string> = {
  low: "niedrig",
  medium: "mittel",
  high: "hoch",
};

/**
 * F-AI-003 ConfidenceBadge für Setup-Empfehlungen.
 */
export function ConfidenceBadge({
  confidence,
  className,
}: {
  confidence: Confidence;
  className?: string;
}) {
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide",
        confidence === "high" && "bg-success/15 text-success",
        confidence === "medium" && "bg-warning/15 text-warning",
        confidence === "low" && "bg-surface-elevated text-text-secondary",
        className
      )}
    >
      Konfidenz {LABEL[confidence]}
    </span>
  );
}
