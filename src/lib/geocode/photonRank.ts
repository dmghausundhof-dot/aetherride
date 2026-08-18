export type RankableGeocodeHit = {
  label: string;
  lat: number;
  lng: number;
  kind?: string;
  name?: string;
};

/** First label token, e.g. "Berlin" from "Berlin, Deutschland". */
export function hitName(hit: RankableGeocodeHit): string {
  const raw = (hit.name ?? hit.label.split(",")[0] ?? "").trim();
  return raw;
}

/**
 * Prefix match only when the next character is not another letter
 * ("Berlin" matches, "Berlingen" does not).
 */
export function nameMatchesQuery(name: string, query: string): boolean {
  const n = name.trim().toLowerCase();
  const q = query.trim().toLowerCase();
  if (!q || !n.startsWith(q)) return false;
  if (n.length === q.length) return true;
  const next = n[q.length];
  return next === " " || next === "-" || next === "/" || next === ",";
}

const STATION_KINDS = new Set(["station", "railway", "halt"]);

function normalizePlaceTokens(raw: string): string[] {
  return raw
    .toLowerCase()
    .replace(/hauptbahnhof/g, "bahnhof")
    .replace(/\bhbf\b/g, "bahnhof")
    .replace(/\bstation\b/g, "bahnhof")
    .replace(/\bgare\b/g, "bahnhof")
    .replace(/\bstazione\b/g, "bahnhof")
    .split(/[^a-z0-9äöüß]+/i)
    .filter((t) => t.length >= 2);
}

/** „Hauptbahnhof Frankfurt“ / Hbf / Station — nicht nur die Stadt. */
export function queryLooksLikeStation(query: string): boolean {
  return normalizePlaceTokens(query).includes("bahnhof");
}

/** Query-Wörter unabhängig von der Reihenfolge im Treffer. */
export function geocodeTokensCovered(query: string, hay: string): boolean {
  const tokens = normalizePlaceTokens(query);
  if (!tokens.length) return false;
  const have = new Set(normalizePlaceTokens(hay));
  return tokens.every((t) => have.has(t));
}

export function geocodeHitScore(query: string, hit: RankableGeocodeHit): number {
  const q = query.trim().toLowerCase();
  const name = hitName(hit).toLowerCase();
  const hay = `${name} ${hit.label}`;
  let s = 0;
  if (name === q) s += 100;
  else if (nameMatchesQuery(name, q)) s += 45;
  if (geocodeTokensCovered(query, hay)) s += 80;
  const kind = hit.kind ?? "";
  const stationQ = queryLooksLikeStation(query);
  if (kind === "city" || kind === "locality") s += stationQ ? 10 : 25;
  if (STATION_KINDS.has(kind)) s += stationQ ? 40 : 5;
  if (kind === "street" || kind === "house") s -= 15;
  return s;
}

export function rankGeocodeHits<T extends RankableGeocodeHit>(
  query: string,
  hits: T[]
): T[] {
  return [...hits].sort(
    (a, b) => geocodeHitScore(query, b) - geocodeHitScore(query, a)
  );
}

export function dedupeGeocodeHits<T extends RankableGeocodeHit>(hits: T[]): T[] {
  const seen = new Set<string>();
  const out: T[] = [];
  for (const h of hits) {
    const key = `${h.lat.toFixed(4)},${h.lng.toFixed(4)}`;
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(h);
  }
  return out;
}
