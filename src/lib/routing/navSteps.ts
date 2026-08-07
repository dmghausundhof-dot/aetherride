/**
 * F-NAV-003 — Engine-Manöver (Valhalla / OSRM / Demo)
 * Interne Normalform für Turn-by-Turn.
 */

export type NavStepType =
  | "start"
  | "turn"
  | "continue"
  | "roundabout"
  | "arrive"
  | "uturn"
  | "merge"
  | "fork"
  | "unknown";

export interface NavStep {
  id: string;
  type: NavStepType;
  /** Lokalisierte Kurzansage (DE) */
  instruction: string;
  instructionEn: string;
  /** Meter vom Routenstart bis zum Manöver */
  distanceAlongM: number;
  /** Länge dieses Segments bis zum nächsten Manöver (m) */
  lengthM: number;
  bearingDeg?: number;
  coordinate?: { lat: number; lng: number };
  /** Roh-Typ der Engine (Debug) */
  engineType?: string | number;
}

/** Spec: Ansagen 400 / 150 / 30 m; bei v>25 km/h zeitbasiert */
export const ANNOUNCE_DISTANCES_M = [400, 150, 30] as const;

export function announceDistancesForSpeed(speedKmh: number): number[] {
  if (speedKmh > 25) {
    // ~8 s / 4 s / 1.5 s Vorlauf
    const ms = (speedKmh * 1000) / 3600;
    return [Math.round(ms * 8), Math.round(ms * 4), Math.round(ms * 1.5)];
  }
  return [...ANNOUNCE_DISTANCES_M];
}

function haversineM(
  a: { lat: number; lng: number },
  b: { lat: number; lng: number }
): number {
  const R = 6371000;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const lat1 = toRad(a.lat);
  const lat2 = toRad(b.lat);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.min(1, Math.sqrt(h)));
}

function alongFromShape(
  coords: [number, number][],
  shapeIndex: number
): number {
  let d = 0;
  const end = Math.min(shapeIndex, coords.length - 1);
  for (let i = 1; i <= end; i++) {
    d += haversineM(
      { lng: coords[i - 1][0], lat: coords[i - 1][1] },
      { lng: coords[i][0], lat: coords[i][1] }
    );
  }
  return d;
}

/** Valhalla maneuver type → NavStepType */
export function valhallaTypeToNav(type: number): NavStepType {
  if (type === 0 || type === 1 || type === 2 || type === 3) return "start";
  if (type === 4 || type === 5 || type === 6) return "arrive";
  if (type === 7 || type === 8 || type === 9) return "continue";
  if (type >= 10 && type <= 14) return "turn"; // slight/right/left variants
  if (type === 15 || type === 16 || type === 17 || type === 18 || type === 19)
    return "turn";
  if (type === 20 || type === 21) return "uturn";
  if (type === 22 || type === 23 || type === 24 || type === 25)
    return "roundabout";
  if (type === 26 || type === 27) return "merge";
  if (type === 28 || type === 29) return "fork";
  return "unknown";
}

export function localizeValhallaInstruction(
  raw: string,
  type: number
): { de: string; en: string } {
  const en = raw?.trim() || "Continue";
  // Valhalla liefert oft EN; kurze DE-Mappings für Kernfälle
  const lower = en.toLowerCase();
  let de = en;
  if (type === 4 || type === 5 || type === 6 || lower.includes("destination")) {
    de = "Ziel erreicht";
  } else if (lower.includes("uturn") || lower.includes("u-turn")) {
    de = "Wenden";
  } else if (lower.includes("sharp left")) de = "Scharf links";
  else if (lower.includes("sharp right")) de = "Scharf rechts";
  else if (lower.includes("slight left") || lower.includes("bear left"))
    de = "Leicht links";
  else if (lower.includes("slight right") || lower.includes("bear right"))
    de = "Leicht rechts";
  else if (lower.startsWith("turn left") || lower.includes(" left onto"))
    de = "Links abbiegen";
  else if (lower.startsWith("turn right") || lower.includes(" right onto"))
    de = "Rechts abbiegen";
  else if (lower.includes("roundabout")) de = "Kreisverkehr";
  else if (lower.includes("continue") || lower.includes("straight"))
    de = "Geradeaus";
  else if (lower.startsWith("go ") || type === 0) de = "Losfahren";
  return { de, en };
}

export function stepsFromValhallaLeg(
  maneuvers: Array<{
    type?: number;
    instruction?: string;
    length?: number;
    begin_shape_index?: number;
    begin_heading?: number;
  }>,
  shapeCoords: [number, number][],
  unitsKilometers: boolean
): NavStep[] {
  const steps: NavStep[] = [];
  let along = 0;
  for (let i = 0; i < maneuvers.length; i++) {
    const m = maneuvers[i];
    const typeNum = m.type ?? 0;
    const idx = m.begin_shape_index ?? 0;
    along =
      shapeCoords.length > 0
        ? alongFromShape(shapeCoords, idx)
        : along;
    const lengthM = unitsKilometers
      ? Math.round((m.length ?? 0) * 1000)
      : Math.round(m.length ?? 0);
    const { de, en } = localizeValhallaInstruction(
      m.instruction ?? "",
      typeNum
    );
    const coord = shapeCoords[Math.min(idx, shapeCoords.length - 1)];
    steps.push({
      id: `vh-${i}`,
      type: valhallaTypeToNav(typeNum),
      instruction: de,
      instructionEn: en,
      distanceAlongM: Math.round(along),
      lengthM,
      bearingDeg: m.begin_heading,
      coordinate: coord
        ? { lng: coord[0], lat: coord[1] }
        : undefined,
      engineType: typeNum,
    });
  }
  return steps;
}

function osrmModifierToDe(modifier?: string, type?: string): {
  de: string;
  en: string;
  nav: NavStepType;
} {
  const t = (type || "").toLowerCase();
  const m = (modifier || "").toLowerCase();
  if (t === "depart") return { de: "Losfahren", en: "Depart", nav: "start" };
  if (t === "arrive")
    return { de: "Ziel erreicht", en: "You have arrived", nav: "arrive" };
  if (t === "roundabout" || t === "rotary")
    return { de: "Kreisverkehr", en: "Enter roundabout", nav: "roundabout" };
  if (t.includes("uturn") || m === "uturn")
    return { de: "Wenden", en: "Make a U-turn", nav: "uturn" };
  if (t === "merge") return { de: "Einfädeln", en: "Merge", nav: "merge" };
  if (t === "fork") return { de: "Gabelung", en: "Keep at fork", nav: "fork" };
  if (t === "new name" || t === "notification" || t === "continue")
    return { de: "Geradeaus", en: "Continue", nav: "continue" };

  if (m === "sharp left")
    return { de: "Scharf links", en: "Sharp left", nav: "turn" };
  if (m === "sharp right")
    return { de: "Scharf rechts", en: "Sharp right", nav: "turn" };
  if (m === "slight left")
    return { de: "Leicht links", en: "Slight left", nav: "turn" };
  if (m === "slight right")
    return { de: "Leicht rechts", en: "Slight right", nav: "turn" };
  if (m === "left")
    return { de: "Links abbiegen", en: "Turn left", nav: "turn" };
  if (m === "right")
    return { de: "Rechts abbiegen", en: "Turn right", nav: "turn" };
  if (m === "straight")
    return { de: "Geradeaus", en: "Continue straight", nav: "continue" };
  return { de: "Weiter", en: "Continue", nav: "unknown" };
}

export function stepsFromOsrmLegs(
  legs: Array<{
    steps?: Array<{
      distance?: number;
      name?: string;
      maneuver?: {
        type?: string;
        modifier?: string;
        location?: [number, number];
        bearing_after?: number;
      };
    }>;
  }>
): NavStep[] {
  const steps: NavStep[] = [];
  let along = 0;
  let i = 0;
  for (const leg of legs) {
    for (const s of leg.steps ?? []) {
      const { de, en, nav } = osrmModifierToDe(
        s.maneuver?.modifier,
        s.maneuver?.type
      );
      const name = s.name?.trim();
      const instruction = name && nav === "turn" ? `${de} auf ${name}` : de;
      const instructionEn =
        name && nav === "turn" ? `${en} onto ${name}` : en;
      const loc = s.maneuver?.location;
      steps.push({
        id: `osrm-${i++}`,
        type: nav,
        instruction,
        instructionEn,
        distanceAlongM: Math.round(along),
        lengthM: Math.round(s.distance ?? 0),
        bearingDeg: s.maneuver?.bearing_after,
        coordinate: loc
          ? { lng: loc[0], lat: loc[1] }
          : undefined,
        engineType: `${s.maneuver?.type ?? ""}:${s.maneuver?.modifier ?? ""}`,
      });
      along += s.distance ?? 0;
    }
  }
  return steps;
}

/** Demo-Steps aus wenigen Stützpunkten */
export function stepsFromDemoGeometry(
  coords: [number, number][]
): NavStep[] {
  if (coords.length < 2) return [];
  const steps: NavStep[] = [
    {
      id: "demo-0",
      type: "start",
      instruction: "Losfahren",
      instructionEn: "Depart",
      distanceAlongM: 0,
      lengthM: 0,
      coordinate: { lng: coords[0][0], lat: coords[0][1] },
    },
  ];
  let along = 0;
  const mid = Math.floor(coords.length / 2);
  for (let i = 1; i < coords.length; i++) {
    along += haversineM(
      { lng: coords[i - 1][0], lat: coords[i - 1][1] },
      { lng: coords[i][0], lat: coords[i][1] }
    );
    if (i === mid) {
      steps.push({
        id: "demo-turn",
        type: "turn",
        instruction: "Rechts abbiegen",
        instructionEn: "Turn right",
        distanceAlongM: Math.round(along),
        lengthM: 0,
        coordinate: { lng: coords[i][0], lat: coords[i][1] },
      });
    }
  }
  steps.push({
    id: "demo-arrive",
    type: "arrive",
    instruction: "Ziel erreicht",
    instructionEn: "You have arrived",
    distanceAlongM: Math.round(along),
    lengthM: 0,
    coordinate: {
      lng: coords[coords.length - 1][0],
      lat: coords[coords.length - 1][1],
    },
  });
  // lengthM zwischen Manövern
  for (let i = 0; i < steps.length - 1; i++) {
    steps[i].lengthM = steps[i + 1].distanceAlongM - steps[i].distanceAlongM;
  }
  return steps;
}

export function nextEngineStep(
  steps: NavStep[],
  distanceAlongM: number
): { step: NavStep; remainingM: number } | null {
  for (const step of steps) {
    if (step.type === "start") continue;
    const remaining = step.distanceAlongM - distanceAlongM;
    if (remaining > 8) {
      return { step, remainingM: Math.round(remaining) };
    }
  }
  return null;
}

export function stepBannerText(step: NavStep, remainingM: number): string {
  if (step.type === "arrive") return step.instruction;
  if (remainingM >= 1000) {
    return `In ${(remainingM / 1000).toFixed(1)} km ${step.instruction.toLowerCase()}`;
  }
  return `In ${remainingM} m ${step.instruction.toLowerCase()}`;
}

/** Welche Ansage-Stufe (400/150/30) gerade fällig ist */
export function dueAnnounceTier(
  remainingM: number,
  speedKmh: number,
  alreadyAnnounced: Set<string>
): { key: string; text: string } | null {
  const distances = announceDistancesForSpeed(speedKmh);
  const next = distances
    .slice()
    .sort((a, b) => b - a)
    .find((d) => remainingM <= d + 15 && remainingM > d - 40);
  if (next == null) return null;
  return null; // caller uses step id + tier
}

export function announceKey(stepId: string, tierM: number): string {
  return `${stepId}@${tierM}`;
}

export function pickAnnounce(
  step: NavStep,
  remainingM: number,
  speedKmh: number,
  spoken: Set<string>
): string | null {
  const tiers = announceDistancesForSpeed(speedKmh).sort((a, b) => b - a);
  for (const tier of tiers) {
    if (remainingM <= tier + 20 && remainingM >= Math.max(0, tier - 55)) {
      const key = announceKey(step.id, tier);
      if (spoken.has(key)) continue;
      spoken.add(key);
      if (step.type === "arrive") return step.instruction;
      return `${step.instruction} in ${Math.round(remainingM)} Metern`;
    }
  }
  return null;
}
