/**
 * Plan-Adressverlauf im Browser — max. 5, lokal, kein Account.
 */
export const PLAN_ADDR_RECENTS_KEY = "aetherride.planAddrRecents";

export type PlanAddrRecent = { label: string; lat: number; lng: number };

export function parsePlanAddrRecents(raw: unknown): PlanAddrRecent[] {
  if (!Array.isArray(raw)) return [];
  const out: PlanAddrRecent[] = [];
  for (const e of raw) {
    if (!e || typeof e !== "object") continue;
    const o = e as Record<string, unknown>;
    const label = typeof o.label === "string" ? o.label.trim() : "";
    const lat = typeof o.lat === "number" ? o.lat : Number(o.lat);
    const lng = typeof o.lng === "number" ? o.lng : Number(o.lng);
    if (!label || !Number.isFinite(lat) || !Number.isFinite(lng)) continue;
    if (Math.abs(lat) > 90 || Math.abs(lng) > 180) continue;
    if (out.some((x) => x.label === label)) continue;
    out.push({ label, lat, lng });
    if (out.length >= 5) break;
  }
  return out;
}

export function pushPlanAddrRecent(
  hit: PlanAddrRecent,
  prev: PlanAddrRecent[],
): PlanAddrRecent[] {
  const label = hit.label.trim();
  if (!label) return prev.slice(0, 5);
  return [
    { ...hit, label },
    ...prev.filter((x) => x.label !== label),
  ].slice(0, 5);
}

export function readPlanAddrRecents(): PlanAddrRecent[] {
  if (typeof window === "undefined") return [];
  try {
    const raw = window.localStorage.getItem(PLAN_ADDR_RECENTS_KEY);
    if (!raw) return [];
    return parsePlanAddrRecents(JSON.parse(raw));
  } catch {
    return [];
  }
}

export function writePlanAddrRecents(hits: PlanAddrRecent[]): void {
  if (typeof window === "undefined") return;
  try {
    window.localStorage.setItem(
      PLAN_ADDR_RECENTS_KEY,
      JSON.stringify(parsePlanAddrRecents(hits))
    );
  } catch {
    // Quota / private mode
  }
}
