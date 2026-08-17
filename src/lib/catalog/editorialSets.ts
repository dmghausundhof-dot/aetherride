/**
 * Redaktionelle Region-Sets: bestehende PublicTours gruppiert.
 * Kein Fake-UGC — nur Katalog-IDs, die wirklich im RAW stehen.
 */

import { getRegion } from "@/lib/catalog/regions";
import { listPublicTours } from "@/lib/catalog/publicTours";

export type EditorialSet = {
  id: string;
  regionSlug: string;
  name: string;
  tourIds: string[];
  count: number;
};

export function listEditorialSets(minTours = 3): EditorialSet[] {
  const bySlug = new Map<string, string[]>();
  for (const t of listPublicTours()) {
    const slug = t.regionSlug.trim();
    if (!slug || !t.id) continue;
    const list = bySlug.get(slug) ?? [];
    list.push(t.id);
    bySlug.set(slug, list);
  }
  const out: EditorialSet[] = [];
  for (const [slug, tourIds] of bySlug) {
    if (tourIds.length < minTours) continue;
    const region = getRegion(slug);
    out.push({
      id: `set-${slug}`,
      regionSlug: slug,
      name: region?.name ?? slug,
      tourIds,
      count: tourIds.length,
    });
  }
  out.sort((a, b) => b.count - a.count || a.name.localeCompare(b.name, "de"));
  return out;
}
