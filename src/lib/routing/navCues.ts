/**
 * F-NAV-003 — Cues aus Engine-Steps, Fallback Bearing entlang Polyline.
 */

import type { NavCue } from "@/types/route";
import type { NavStep } from "@/lib/routing/navSteps";
import {
  nextEngineStep,
  stepBannerText,
} from "@/lib/routing/navSteps";

function haversineM(
  a: [number, number],
  b: [number, number]
): number {
  const R = 6371000;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(b[1] - a[1]);
  const dLng = toRad(b[0] - a[0]);
  const lat1 = toRad(a[1]);
  const lat2 = toRad(b[1]);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.min(1, Math.sqrt(h)));
}

function bearingDeg(a: [number, number], b: [number, number]): number {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const toDeg = (r: number) => (r * 180) / Math.PI;
  const lat1 = toRad(a[1]);
  const lat2 = toRad(b[1]);
  const dLng = toRad(b[0] - a[0]);
  const y = Math.sin(dLng) * Math.cos(lat2);
  const x =
    Math.cos(lat1) * Math.sin(lat2) -
    Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLng);
  return (toDeg(Math.atan2(y, x)) + 360) % 360;
}

function turnInstruction(delta: number): string | null {
  const d = ((delta + 540) % 360) - 180;
  const abs = Math.abs(d);
  if (abs < 18) return null;
  if (abs < 40) return d > 0 ? "Leicht rechts" : "Leicht links";
  if (abs < 110) return d > 0 ? "Rechts abbiegen" : "Links abbiegen";
  return d > 0 ? "Scharf rechts" : "Scharf links";
}

export function cuesFromEngineSteps(steps: NavStep[]): NavCue[] {
  return steps
    .filter((s) => s.type !== "start")
    .map((s) => ({
      id: s.id,
      distanceAlongM: s.distanceAlongM,
      instruction: s.instruction,
      bearingDeg: s.bearingDeg ?? 0,
    }));
}

/** Bearing-Fallback wenn keine Engine-Steps */
export function buildNavCues(
  geometry: GeoJSON.LineString | null | undefined
): NavCue[] {
  const coords = geometry?.coordinates;
  if (!coords || coords.length < 4) return [];

  const cues: NavCue[] = [];
  let along = 0;
  let windowStart = 0;
  let windowAlong = 0;
  let prevSampleBearing: number | null = null;

  for (let i = 1; i < coords.length; i++) {
    const a = coords[i - 1] as [number, number];
    const b = coords[i] as [number, number];
    const seg = haversineM(a, b);
    along += seg;
    windowAlong += seg;

    if (windowAlong < 120 && i < coords.length - 1) continue;

    const start = coords[windowStart] as [number, number];
    const br = bearingDeg(start, b);
    if (prevSampleBearing != null) {
      const instruction = turnInstruction(br - prevSampleBearing);
      if (instruction) {
        const last = cues[cues.length - 1];
        if (!last || along - last.distanceAlongM > 150) {
          cues.push({
            id: `cue-${cues.length}`,
            distanceAlongM: Math.round(along),
            instruction,
            bearingDeg: Math.round(br),
          });
        }
      }
    }
    prevSampleBearing = br;
    windowStart = i;
    windowAlong = 0;
  }

  cues.push({
    id: "cue-finish",
    distanceAlongM: Math.round(along),
    instruction: "Ziel erreicht",
    bearingDeg: prevSampleBearing ?? 0,
  });

  return cues;
}

/** Bevorzugt Engine-Steps, sonst Bearing-Stub */
export function resolveNavCues(input: {
  steps?: NavStep[] | null;
  geometry?: GeoJSON.LineString | null;
}): NavCue[] {
  if (input.steps && input.steps.length > 0) {
    return cuesFromEngineSteps(input.steps);
  }
  return buildNavCues(input.geometry);
}

export function nextCue(
  cues: NavCue[],
  distanceAlongM: number
): { cue: NavCue; remainingM: number } | null {
  for (const cue of cues) {
    const remaining = cue.distanceAlongM - distanceAlongM;
    if (remaining > 12) {
      return { cue, remainingM: Math.round(remaining) };
    }
  }
  return null;
}

export function cueBannerText(
  cue: NavCue,
  remainingM: number
): string {
  if (cue.instruction === "Ziel erreicht") return "Ziel erreicht";
  if (remainingM >= 1000) {
    return `In ${(remainingM / 1000).toFixed(1)} km ${cue.instruction.toLowerCase()}`;
  }
  return `In ${remainingM} m ${cue.instruction.toLowerCase()}`;
}

export { nextEngineStep, stepBannerText };
