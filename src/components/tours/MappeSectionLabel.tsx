"use client";

import type { ReactNode } from "react";
import { MappeGlyph, type MappeGlyphName } from "@/components/tours/MappeGlyph";

export function MappeSectionLabel({
  glyph,
  children,
  count,
  expanded,
  onToggle,
}: {
  glyph: MappeGlyphName;
  children: ReactNode;
  count?: number;
  expanded?: boolean;
  onToggle?: () => void;
}) {
  const label = (
    <>
      <MappeGlyph name={glyph} size={18} />
      <span>
        {children}
        {count != null ? ` · ${count}` : ""}
      </span>
    </>
  );
  if (!onToggle) {
    return (
      <h2 className="mb-3 flex items-center gap-2 text-sm font-semibold tracking-wide text-text-secondary">
        {label}
      </h2>
    );
  }
  return (
    <h2 className="mb-3">
      <button
        type="button"
        onClick={onToggle}
        aria-expanded={expanded}
        className="flex w-full items-center gap-2 text-left text-sm font-semibold tracking-wide text-text-secondary"
      >
        {label}
        <span className="ml-auto text-xs" aria-hidden>
          {expanded ? "▴" : "▾"}
        </span>
      </button>
    </h2>
  );
}
