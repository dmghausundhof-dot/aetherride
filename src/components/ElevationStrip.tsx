"use client";

/**
 * Mini-Höhenprofil für Home „HEUTE PASST“ (Spec ElevationStrip).
 * Ohne echte Elev-Serie: synthetisches Profil — UI kennzeichnet als Schätzung.
 */

import { useChromeLang } from "@/hooks/useChromeLang";
import { discoverUi } from "@/lib/i18n/discoverUi";

export function ElevationStrip({
  elevationM,
  distanceKm,
  className,
  /** Echte Höhenpunkte (z. B. Ride-Track); sonst synthetisch */
  elevProfile,
  /** Kennzeichnung wenn Profil geschätzt/synthetisch ist */
  estimated,
}: {
  elevationM: number;
  distanceKm: number;
  className?: string;
  elevProfile?: number[];
  estimated?: boolean;
}) {
  const ui = discoverUi(useChromeLang());
  const fromTrack =
    elevProfile &&
    elevProfile.length >= 4 &&
    elevProfile.some((v) => Number.isFinite(v));
  const points = fromTrack
    ? elevProfile!
    : buildSyntheticProfile(elevationM, distanceKm);
  const isEstimate = estimated ?? !fromTrack;
  const max = Math.max(...points, 1);
  const min = Math.min(...points, 0);
  const span = Math.max(max - min, 1);
  const w = 200;
  const h = 28;
  const d = points
    .map((y, i) => {
      const x = (i / (points.length - 1)) * w;
      const py = h - ((y - min) / span) * (h - 4) - 2;
      return `${i === 0 ? "M" : "L"}${x.toFixed(1)},${py.toFixed(1)}`;
    })
    .join(" ");

  return (
    <div className={className}>
      <svg
        viewBox={`0 0 ${w} ${h}`}
        aria-label={
          isEstimate
            ? ui.elevEst(elevationM)
            : ui.elevProfile(elevationM)
        }
        preserveAspectRatio="none"
        width="100%"
        height={28}
      >
        <path
          d={d}
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          className="text-accent"
        />
      </svg>
      {isEstimate && (
        <p className="mt-0.5 text-[10px] text-text-secondary">{ui.estimate}</p>
      )}
    </div>
  );
}

/** Einfaches synthetisches Profil: Anstieg → Plateau → Abfahrt. */
function buildSyntheticProfile(elevationM: number, distanceKm: number): number[] {
  const n = 24;
  const peak = Math.max(elevationM, 80);
  const out: number[] = [];
  for (let i = 0; i < n; i++) {
    const t = i / (n - 1);
    // asymmetrisch: längerer Anstieg
    let y: number;
    if (t < 0.55) {
      y = peak * Math.pow(t / 0.55, 1.15);
    } else if (t < 0.7) {
      y = peak * (1 - (t - 0.55) * 0.15);
    } else {
      y = peak * 0.85 * (1 - (t - 0.7) / 0.3);
    }
    // leichte Distanz-Modulation
    y *= 0.92 + 0.08 * Math.sin(t * Math.PI * (2 + distanceKm / 40));
    out.push(Math.max(0, y));
  }
  return out;
}
