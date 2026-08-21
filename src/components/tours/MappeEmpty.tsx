"use client";

import type { ReactNode } from "react";
import { MappeGlyph } from "@/components/tours/MappeGlyph";

export function MappeEmpty({
  title,
  hint,
  compact = false,
  actions,
}: {
  title: string;
  hint: string;
  compact?: boolean;
  actions?: ReactNode;
}) {
  return (
    <div className="overflow-hidden rounded-2xl border border-dashed border-border bg-surface text-center">
      <img
        src="/tours/empty-mappe.svg"
        alt=""
        width={240}
        height={140}
        className={`mx-auto h-auto ${compact ? "mt-2 w-[min(100%,180px)]" : "mt-4 w-[min(100%,240px)]"}`}
        draggable={false}
      />
      <div className={compact ? "px-4 pb-4 pt-2" : "px-6 pb-8 pt-3"}>
        <p className="flex items-center justify-center gap-2 text-base font-extrabold">
          <MappeGlyph name="mappe" size={18} />
          {title}
        </p>
        <p className="mx-auto mt-2 max-w-md text-sm text-text-secondary">{hint}</p>
        {actions ? (
          <div className="mt-4 flex flex-wrap items-center justify-center gap-2">
            {actions}
          </div>
        ) : null}
      </div>
    </div>
  );
}
