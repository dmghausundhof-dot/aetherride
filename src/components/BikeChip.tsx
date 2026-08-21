"use client";

import Link from "next/link";
import { RadNavMark } from "@/components/garage/RadNavMark";
import { useHofCopy } from "@/hooks/useHofCopy";
import { useChromeLang } from "@/hooks/useChromeLang";
import { useAppStore } from "@/store/useAppStore";
import { bikeCategoryLabel } from "@/lib/catalog/slots";
import { garageTabCopy } from "@/lib/i18n/garageTabCopy";

/** Aktives Rad — Spec: auf Kernflächen sichtbar */
export function BikeChip({
  href = "/garage",
  className = "",
}: {
  href?: string;
  className?: string;
}) {
  const copy = useHofCopy();
  const lang = useChromeLang();
  const tab = garageTabCopy(lang);
  const bikes = useAppStore((s) => s.bikes);
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const bike = bikes.find((b) => b.id === activeBikeId) || bikes[0];

  if (!bike) {
    return (
      <Link
        href="/garage?wizard=basic"
        className={`inline-flex max-w-full items-center gap-1.5 rounded-full border border-border bg-surface-elevated px-2.5 py-1 text-xs font-medium text-accent ${className}`}
      >
        <RadNavMark className="h-3.5 w-3.5 shrink-0" />
        <span className="truncate">{copy.parkBike}</span>
      </Link>
    );
  }

  return (
    <Link
      href={href}
      className={`inline-flex max-w-full items-center gap-1.5 rounded-full border border-accent/30 bg-accent/10 px-2.5 py-1 text-xs font-medium text-accent ${className}`}
      aria-label={tab.activeAria(bike.name)}
    >
      <RadNavMark className="h-3.5 w-3.5 shrink-0" />
      <span className="truncate">{bike.name}</span>
      <span className="shrink-0 text-[10px] text-text-secondary">
        {bikeCategoryLabel(bike.category, lang)}
      </span>
    </Link>
  );
}
