import { BIKE_CATALOG } from "./bikes";

export type CatalogBikeHit = {
  id: string;
  manufacturerId: string;
  manufacturerName: string;
  name: string;
  year: number;
  category: string;
  isEbike: boolean;
  score: number;
};

/** Textsuche über den OEM-Katalog — ohne LLM, immer verfügbar. */
export function searchCatalogBikes(q: string, limit = 8): CatalogBikeHit[] {
  const needle = q.trim().toLowerCase();
  if (needle.length < 2) return [];
  const tokens = needle.split(/\s+/).filter((t) => t.length >= 2);
  const hits: CatalogBikeHit[] = [];
  for (const m of BIKE_CATALOG) {
    for (const b of m.bikes) {
      const hay =
        `${m.name} ${m.id} ${b.name} ${b.id} ${b.year} ${b.category}`.toLowerCase();
      let score = 0;
      if (hay.includes(needle)) score += 14;
      for (const t of tokens) {
        if (m.name.toLowerCase() === t) score += 10;
        else if (m.name.toLowerCase().includes(t)) score += 6;
        if (b.name.toLowerCase().includes(t)) score += 8;
        else if (hay.includes(t)) score += 2;
      }
      if (score > 0) {
        hits.push({
          id: b.id,
          manufacturerId: m.id,
          manufacturerName: m.name,
          name: b.name,
          year: b.year,
          category: b.category,
          isEbike: b.isEbike,
          score,
        });
      }
    }
  }
  hits.sort((a, b) => b.score - a.score || b.year - a.year);
  return hits.slice(0, limit);
}

export function catalogNameIndex(): string {
  return BIKE_CATALOG.map((m) => {
    const models = m.bikes.map((b) => `${b.name} (${b.year})`).join(", ");
    return `${m.name}: ${models}`;
  }).join("\n");
}

const VISION_SLOT_ALIASES: Record<string, string> = {
  shock: "rear_shock",
  damper: "rear_shock",
  rearshock: "rear_shock",
  dropper: "seatpost",
  vario: "seatpost",
  tyre_front: "tire_front",
  tyre_rear: "tire_rear",
  front_tyre: "tire_front",
  rear_tyre: "tire_rear",
  front_tire: "tire_front",
  rear_tire: "tire_rear",
  mech: "rear_derailleur",
  derailleur: "rear_derailleur",
};

export type VisionPartHint = {
  slot: string;
  manufacturer?: string;
  model?: string;
};

/** Grok-Slots normalisieren; unbekannte Slots behalten — nicht verwerfen. */
export function normalizeVisionSlot(raw: string): string {
  const slot = raw.trim().toLowerCase().replace(/-/g, "_");
  return VISION_SLOT_ALIASES[slot] ?? slot;
}

export function parseVisionParts(raw: unknown): VisionPartHint[] {
  if (!Array.isArray(raw)) return [];
  const out: VisionPartHint[] = [];
  for (const e of raw) {
    if (!e || typeof e !== "object") continue;
    const m = e as Record<string, unknown>;
    const slot = normalizeVisionSlot(String(m.slot ?? ""));
    if (!slot) continue;
    const manufacturer = String(m.manufacturer ?? "").trim();
    const model = String(m.model ?? "").trim();
    if (!manufacturer && !model) continue;
    out.push({
      slot,
      ...(manufacturer ? { manufacturer } : {}),
      ...(model ? { model } : {}),
    });
    if (out.length >= 12) break;
  }
  return out;
}
