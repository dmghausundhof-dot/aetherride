/**
 * Browse-Suche: Tour-Namen filtern beim Tippen, Ort anfliegen beim Absenden.
 * Parität zu Flutter `BrowsePlaceSearch`.
 */

export type CoordHit = {
  label: string;
  lat: number;
  lng: number;
  kind: "coords";
};

/** `49.398, 8.715` (lat,lng) oder `8.715, 49.398` (lng,lat). */
export function geocodeHitFromCoordinates(query: string): CoordHit | null {
  const m = query
    .trim()
    .match(/^\s*(-?\d+(?:\.\d+)?)\s*[,;]\s*(-?\d+(?:\.\d+)?)\s*$/);
  if (!m) return null;
  const a = Number(m[1]);
  const b = Number(m[2]);
  if (!Number.isFinite(a) || !Number.isFinite(b)) return null;
  let lat: number;
  let lng: number;
  if (Math.abs(a) <= 90 && Math.abs(b) <= 180 && Math.abs(a) > Math.abs(b) && Math.abs(b) <= 90) {
    lat = a;
    lng = b;
  } else if (Math.abs(b) <= 90 && Math.abs(a) <= 180) {
    lng = a;
    lat = b;
  } else {
    return null;
  }
  if (Math.abs(lat) > 90 || Math.abs(lng) > 180) return null;
  return {
    label: `${lat.toFixed(5)}, ${lng.toFixed(5)}`,
    lat,
    lng,
    kind: "coords",
  };
}

/** Submit fliegt zum Ort, außer die Query ist bereits ein Tour-Prefix. */
export function shouldFlyToPlace(opts: {
  query: string;
  visibleTourNames: Iterable<string>;
}): boolean {
  const q = opts.query.trim();
  if (q.length < 2) return false;
  if (geocodeHitFromCoordinates(q) != null) return true;
  const lower = q.toLowerCase();
  let strong = 0;
  for (const name of opts.visibleTourNames) {
    const n = name.toLowerCase();
    if (n === lower || n.startsWith(lower)) strong += 1;
  }
  return strong === 0;
}

/** Ab 3 Zeichen Orts-Chips neben der Tour-Filterung. */
export function shouldOfferPlaceHits(query: string): boolean {
  const q = query.trim();
  if (q.length < 3) return false;
  return geocodeHitFromCoordinates(q) == null;
}
