/**
 * Trail-Zustände — Community-Schmerzpunkt: „Conditions nur auf der Website“
 * Lokal, kein Social-Network Fake.
 */

export type TrailConditionKind =
  | "dry"
  | "grippy"
  | "wet"
  | "muddy"
  | "closed"
  | "unknown";

export interface TrailConditionReport {
  id: string;
  routeOrTrailId: string;
  labelDe: string;
  condition: TrailConditionKind;
  note?: string;
  reportedAt: string;
}

const KEY = "aetherride.trailConditions.v1";

/** Node/Tests ohne window */
let memoryStore: TrailConditionReport[] = [];

export const TRAIL_CONDITION_LABELS: Record<TrailConditionKind, string> = {
  dry: "Trocken",
  grippy: "Griffig",
  wet: "Nass",
  muddy: "Matschig",
  closed: "Gesperrt / nicht fahren",
  unknown: "Unklar",
};

export function loadTrailConditions(): TrailConditionReport[] {
  if (typeof window === "undefined") return [...memoryStore];
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw) as TrailConditionReport[];
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

export function saveTrailConditions(list: TrailConditionReport[]) {
  const next = list.slice(0, 80);
  memoryStore = next;
  if (typeof window === "undefined") return;
  localStorage.setItem(KEY, JSON.stringify(next));
}

export function upsertTrailCondition(
  input: Omit<TrailConditionReport, "id" | "reportedAt"> & { id?: string }
): TrailConditionReport {
  const list = loadTrailConditions().filter(
    (r) => r.routeOrTrailId !== input.routeOrTrailId
  );
  const row: TrailConditionReport = {
    id: input.id ?? `tc-${Date.now()}`,
    routeOrTrailId: input.routeOrTrailId,
    labelDe: input.labelDe,
    condition: input.condition,
    note: input.note,
    reportedAt: new Date().toISOString(),
  };
  list.unshift(row);
  saveTrailConditions(list);
  return row;
}

export function latestConditionFor(
  routeOrTrailId: string
): TrailConditionReport | undefined {
  return loadTrailConditions().find((r) => r.routeOrTrailId === routeOrTrailId);
}
