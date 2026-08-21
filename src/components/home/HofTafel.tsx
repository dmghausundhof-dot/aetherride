"use client";

import Link from "next/link";
import { useHofCopy } from "@/hooks/useHofCopy";
import type { TafelItem } from "@/lib/tours/tourAkte";

/** Zwei Zeilen-Typen: Pflege → Rad, Mappe/Stimmen → Tour. Kein Hybrid. */
export function HofTafel({ items }: { items: TafelItem[] }) {
  const copy = useHofCopy();

  const care = items.filter((i) => i.kind === "care");
  const tour = items.filter(
    (i) =>
      i.kind === "stimmen" ||
      i.kind === "mappe" ||
      i.kind === "gruppe" ||
      i.kind === "listing"
  );
  if (care.length === 0 && tour.length === 0) return null;

  return (
    <section className="mb-4 space-y-3">
      {care.length > 0 ? (
        <div className="rounded-2xl border border-border p-3">
          <p className="text-[11px] font-bold tracking-wide text-text-secondary">
            {copy.workshopTitle}
          </p>
          <ul className="mt-2 space-y-1.5">
            {care.map((item) => (
              <li key={item.id}>
                <Link
                  href={item.href}
                  className="block text-[13px] font-semibold text-warning hover:text-chrome"
                >
                  {item.text}
                </Link>
              </li>
            ))}
          </ul>
        </div>
      ) : null}
      {tour.length > 0 ? (
        <div className="rounded-2xl border border-border p-3">
          <p className="text-[11px] font-bold tracking-wide text-text-secondary">
            {copy.tafelKicker}
          </p>
          <p className="mt-0.5 text-[11px] text-text-secondary">
            {copy.tafelHint}
          </p>
          <ul className="mt-2 space-y-1.5">
            {tour.map((item) => (
              <li key={item.id}>
                <Link
                  href={item.href}
                  className="block text-[13px] font-semibold text-foreground hover:text-chrome"
                >
                  {item.text}
                </Link>
              </li>
            ))}
          </ul>
        </div>
      ) : null}
    </section>
  );
}
