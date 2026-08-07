/**
 * Mini-Höhenprofil für Home „HEUTE PASST“ (Spec ElevationStrip).
 */

export function ElevationStrip({
  elevationM,
  distanceKm,
  className,
}: {
  elevationM: number;
  distanceKm: number;
  className?: string;
}) {
  const points = buildSyntheticProfile(elevationM, distanceKm);
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
    <svg
      viewBox={`0 0 ${w} ${h}`}
      className={className}
      aria-hidden
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
