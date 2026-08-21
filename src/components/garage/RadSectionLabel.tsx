import type { ReactNode } from "react";
import { RadGlyph } from "@/components/garage/RadGlyph";
import type { RadMarkName } from "@/lib/garage/radMark";

export function RadSectionLabel({
  mark,
  children,
}: {
  mark: RadMarkName;
  children: ReactNode;
}) {
  return (
    <h3 className="mb-2 flex items-center gap-2 text-[11px] font-bold tracking-wide text-text-secondary">
      <RadGlyph name={mark} size={16} />
      <span>{children}</span>
    </h3>
  );
}
