"use client";

import type { ReactNode } from "react";
import { MappeGlyph, type MappeGlyphName } from "@/components/tours/MappeGlyph";

export function MappeSectionLabel({
  glyph,
  children,
}: {
  glyph: MappeGlyphName;
  children: ReactNode;
}) {
  return (
    <h2 className="mb-3 flex items-center gap-2 text-sm font-semibold tracking-wide text-text-secondary">
      <MappeGlyph name={glyph} size={18} />
      <span>{children}</span>
    </h2>
  );
}
