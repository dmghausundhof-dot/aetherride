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
