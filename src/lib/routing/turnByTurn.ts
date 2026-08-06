/**
 * F-NAV-003 — Turn-by-Turn-Sprachnavigation (P0)
 *
 * Manöver aus Valhalla; Formulierung lokal; System-TTS.
 * Ansagen: 400 / 150 / 30 m (bei > 25 km/h zeitbasiert).
 * Sprachen Launch: DE, EN. Audio-Ducking Pflicht.
 */

import type { RouteResult } from "./profiles";

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
