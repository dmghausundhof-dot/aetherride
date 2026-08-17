"use client";

import { useChromeLang } from "@/hooks/useChromeLang";
import { overlayCopy, overlayLegendLabel } from "@/lib/i18n/overlayCopy";
import {
  BIKE_OVERLAY_LEGEND_DE,
  BIKE_OVERLAY_SURFACE_LEGEND,
  overlayClassesForFamily,
  type BikeOverlayClass,
  type BikeOverlayFamily,
} from "@/lib/routing/bikeOverlayClass";
import { overlayClassesOn } from "@/lib/routing/bikeOverlayMap";
import {
  getProfile,
  overlayScaleLabels,
  prefersUnratedTrails,
  type RideProfileId,
} from "@/lib/routing/profiles";
import { KARTEN_PAGE } from "@/lib/content/kartenCopy";

export function OverlayWaysHint() {
  return (
    <div className="max-w-[12rem] rounded-xl bg-black/70 px-2.5 py-2 text-[10px] leading-snug text-white/80 shadow-lg">
      {KARTEN_PAGE.waysHint}
    </div>
  );
}

export function BikeOverlayLegend({
  family,
  visible,
  extraOn,
  rideProfileId = null,
  hasOverlayData = true,
  overlayKind = "ways",
  onToggleVisible,
  onToggleClass,
}: {
  family: BikeOverlayFamily;
  visible: boolean;
  extraOn: BikeOverlayClass[];
  rideProfileId?: RideProfileId | null;
  hasOverlayData?: boolean;
  overlayKind?: "ways" | "mesh";
  onToggleVisible: () => void;
  onToggleClass: (cls: BikeOverlayClass) => void;
}) {
  const lang = useChromeLang();
  const o = overlayCopy(lang);
  if (!hasOverlayData) return <OverlayWaysHint />;
  const mesh = overlayKind === "mesh";
  const primary = new Set(overlayClassesForFamily(family));
  const profileOn = rideProfileId
    ? overlayClassesOn({
        family,
        visible: true,
        extraOn,
        rideProfileId,
      })
    : null;
  const scaleOn = rideProfileId ? overlayScaleLabels(rideProfileId) : null;
  const ride = rideProfileId ? getProfile(rideProfileId) : null;

  return (
    <div className="rounded-xl bg-black/70 px-2.5 py-2 text-[10px] text-white shadow-lg">
      <button
        type="button"
        className="mb-1.5 flex w-full items-center justify-between gap-2 font-semibold uppercase tracking-wide text-white/90"
        onClick={onToggleVisible}
      >
        <span>{mesh ? o.meshOsm : o.waysOsm}</span>
        <span className="normal-case font-normal text-white/70">
          {visible ? o.on : o.off}
        </span>
      </button>
      {ride && !mesh && (
        <p className="mb-1 text-[9px] font-medium text-white/80">
          {ride.shortLabel}
          {scaleOn && scaleOn.length > 0 ? ` · ${scaleOn.join("–")}` : ""}
        </p>
      )}
      {!mesh && (
      <ul className="flex flex-col gap-1">
        {BIKE_OVERLAY_LEGEND_DE.map((row) => {
          let on =
            visible &&
            (primary.has(row.bikeClass) || extraOn.includes(row.bikeClass));
          if (profileOn) {
            on = visible && profileOn.has(row.bikeClass);
            if (row.bikeClass === "mtb" && /^S[0-3]\+?$/.test(row.key)) {
              on = on && (scaleOn?.includes(row.key) ?? false);
            }
            if (row.key === "unrated" && rideProfileId) {
              on = on && prefersUnratedTrails(rideProfileId);
            }
          }
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
                <span>{overlayLegendLabel(row.key, lang) || row.label}</span>
              </button>
            </li>
          );
        })}
      </ul>
      )}
      {!mesh && (
        <ul className="mt-1.5 flex flex-col gap-0.5">
          {BIKE_OVERLAY_SURFACE_LEGEND.map((row) => (
            <li
              key={row.key}
              className="flex items-center gap-1.5 text-[9px] text-white/70"
            >
              <span
                className="inline-block h-0.5 w-3.5 rounded-full"
                style={{ background: row.color }}
              />
              <span>
                {row.key === "gravel"
                  ? o.surfaceGravel
                  : overlayLegendLabel(row.key, lang)}
              </span>
            </li>
          ))}
        </ul>
      )}
      {!mesh && (
        <p className="mt-1 max-w-[11rem] text-[9px] leading-snug text-white/55">
          {o.surfaceNote}
        </p>
      )}
      <p className="mt-1.5 max-w-[11rem] text-[9px] leading-snug text-white/55">
        {mesh ? o.meshNote : o.scaleNote}
      </p>
    </div>
  );
}
