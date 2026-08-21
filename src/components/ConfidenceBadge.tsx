"use client";

import { cn } from "@/lib/utils";
import { useChromeLang } from "@/hooks/useChromeLang";
import { recapChromeCopy } from "@/lib/i18n/recapChromeCopy";

type Confidence = "low" | "medium" | "high";

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
  const copy = recapChromeCopy(useChromeLang());
  const level =
    confidence === "high"
      ? copy.confHigh
      : confidence === "medium"
        ? copy.confMedium
        : copy.confLow;
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
      {copy.confPrefix} {level}
    </span>
  );
}
