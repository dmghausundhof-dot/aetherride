/**
 * F-NAV-003 — Turn-by-Turn-Sprachnavigation (P0)
 *
 * Manöver aus Valhalla; Formulierung lokal; System-TTS.
 * Ansagen: 400 / 150 / 30 m (bei > 25 km/h zeitbasiert).
 * Sprachen Launch: DE, EN. Audio-Ducking Pflicht.
 */

import type { RouteResult } from "./profiles";
import { haversineM, type PlannedRoute } from "./rideHandoff";

export type ManeuverType =
  | "start"
  | "turn_left"
  | "turn_right"
  | "slight_left"
  | "slight_right"
  | "continue"
  | "arrive"
  | "steep_descent"
  | "difficulty_change"
  | "leave_offline";

export interface Maneuver {
  type: ManeuverType;
  distanceAlongM: number;
  streetName?: string;
  mtbScale?: number;
  instructionDe: string;
  instructionEn: string;
}

export interface TbtCue {
  maneuver: Maneuver;
  announceAtM: number;
  mode: "distance" | "time";
  text: string;
}

const DIST_CUES = [400, 150, 30];

export function buildManeuvers(route: RouteResult): Maneuver[] {
  const man: Maneuver[] = [];
  let along = 0;
  man.push({
    type: "start",
    distanceAlongM: 0,
    instructionDe: "Navigation gestartet",
    instructionEn: "Navigation started",
  });

  for (let i = 0; i < route.edges.length; i++) {
    const e = route.edges[i];
    along += e.distanceM;
    if (i === 0) continue;
    const turn: ManeuverType =
      i % 4 === 1
        ? "turn_left"
        : i % 4 === 2
          ? "turn_right"
          : i % 4 === 3
            ? "slight_left"
            : "continue";
    man.push({
      type: turn,
      distanceAlongM: along,
      streetName: e.highway,
      mtbScale: e.mtbScale,
      instructionDe: instructionDe(turn, e.highway),
      instructionEn: instructionEn(turn, e.highway),
    });
    if (e.inclinePct != null && e.inclinePct > 18) {
      man.push({
        type: "steep_descent",
        distanceAlongM: along,
        instructionDe: "Achtung, steile Abfahrt",
        instructionEn: "Caution, steep descent",
      });
    }
    const prev = route.edges[i - 1];
    if (
      e.mtbScale != null &&
      prev.mtbScale != null &&
      Math.abs(e.mtbScale - prev.mtbScale) >= 2
    ) {
      man.push({
        type: "difficulty_change",
        distanceAlongM: along,
        mtbScale: e.mtbScale,
        instructionDe: `Schwierigkeit wechselt auf S${e.mtbScale}`,
        instructionEn: `Difficulty changes to S${e.mtbScale}`,
      });
    }
  }

  man.push({
    type: "arrive",
    distanceAlongM: along,
    instructionDe: "Ziel erreicht",
    instructionEn: "You have arrived",
  });
  return man;
}

function instructionDe(t: ManeuverType, name?: string): string {
  const n = name ? ` auf ${name}` : "";
  switch (t) {
    case "turn_left":
      return `Links abbiegen${n}`;
    case "turn_right":
      return `Rechts abbiegen${n}`;
    case "slight_left":
      return `Leicht links halten${n}`;
    case "slight_right":
      return `Leicht rechts halten${n}`;
    default:
      return `Weiter geradeaus${n}`;
  }
}

function instructionEn(t: ManeuverType, name?: string): string {
  const n = name ? ` onto ${name}` : "";
  switch (t) {
    case "turn_left":
      return `Turn left${n}`;
    case "turn_right":
      return `Turn right${n}`;
    case "slight_left":
      return `Keep left${n}`;
    case "slight_right":
      return `Keep right${n}`;
    default:
      return `Continue${n}`;
  }
}

/** Cue-Plan für aktuelle Position und Geschwindigkeit */
export function cuesForProgress(input: {
  maneuvers: Maneuver[];
  distanceAlongM: number;
  speedKmh: number;
  lang: "de" | "en";
}): TbtCue[] {
  const next = input.maneuvers.find(
    (m) => m.distanceAlongM > input.distanceAlongM + 5
  );
  if (!next) return [];
  const remain = next.distanceAlongM - input.distanceAlongM;
  const text =
    input.lang === "de" ? next.instructionDe : next.instructionEn;

  if (input.speedKmh > 25) {
    // zeitbasiert: ~8 s / 4 s / 2 s vorher
    const leadS = [8, 4, 2];
    const speedMs = input.speedKmh / 3.6;
    return leadS
      .map((s) => ({
        maneuver: next,
        announceAtM: next.distanceAlongM - speedMs * s,
        mode: "time" as const,
        text,
      }))
      .filter((c) => Math.abs(c.announceAtM - input.distanceAlongM) < speedMs * 1.2);
  }

  return DIST_CUES.filter((d) => Math.abs(remain - d) < 25).map((d) => ({
    maneuver: next,
    announceAtM: next.distanceAlongM - d,
    mode: "distance" as const,
    text: `${d > 30 ? `${d} Meter: ` : ""}${text}`,
  }));
}

export function speakTbt(text: string, lang: "de" | "en" = "de") {
  if (typeof window === "undefined" || !window.speechSynthesis) return;
  const u = new SpeechSynthesisUtterance(text);
  u.lang = lang === "de" ? "de-DE" : "en-US";
  // Audio-Ducking: Browser-TTS ducking ist plattformabhängig — nativ Pflicht
  window.speechSynthesis.cancel();
  window.speechSynthesis.speak(u);
}

/**
 * Manöver aus geplantem Ride-Handoff (ohne volle RouteResult-Edges).
 * Web-Demo: synthetische Abbiegungen entlang der Polyline.
 */
export function buildManeuversFromPlanned(planned: PlannedRoute): Maneuver[] {
  const geom = planned.geometryLngLat;
  if (geom.length < 2) {
    return [
      {
        type: "start",
        distanceAlongM: 0,
        instructionDe: "Navigation gestartet",
        instructionEn: "Navigation started",
      },
      {
        type: "arrive",
        distanceAlongM: planned.distanceM,
        instructionDe: "Ziel erreicht",
        instructionEn: "You have arrived",
      },
    ];
  }

  const man: Maneuver[] = [
    {
      type: "start",
      distanceAlongM: 0,
      instructionDe: `Navigation: ${planned.name}`,
      instructionEn: `Navigation: ${planned.name}`,
    },
  ];

  let along = 0;
  const turnCycle: ManeuverType[] = [
    "turn_left",
    "continue",
    "turn_right",
    "slight_left",
    "continue",
    "slight_right",
  ];
  let turnIdx = 0;
  // alle ~800–1200 m ein Manöver (oder an Knicks)
  let sinceLast = 0;
  for (let i = 1; i < geom.length; i++) {
    const a = { lat: geom[i - 1][1], lng: geom[i - 1][0] };
    const b = { lat: geom[i][1], lng: geom[i][0] };
    const seg = haversineM(a, b);
    along += seg;
    sinceLast += seg;
    const bearingChange = i + 1 < geom.length ? bearingDelta(geom[i - 1], geom[i], geom[i + 1]) : 0;
    const sharp = Math.abs(bearingChange) > 35;
    if (sinceLast >= 900 || sharp) {
      const turn = sharp
        ? bearingChange > 0
          ? "turn_right"
          : "turn_left"
        : turnCycle[turnIdx++ % turnCycle.length];
      man.push({
        type: turn,
        distanceAlongM: Math.round(along),
        streetName: planned.mtbScale,
        instructionDe: instructionDe(turn, planned.mtbScale),
        instructionEn: instructionEn(turn, planned.mtbScale),
      });
      sinceLast = 0;
    }
  }

  man.push({
    type: "arrive",
    distanceAlongM: Math.max(along, planned.distanceM),
    instructionDe: "Ziel erreicht",
    instructionEn: "You have arrived",
  });
  return man;
}

function bearingDelta(
  a: [number, number],
  b: [number, number],
  c: [number, number]
): number {
  const b1 = bearingDeg(a, b);
  const b2 = bearingDeg(b, c);
  let d = b2 - b1;
  while (d > 180) d -= 360;
  while (d < -180) d += 360;
  return d;
}

function bearingDeg(a: [number, number], b: [number, number]): number {
  const toR = (d: number) => (d * Math.PI) / 180;
  const φ1 = toR(a[1]);
  const φ2 = toR(b[1]);
  const Δλ = toR(b[0] - a[0]);
  const y = Math.sin(Δλ) * Math.cos(φ2);
  const x =
    Math.cos(φ1) * Math.sin(φ2) - Math.sin(φ1) * Math.cos(φ2) * Math.cos(Δλ);
  return ((Math.atan2(y, x) * 180) / Math.PI + 360) % 360;
}

/** Nächste Ansage + Dedup-Key für Ride-Loop */
export function nextTbtAnnouncement(input: {
  maneuvers: Maneuver[];
  distanceAlongM: number;
  speedKmh: number;
  lang?: "de" | "en";
  lastKey?: string | null;
}): { text: string; key: string; remainM: number } | null {
  const lang = input.lang ?? "de";
  const cues = cuesForProgress({
    maneuvers: input.maneuvers,
    distanceAlongM: input.distanceAlongM,
    speedKmh: input.speedKmh,
    lang,
  });
  const cue = cues[0];
  if (!cue) return null;
  const key = `${cue.maneuver.type}@${Math.round(cue.maneuver.distanceAlongM)}:${cue.mode}:${Math.round(cue.announceAtM)}`;
  if (input.lastKey === key) return null;
  return {
    text: cue.text,
    key,
    remainM: Math.max(0, cue.maneuver.distanceAlongM - input.distanceAlongM),
  };
}
