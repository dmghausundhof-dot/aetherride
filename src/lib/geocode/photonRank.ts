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

export function isCinemaQuery(query: string): boolean {
  return /\b(kino|cinema|kinopolis|cineplex|filmpalast|kinotreff)\b/i.test(
    query.trim()
  );
}

/** Place tokens without the cinema keyword, or "" when the query is only "Kino". */
export function cinemaPlaceQuery(query: string): string | null {
  if (!isCinemaQuery(query)) return null;
  return query
    .replace(/\b(kino|cinema|kinopolis|cineplex|filmpalast|kinotreff)\b/gi, " ")
    .replace(/\s+/g, " ")
    .trim();
}

export function haversineKm(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number
): number {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * 6371 * Math.asin(Math.min(1, Math.sqrt(a)));
}

export type GeocodeRankBias = { lat: number; lng: number };

export function geocodeHitScore(
  query: string,
  hit: RankableGeocodeHit,
  bias?: GeocodeRankBias
): number {
  const q = query.trim().toLowerCase();
  const name = hitName(hit).toLowerCase();
  let s = 0;
  if (name === q) s += 100;
  else if (nameMatchesQuery(name, q)) s += 45;
  const kind = hit.kind ?? "";
  if (kind === "city" || kind === "locality") s += 25;
  if (kind === "street" || kind === "house") s -= 15;
  const hay = `${name} ${hit.label}`.toLowerCase();
  for (const token of q.split(/\s+/).filter((t) => t.length >= 3)) {
    if (hay.includes(token)) s += 12;
  }
  if (
    isCinemaQuery(query) &&
    /\b(kino|cinema|filmpalast|kinopolis|cineplex|kinotreff)\b/i.test(hay)
  ) {
    s += 20;
  }
  if (
    bias &&
    Number.isFinite(bias.lat) &&
    Number.isFinite(bias.lng) &&
    Number.isFinite(hit.lat) &&
    Number.isFinite(hit.lng)
  ) {
    const km = haversineKm(bias.lat, bias.lng, hit.lat, hit.lng);
    if (km <= 8) s += 55;
    else if (km <= 25) s += 28;
    else if (km <= 60) s += 8;
    else s -= Math.min(50, (km - 60) / 4);
  }
  return s;
}

export function rankGeocodeHits<T extends RankableGeocodeHit>(
  query: string,
  hits: T[],
  bias?: GeocodeRankBias
): T[] {
  return [...hits].sort(
    (a, b) => geocodeHitScore(query, b, bias) - geocodeHitScore(query, a, bias)
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
