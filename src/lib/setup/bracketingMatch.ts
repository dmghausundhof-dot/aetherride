/**
 * F-SET-003 — Segment-Geometrie-Matching für Bracketing
 *
 * Auswertung nur auf vergleichbaren Segmenten (Geometrie + Richtung).
 * Demo: Hausdorff-Proxy auf Track-Punkten + Längen-/Höhen-Toleranz.
 */

export interface TrackPoint {
  lat: number;
  lng: number;
  elev?: number;
}

export interface SegmentMatchResult {
  matched: boolean;
  score: number; // 0–1
  lengthRatio: number;
  meanDistanceM: number;
  reason: string;
}

function haversineM(a: TrackPoint, b: TrackPoint): number {
  const R = 6371000;
  const toR = (d: number) => (d * Math.PI) / 180;
  const dLat = toR(b.lat - a.lat);
  const dLon = toR(b.lng - a.lng);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toR(a.lat)) * Math.cos(toR(b.lat)) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

function pathLength(pts: TrackPoint[]): number {
  let d = 0;
  for (let i = 1; i < pts.length; i++) d += haversineM(pts[i - 1], pts[i]);
  return d;
}

function meanNearestDistance(a: TrackPoint[], b: TrackPoint[]): number {
  if (!a.length || !b.length) return Infinity;
  let sum = 0;
  for (const p of a) {
    let best = Infinity;
    for (const q of b) best = Math.min(best, haversineM(p, q));
    sum += best;
  }
  return sum / a.length;
}

/**
 * Zwei Bracketing-Läufe gelten als vergleichbar wenn:
 * - Längenverhältnis 0.9–1.1
 * - mittlere Punkt-Distanz < 25 m
 * - Startrichtung grob gleich (Dot-Produkt > 0)
 */
export function matchReferenceSegment(
  reference: TrackPoint[],
  candidate: TrackPoint[],
  opts: { maxMeanDistM?: number; lengthTol?: number } = {}
): SegmentMatchResult {
  const maxMean = opts.maxMeanDistM ?? 25;
  const lengthTol = opts.lengthTol ?? 0.1;

  if (reference.length < 5 || candidate.length < 5) {
    return {
      matched: false,
      score: 0,
      lengthRatio: 0,
      meanDistanceM: Infinity,
      reason: "Zu wenige Trackpunkte für Geometrie-Match",
    };
  }

  const lenR = pathLength(reference);
  const lenC = pathLength(candidate);
  const lengthRatio = lenR > 0 ? lenC / lenR : 0;
  if (Math.abs(1 - lengthRatio) > lengthTol) {
    return {
      matched: false,
      score: 0,
      lengthRatio,
      meanDistanceM: Infinity,
      reason: `Längenverhältnis ${lengthRatio.toFixed(2)} außerhalb ±${lengthTol * 100}%`,
    };
  }

  // Richtung: Vektor Start→Ende
  const vR = {
    x: reference[reference.length - 1].lng - reference[0].lng,
    y: reference[reference.length - 1].lat - reference[0].lat,
  };
  const vC = {
    x: candidate[candidate.length - 1].lng - candidate[0].lng,
    y: candidate[candidate.length - 1].lat - candidate[0].lat,
  };
  const dot = vR.x * vC.x + vR.y * vC.y;
  if (dot <= 0) {
    return {
      matched: false,
      score: 0,
      lengthRatio,
      meanDistanceM: Infinity,
      reason: "Gegenrichtung — Segment nicht vergleichbar",
    };
  }

  const d1 = meanNearestDistance(reference, candidate);
  const d2 = meanNearestDistance(candidate, reference);
  const meanDistanceM = (d1 + d2) / 2;
  const score = Math.max(0, 1 - meanDistanceM / maxMean);

  return {
    matched: meanDistanceM <= maxMean,
    score: Math.round(score * 100) / 100,
    lengthRatio: Math.round(lengthRatio * 100) / 100,
    meanDistanceM: Math.round(meanDistanceM * 10) / 10,
    reason:
      meanDistanceM <= maxMean
        ? "Geometrie matcht — Auswertung zulässig"
        : `Mittlere Distanz ${meanDistanceM.toFixed(1)} m > ${maxMean} m`,
  };
}
