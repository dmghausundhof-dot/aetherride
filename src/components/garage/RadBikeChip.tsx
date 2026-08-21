"use client";

import { bikeCategoryLabel } from "@/lib/catalog/slots";
import { garageTabCopy } from "@/lib/i18n/garageTabCopy";
import { useChromeLang } from "@/hooks/useChromeLang";
import { RadStandFrame } from "@/components/garage/RadStandFrame";
import { radSilhouetteSrc } from "@/lib/garage/radMark";
import type { Bike } from "@/types";

export function RadBikeChip({
  bike,
  selected,
  onSelect,
}: {
  bike: Bike;
  selected: boolean;
  onSelect: () => void;
}) {
  const src = bike.photoUrl || radSilhouetteSrc(bike);
  const lang = useChromeLang();
  const tab = garageTabCopy(lang);

  return (
    <button
      type="button"
      onClick={onSelect}
      className={`min-w-[7.5rem] flex-shrink-0 overflow-hidden rounded-xl border text-left transition lg:min-w-0 lg:w-full ${
        selected
          ? "border-chrome bg-chrome/10"
          : "border-border bg-surface hover:border-chrome/30"
      }`}
    >
      <RadStandFrame
        src={src}
        alt=""
        photo={Boolean(bike.photoUrl)}
        heightClass="h-12 lg:h-16"
      />
      <div className="px-2.5 py-1.5 lg:px-3 lg:py-2">
        <div className="truncate text-sm font-medium">{bike.name}</div>
        <div className="truncate text-[11px] text-text-secondary">
          {bikeCategoryLabel(bike.category, lang)}
          {bike.isActive ? ` · ${tab.active}` : ""}
        </div>
      </div>
    </button>
  );
}
