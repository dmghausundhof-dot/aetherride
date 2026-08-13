"use client";

import {
  BIKE_OVERLAY_LEGEND_DE,
  overlayClassesForFamily,
  type BikeOverlayClass,
  type BikeOverlayFamily,
} from "@/lib/routing/bikeOverlayClass";

export function BikeOverlayLegend({
  family,
  visible,
  extraOn,
  onToggleVisible,
  onToggleClass,
}: {
  family: BikeOverlayFamily;
  visible: boolean;
  extraOn: BikeOverlayClass[];
  onToggleVisible: () => void;
  onToggleClass: (cls: BikeOverlayClass) => void;
}) {
  const primary = new Set(overlayClassesForFamily(family));
  return (
    <div className="rounded-xl bg-black/70 px-2.5 py-2 text-[10px] text-white shadow-lg">
      <button
        type="button"
        className="mb-1.5 flex w-full items-center justify-between gap-2 font-semibold uppercase tracking-wide text-white/90"
        onClick={onToggleVisible}
      >
        <span>Wege · OSM</span>
        <span className="normal-case font-normal text-white/70">
          {visible ? "an" : "aus"}
        </span>
      </button>
      <ul className="flex flex-col gap-1">
        {BIKE_OVERLAY_LEGEND_DE.map((row) => {
          const on =
            visible &&
            (primary.has(row.bikeClass) || extraOn.includes(row.bikeClass));
          return (
            <li key={row.key}>
              <button
                type="button"
                className={`flex w-full items-center gap-1.5 text-left ${
                  on ? "opacity-100" : "opacity-40"
                }`}
                onClick={() => onToggleClass(row.bikeClass)}
              >
                <span
                  className="inline-block h-0.5 w-3.5 rounded-full"
                  style={{ background: row.color }}
                />
                <span>{row.label}</span>
              </button>
            </li>
          );
        })}
      </ul>
      <p className="mt-1.5 max-w-[11rem] text-[9px] leading-snug text-white/55">
        S0–S3 nur bei OSM-Tag. Sonst unbewertet — keine Trailforks-Geometrie.
      </p>
    </div>
  );
}
